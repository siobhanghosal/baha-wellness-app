from __future__ import annotations

import html
import re
from pathlib import Path
from urllib.parse import urljoin, urlparse

import scrapy
from bs4 import BeautifulSoup

from baha_rag.acquisition.campaign import (
    classify_resource,
    is_campaign_relevant,
    is_restricted_url,
    source_weight,
)
from baha_rag.acquisition.items import ResourceCandidateItem
from baha_rag.acquisition.life_skills_campaign import is_life_skills_relevant
from baha_rag.acquisition.source_registry import SourceRegistryService
from baha_rag.acquisition.topics import classify_topic


DOCUMENT_EXTENSIONS = (
    ".pdf",
    ".doc",
    ".docx",
    ".ppt",
    ".pptx",
    ".xls",
    ".xlsx",
    ".csv",
    ".zip",
)

UNSUPPORTED_MEDIA_EXTENSIONS = {
    ".avi",
    ".gif",
    ".jpeg",
    ".jpg",
    ".m4a",
    ".mov",
    ".mp3",
    ".mp4",
    ".png",
    ".svg",
    ".webm",
    ".webp",
}


class ApprovedSourceSpider(scrapy.Spider):
    name = "approved_sources"

    def __init__(
        self,
        organization: str | None = None,
        campaign: str | bool | None = None,
        *args,
        **kwargs,
    ) -> None:
        super().__init__(*args, **kwargs)
        self.registry = SourceRegistryService()
        self.campaign_name = str(campaign or "").lower()
        self.campaign = self.campaign_name in {
            "1", "true", "yes", "aha-nimhans", "life-skills"
        }
        self.sources = (
            [self.registry.by_organization(organization)] if organization else self.registry.all_sources()
        )
        self.allowed_domains = sorted({domain for source in self.sources for domain in source.base_domains})
        self.start_urls = [url for source in self.sources for url in source.seed_urls]

    def parse(self, response: scrapy.http.Response):
        source = self.registry.organization_for_domain(urlparse(response.url).netloc)
        if source is None or is_restricted_url(response.url):
            return

        content_type = response.headers.get("content-type", b"").decode("latin-1")
        if not self._is_html(content_type):
            if not self._is_supported_binary(response.url, content_type):
                return
            topic, subtopic = classify_topic(response.url)
            topic = topic or response.meta.get("inherited_topic")
            subtopic = subtopic or response.meta.get("inherited_subtopic")
            context = f"{response.url} {response.meta.get('link_label', '')}"
            audience, resource_class = classify_resource(context)
            if audience == "general" and response.meta.get("inherited_audience"):
                audience = response.meta["inherited_audience"]
                resource_class = response.meta.get("inherited_resource_class") or resource_class
            campaign_relevant = bool(response.meta.get("campaign_relevant"))
            if topic or campaign_relevant or (not self.campaign and self._looks_like_document(response.url)):
                yield ResourceCandidateItem(
                    url=response.url,
                    organization=source.organization,
                    source=urlparse(response.url).netloc.removeprefix("www."),
                    title=response.url.rsplit("/", 1)[-1],
                    author=None,
                    publication_date=None,
                    country=source.country,
                    language="en",
                    topic=topic,
                    subtopic=subtopic,
                    resource_type=self._resource_type(response.url, content_type),
                    content_type=content_type,
                    discovered_via="scrapy",
                    metadata={
                        "depth": response.meta.get("depth", 0),
                        "binary": True,
                        "audience": audience,
                        "resource_class": resource_class,
                        "source_weight": source_weight(source.organization),
                        "campaign": self._campaign_label(),
                    },
                )
            return

        title = self._title(response)
        page_context = f"{title} {response.url} {response.text[:12000]}"
        topic, subtopic = classify_topic(page_context)
        topic = topic or response.meta.get("inherited_topic")
        subtopic = subtopic or response.meta.get("inherited_subtopic")
        campaign_navigation_context = (
            f"{title} {response.url} {response.meta.get('link_label', '')}"
        )
        audience, resource_class = classify_resource(campaign_navigation_context)
        if audience == "general" and response.meta.get("inherited_audience"):
            audience = response.meta["inherited_audience"]
            resource_class = response.meta.get("inherited_resource_class") or resource_class
        campaign_relevant = bool(response.meta.get("campaign_relevant")) or self._campaign_relevant(
            campaign_navigation_context,
            source.organization,
        )
        if topic or campaign_relevant or (not self.campaign and self._looks_like_document(response.url)):
            yield ResourceCandidateItem(
                url=response.url,
                organization=source.organization,
                source=urlparse(response.url).netloc.removeprefix("www."),
                title=title,
                author=None,
                publication_date=None,
                country=source.country,
                language=self._language(response),
                topic=topic,
                subtopic=subtopic,
                resource_type=self._resource_type(response.url, content_type),
                content_type=content_type,
                discovered_via="scrapy",
                metadata={
                    "depth": response.meta.get("depth", 0),
                    "audience": audience,
                    "resource_class": resource_class,
                    "source_weight": source_weight(source.organization),
                    "campaign": self._campaign_label(),
                },
            )

        for href, label in self._links(response):
            absolute = urljoin(response.url, href)
            if not self._approved_url(absolute) or is_restricted_url(absolute):
                continue
            link_topic, link_subtopic = classify_topic(f"{label} {absolute}")
            is_document = self._looks_like_document(absolute)
            direct_campaign_relevant = self._campaign_relevant(
                f"{label} {absolute}",
                source.organization,
            )
            document_campaign_relevant = campaign_relevant or direct_campaign_relevant
            should_follow = (
                link_topic
                or (is_document and (topic or document_campaign_relevant))
                or (self.campaign and direct_campaign_relevant)
            )
            if should_follow:
                yield scrapy.Request(
                    absolute,
                    callback=self.parse,
                    meta={
                        "inherited_topic": link_topic or topic,
                        "inherited_subtopic": link_subtopic or subtopic,
                        "campaign_relevant": (
                            document_campaign_relevant
                            if is_document
                            else direct_campaign_relevant
                        ),
                        "link_label": label,
                        "inherited_audience": audience,
                        "inherited_resource_class": resource_class,
                    },
                )

    def _links(self, response: scrapy.http.Response) -> list[tuple[str, str]]:
        soup = BeautifulSoup(response.text, "html.parser")
        links: list[tuple[str, str]] = []
        for anchor in soup.find_all("a", href=True):
            links.append((str(anchor["href"]), anchor.get_text(" ", strip=True)))
        for match in re.finditer(
            r'\\"href\\":\\"(?P<url>https?[^"\\]+?\.(?:pdf|pptx?|docx?|xlsx?|zip))\\"'
            r'.{0,800}?\\"children\\":\\"(?P<label>[^"\\]+)',
            response.text,
            flags=re.IGNORECASE | re.DOTALL,
        ):
            links.append(
                (
                    html.unescape(match.group("url").replace("\\/", "/")),
                    html.unescape(match.group("label")),
                )
            )
        return links

    def _approved_url(self, url: str) -> bool:
        host = urlparse(url).netloc.removeprefix("www.").lower()
        return any(host == domain or host.endswith(f".{domain}") for domain in self.allowed_domains)

    def _is_supported_binary(self, url: str, content_type: str) -> bool:
        suffix = Path(urlparse(url).path).suffix.lower()
        lowered_type = content_type.lower()
        if suffix in UNSUPPORTED_MEDIA_EXTENSIONS:
            return False
        if lowered_type.startswith(("image/", "audio/", "video/")):
            return False
        return suffix in DOCUMENT_EXTENSIONS or any(
            marker in lowered_type
            for marker in (
                "pdf",
                "word",
                "officedocument",
                "powerpoint",
                "spreadsheet",
                "csv",
                "zip",
                "json",
            )
        )

    def _looks_like_document(self, url: str) -> bool:
        lowered = url.lower().split("?", 1)[0]
        return lowered.endswith(DOCUMENT_EXTENSIONS)

    def _resource_type(self, url: str, content_type: str) -> str:
        path = urlparse(url).path.lower()
        suffix = Path(path).suffix
        if suffix in {".ppt", ".pptx"}:
            return "powerpoint"
        if suffix in {".doc", ".docx"}:
            return "document"
        if suffix in {".csv", ".xls", ".xlsx"}:
            return "dataset"
        if suffix == ".zip":
            return "zip_archive"
        if suffix == ".pdf" or "pdf" in content_type.lower():
            return "pdf"
        return "html"

    def _title(self, response: scrapy.http.Response) -> str:
        title = response.css("title::text").get()
        if title:
            return title.strip()
        heading = response.css("h1::text").get()
        return heading.strip() if heading else response.url

    def _language(self, response: scrapy.http.Response) -> str:
        lang = response.css("html::attr(lang)").get()
        return lang.strip() if lang else "en"

    def _is_html(self, content_type: str) -> bool:
        return "html" in content_type.lower() or "text" in content_type.lower()

    def _campaign_relevant(self, text_value: str, organization: str) -> bool:
        if self.campaign_name == "life-skills":
            return is_life_skills_relevant(text_value, organization)
        return is_campaign_relevant(text_value, organization)

    def _campaign_label(self) -> str | None:
        if self.campaign_name == "life-skills":
            return "life_skills_digital_wellbeing"
        if self.campaign:
            return "aha_nimhans_priority"
        return None
