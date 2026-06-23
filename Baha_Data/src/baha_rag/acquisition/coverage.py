from __future__ import annotations

from dataclasses import dataclass

from baha_rag.acquisition.topics import TOPIC_ALIASES


TOPIC_TARGETS: dict[str, int] = {
    "depression": 200,
    "anxiety": 200,
    "stress": 200,
    "bullying": 200,
    "cyberbullying": 150,
    "sleep": 200,
    "digital wellness": 200,
    "nutrition": 150,
    "physical activity": 150,
    "adhd": 100,
    "autism": 100,
    "self harm": 100,
    "suicide prevention": 100,
}


@dataclass(frozen=True)
class TopicGap:
    topic: str
    current_count: int
    target_count: int
    gap_count: int
    generated_queries: tuple[str, ...]


class GapQueryGenerator:
    def generate(self, topic: str) -> tuple[str, ...]:
        aliases = TOPIC_ALIASES.get(topic, (topic,))
        primary = aliases[0]
        prevention_query = (
            f"youth {primary} resources"
            if primary.endswith("prevention")
            else f"youth {primary} prevention"
        )
        return (
            f"adolescent {primary} guideline",
            f"teen {primary} parent guide",
            f"school {primary} teacher toolkit",
            f"adolescent {primary} intervention",
            prevention_query,
        )
