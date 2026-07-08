from __future__ import annotations

from scrapy.crawler import CrawlerProcess
from scrapy.utils.project import get_project_settings

from baha_rag.acquisition.spiders.approved_sources import ApprovedSourceSpider


def run_scrapy_discovery(
    organization: str | None = None,
    *,
    campaign: bool | str = False,
) -> None:
    settings = get_project_settings()
    settings.setmodule("baha_rag.acquisition.settings")
    process = CrawlerProcess(settings)
    process.crawl(
        ApprovedSourceSpider,
        organization=organization,
        campaign=("aha-nimhans" if campaign is True else campaign or None),
    )
    process.start()
