from __future__ import annotations

from baha_rag.acquisition.models import ResourceCandidate
from baha_rag.acquisition.research.europe_pmc import EuropePMCClient
from baha_rag.acquisition.research.pubmed import PubMedClient
from baha_rag.acquisition.research.semantic_scholar import SemanticScholarClient
from baha_rag.acquisition.topics import RESEARCH_QUERIES, classify_topic


class ResearchDiscoveryService:
    def __init__(self) -> None:
        self.clients = (PubMedClient(), EuropePMCClient(), SemanticScholarClient())
        self.errors: list[dict[str, str]] = []

    async def discover(
        self,
        *,
        limit_per_topic: int = 25,
        queries: tuple[str, ...] | list[str] | None = None,
    ) -> list[ResourceCandidate]:
        candidates: list[ResourceCandidate] = []
        for query in queries or RESEARCH_QUERIES:
            for client in self.clients:
                try:
                    results = await client.search(query, limit=limit_per_topic)
                except Exception as exc:
                    self.errors.append(
                        {
                            "client": client.__class__.__name__,
                            "query": query,
                            "error": str(exc),
                        }
                    )
                    continue
                for candidate in results:
                    classified_topic, subtopic = classify_topic(f"{candidate.title or ''} {query}")
                    candidates.append(
                        ResourceCandidate(
                            **{
                                **candidate.__dict__,
                                "topic": candidate.topic or classified_topic,
                                "subtopic": candidate.subtopic or subtopic,
                            }
                        )
                    )
        return candidates
