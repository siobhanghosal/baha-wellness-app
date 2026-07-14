from __future__ import annotations

import os

BOT_NAME = "baha_acquisition"
SPIDER_MODULES = ["baha_rag.acquisition.spiders"]
NEWSPIDER_MODULE = "baha_rag.acquisition.spiders"

ROBOTSTXT_OBEY = True
CONCURRENT_REQUESTS = int(os.getenv("CRAWL_CONCURRENT_REQUESTS", "8"))
DOWNLOAD_DELAY = float(os.getenv("CRAWL_DOWNLOAD_DELAY_SECONDS", "1.0"))
DEPTH_LIMIT = int(os.getenv("CRAWL_DEPTH_LIMIT", "3"))

AUTOTHROTTLE_ENABLED = True
AUTOTHROTTLE_START_DELAY = 1.0
AUTOTHROTTLE_MAX_DELAY = 15.0
AUTOTHROTTLE_TARGET_CONCURRENCY = 2.0

RETRY_ENABLED = True
RETRY_TIMES = 3
RETRY_HTTP_CODES = [408, 429, 500, 502, 503, 504, 522, 524]

DOWNLOAD_TIMEOUT = 45
REDIRECT_ENABLED = True
COOKIES_ENABLED = False
USER_AGENT = "BAHA-Wellness-Acquisition/0.1 (+approved-source research crawler)"

ITEM_PIPELINES = {
    "baha_rag.acquisition.pipelines.PostgresCandidatePipeline": 300,
}

LOG_LEVEL = os.getenv("SCRAPY_LOG_LEVEL", "INFO")
