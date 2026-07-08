from __future__ import annotations

import xml.etree.ElementTree as ET

import aiohttp

from baha_rag.acquisition.models import ResourceCandidate


class PubMedClient:
    base_url = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils"

    async def search(self, query: str, *, limit: int = 50) -> list[ResourceCandidate]:
        timeout = aiohttp.ClientTimeout(total=30.0)
        async with aiohttp.ClientSession(timeout=timeout) as session:
            async with session.get(
                f"{self.base_url}/esearch.fcgi",
                params={"db": "pubmed", "term": query, "retmode": "json", "retmax": limit},
            ) as search_response:
                search_response.raise_for_status()
                search_json = await search_response.json()
            ids = search_json.get("esearchresult", {}).get("idlist", [])
            if not ids:
                return []
            async with session.get(
                f"{self.base_url}/esummary.fcgi",
                params={"db": "pubmed", "id": ",".join(ids), "retmode": "json"},
            ) as summary_response:
                summary_response.raise_for_status()
                summary_json = await summary_response.json()
            async with session.get(
                f"{self.base_url}/efetch.fcgi",
                params={"db": "pubmed", "id": ",".join(ids), "retmode": "xml"},
            ) as fetch_response:
                fetch_response.raise_for_status()
                details_xml = await fetch_response.text()
        result = summary_json.get("result", {})
        details = self._article_details(details_xml)
        candidates: list[ResourceCandidate] = []
        for pubmed_id in ids:
            item = result.get(pubmed_id, {})
            detail = details.get(pubmed_id, {})
            candidates.append(
                ResourceCandidate(
                    url=f"https://pubmed.ncbi.nlm.nih.gov/{pubmed_id}/",
                    organization="PubMed",
                    source="pubmed.ncbi.nlm.nih.gov",
                    title=item.get("title"),
                    author=self._first_author(item),
                    publication_date=item.get("pubdate"),
                    resource_type="research_paper",
                    discovered_via="pubmed_api",
                    metadata={
                        "pubmed_id": pubmed_id,
                        "query": query,
                        "abstract": detail.get("abstract"),
                        "publication_year": detail.get("publication_year"),
                        "journal": detail.get("journal") or item.get("fulljournalname"),
                        "doi": detail.get("doi"),
                        "keywords": detail.get("keywords", []),
                        "publication_types": detail.get("publication_types", []),
                    },
                )
            )
        return candidates

    def _first_author(self, item: dict) -> str | None:
        authors = item.get("authors") or []
        if not authors:
            return None
        return authors[0].get("name")

    def _article_details(self, xml_text: str) -> dict[str, dict]:
        root = ET.fromstring(xml_text)
        details: dict[str, dict] = {}
        for article in root.findall(".//PubmedArticle"):
            pmid = article.findtext(".//PMID")
            if not pmid:
                continue
            abstract_parts = [
                "".join(node.itertext()).strip()
                for node in article.findall(".//Abstract/AbstractText")
            ]
            doi = None
            for article_id in article.findall(".//ArticleId"):
                if article_id.attrib.get("IdType") == "doi":
                    doi = article_id.text
                    break
            details[pmid] = {
                "abstract": " ".join(part for part in abstract_parts if part),
                "publication_year": (
                    article.findtext(".//PubDate/Year")
                    or article.findtext(".//ArticleDate/Year")
                ),
                "journal": article.findtext(".//Journal/Title"),
                "doi": doi,
                "keywords": [
                    "".join(node.itertext()).strip()
                    for node in article.findall(".//Keyword")
                ],
                "publication_types": [
                    "".join(node.itertext()).strip()
                    for node in article.findall(".//PublicationType")
                ],
            }
        return details


def pubmed_xml_text(root: ET.Element, path: str) -> str | None:
    node = root.find(path)
    return node.text if node is not None else None
