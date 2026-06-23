from __future__ import annotations

import aiohttp

from baha_rag.acquisition.models import ResourceCandidate


class EuropePMCClient:
    async def search(self, query: str, *, limit: int = 50) -> list[ResourceCandidate]:
        timeout = aiohttp.ClientTimeout(total=30.0)
        async with aiohttp.ClientSession(timeout=timeout) as session:
            async with session.get(
                "https://www.ebi.ac.uk/europepmc/webservices/rest/search",
                params={
                    "query": query,
                    "format": "json",
                    "pageSize": limit,
                    "resultType": "core",
                },
            ) as response:
                response.raise_for_status()
                payload = await response.json()
        results = payload.get("resultList", {}).get("result", [])
        candidates: list[ResourceCandidate] = []
        for item in results:
            source_id = item.get("id")
            candidates.append(
                ResourceCandidate(
                    url=item.get("fullTextUrlList", {}).get("fullTextUrl", [{}])[0].get("url")
                    or f"https://europepmc.org/article/{item.get('source', 'MED')}/{source_id}",
                    organization="Europe PMC",
                    source="europepmc.org",
                    title=item.get("title"),
                    author=item.get("authorString"),
                    publication_date=item.get("firstPublicationDate") or item.get("pubYear"),
                    resource_type="research_paper",
                    discovered_via="europe_pmc_api",
                    metadata={
                        "source_id": source_id,
                        "query": query,
                        "abstract": item.get("abstractText"),
                        "publication_year": item.get("pubYear"),
                        "journal": item.get("journalTitle"),
                        "doi": item.get("doi"),
                        "keywords": item.get("keywordList", {}).get("keyword", []),
                        "is_open_access": item.get("isOpenAccess") == "Y",
                        "is_retracted": item.get("isRetracted") == "Y",
                        "license": item.get("license"),
                    },
                )
            )
        return candidates
