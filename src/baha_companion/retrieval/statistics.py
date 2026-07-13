from __future__ import annotations

from math import log2


def precision_at_k(relevant: list[bool], *, k: int) -> float:
    if k <= 0:
        return 0.0
    slice_values = relevant[:k]
    return round(sum(slice_values) / k, 4)


def recall_at_k(relevant: list[bool], *, k: int, total_relevant: int) -> float:
    if total_relevant <= 0:
        return 0.0
    return round(sum(relevant[:k]) / total_relevant, 4)


def reciprocal_rank(relevant: list[bool]) -> float:
    for index, is_relevant in enumerate(relevant, start=1):
        if is_relevant:
            return round(1 / index, 4)
    return 0.0


def ndcg_at_k(relevant: list[bool], *, k: int) -> float:
    gains = [1.0 if item else 0.0 for item in relevant[:k]]
    dcg = sum(gain / log2(index + 2) for index, gain in enumerate(gains))
    ideal_gains = sorted(gains, reverse=True)
    idcg = sum(gain / log2(index + 2) for index, gain in enumerate(ideal_gains))
    if idcg == 0:
        return 0.0
    return round(dcg / idcg, 4)
