from __future__ import annotations

import aiohttp

from baha_rag.acquisition.models import ResourceCandidate


class SemanticScholarClient:
    async def search(self, query: str, *, limit: int = 50) -> list[ResourceCandidate]:
        timeout = aiohttp.ClientTimeout(total=30.0)
        async with aiohttp.ClientSession(timeout=timeout) as session:
            async with session.get(
                "https://api.semanticscholar.org/graph/v1/paper/search",
                params={
                    "query": query,
                    "limit": limit,
                    "fields": (
                        "title,authors,year,url,openAccessPdf,publicationDate,venue,"
                        "abstract,externalIds,fieldsOfStudy,isOpenAccess,citationCount"
                    ),
                },
            ) as response:
                response.raise_for_status()
                payload = await response.json()
        candidates: list[ResourceCandidate] = []
        for item in payload.get("data", []):
            pdf = item.get("openAccessPdf") or {}
            url = pdf.get("url") or item.get("url")
            if not url:
                continue
            candidates.append(
                ResourceCandidate(
                    url=url,
                    organization="Semantic Scholar",
                    source="semanticscholar.org",
                    title=item.get("title"),
                    author=", ".join(author.get("name", "") for author in item.get("authors", [])[:5]),
                    publication_date=item.get("publicationDate") or str(item.get("year") or ""),
                    resource_type="research_paper",
                    discovered_via="semantic_scholar_api",
                    metadata={
                        "paper_id": item.get("paperId"),
                        "query": query,
                        "abstract": item.get("abstract"),
                        "publication_year": item.get("year"),
                        "journal": item.get("venue"),
                        "doi": (item.get("externalIds") or {}).get("DOI"),
                        "keywords": item.get("fieldsOfStudy") or [],
                        "is_open_access": item.get("isOpenAccess"),
                        "citation_count": item.get("citationCount"),
                        "license": pdf.get("license"),
                    },
                )
            )
        return candidates
