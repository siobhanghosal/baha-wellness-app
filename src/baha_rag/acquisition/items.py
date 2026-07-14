from __future__ import annotations

import scrapy


class ResourceCandidateItem(scrapy.Item):
    url = scrapy.Field()
    organization = scrapy.Field()
    source = scrapy.Field()
    title = scrapy.Field()
    author = scrapy.Field()
    publication_date = scrapy.Field()
    country = scrapy.Field()
    language = scrapy.Field()
    topic = scrapy.Field()
    subtopic = scrapy.Field()
    resource_type = scrapy.Field()
    content_type = scrapy.Field()
    discovered_via = scrapy.Field()
    metadata = scrapy.Field()
