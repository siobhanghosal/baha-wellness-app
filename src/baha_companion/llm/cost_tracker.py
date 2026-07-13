from __future__ import annotations

from dataclasses import dataclass

from baha_companion.llm.config import LLMModelSpec


@dataclass(slots=True)
class UsageSnapshot:
    prompt_tokens: int
    completion_tokens: int
    total_tokens: int


@dataclass(slots=True)
class CostSnapshot:
    prompt_cost: float
    completion_cost: float
    total_cost: float
    currency: str = "USD"


class CostTracker:
    def estimate(self, *, usage: UsageSnapshot, model: LLMModelSpec) -> CostSnapshot:
        prompt_cost = round((usage.prompt_tokens / 1_000_000) * model.input_token_price_per_million, 8)
        completion_cost = round(
            (usage.completion_tokens / 1_000_000) * model.output_token_price_per_million,
            8,
        )
        return CostSnapshot(
            prompt_cost=prompt_cost,
            completion_cost=completion_cost,
            total_cost=round(prompt_cost + completion_cost, 8),
        )
