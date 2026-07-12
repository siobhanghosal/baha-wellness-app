from __future__ import annotations

from dataclasses import dataclass
from urllib.parse import quote_plus


BAHA = "Bangalore Adolescent Health Academy"
IAP = "Indian Academy of Pediatrics"
AHA = "IAP Adolescent Health Academy"


@dataclass(frozen=True)
class PrioritySource:
    organization: str
    priority_rank: int
    domains: tuple[str, ...]
    source_weight: float
    search_url_template: str | None = None

    @property
    def is_baha(self) -> bool:
        return self.organization == BAHA

    @property
    def is_iap(self) -> bool:
        return self.organization in {AHA, IAP}

    def search_url(self, query: str) -> str | None:
        if not self.search_url_template:
            return None
        return self.search_url_template.format(query=quote_plus(query))


PRIORITY_SOURCES: tuple[PrioritySource, ...] = (
    PrioritySource(BAHA, 1, ("baha.org.in", "bahedu.in"), 1.00),
    PrioritySource(AHA, 2, ("aha.iapindia.org",), 0.95),
    PrioritySource(IAP, 2, ("iapindia.org",), 0.95),
    PrioritySource("NIMHANS", 3, ("nimhans.ac.in",), 0.90),
    PrioritySource(
        "WHO",
        4,
        ("who.int",),
        0.85,
        "https://www.who.int/home/search?indexCatalogue=genericsearchindex1&searchQuery={query}",
    ),
    PrioritySource(
        "UNICEF",
        5,
        ("unicef.org",),
        0.80,
        "https://www.unicef.org/search?force=0&query={query}",
    ),
    PrioritySource(
        "UNESCO",
        5,
        ("unesco.org", "unesdoc.unesco.org"),
        0.80,
        "https://unesdoc.unesco.org/search?query={query}",
    ),
    PrioritySource("PubMed", 6, ("pubmed.ncbi.nlm.nih.gov",), 0.75),
    PrioritySource("Europe PMC", 6, ("europepmc.org",), 0.75),
    PrioritySource("Semantic Scholar", 6, ("semanticscholar.org",), 0.75),
)

ALIASES = {
    "baha": BAHA,
    "iap": IAP,
    "aha": AHA,
    "iap aha": AHA,
}


class PrioritySourceRegistry:
    def all(self) -> list[PrioritySource]:
        return list(PRIORITY_SOURCES)

    def resolve(
        self,
        organization: str,
        *,
        allow_custom: bool = False,
    ) -> PrioritySource:
        normalized = ALIASES.get(organization.strip().lower(), organization.strip())
        for source in PRIORITY_SOURCES:
            if source.organization.lower() == normalized.lower():
                return source
        if allow_custom:
            # Manual curation should preserve the true organization even when the
            # source is not part of the automated acquisition priority ladder.
            return PrioritySource(
                organization=normalized,
                priority_rank=99,
                domains=(),
                source_weight=0.70,
            )
        raise ValueError(
            f"{organization!r} is not a priority source. "
            f"Allowed: {', '.join(source.organization for source in PRIORITY_SOURCES)}"
        )

    def site_query(self, source: PrioritySource, query: str) -> str:
        domains = " OR ".join(f"site:{domain}" for domain in source.domains)
        return f"({domains}) {query}"
