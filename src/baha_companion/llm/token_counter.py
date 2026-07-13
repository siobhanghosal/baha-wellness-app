from __future__ import annotations

import math
from collections.abc import Iterable


class TokenCounter:
    """Approximate token counting without a tokenizer dependency."""

    @staticmethod
    def count_text(text: str | None) -> int:
        if not text:
            return 0
        normalized = " ".join(text.strip().split())
        if not normalized:
            return 0
        by_chars = math.ceil(len(normalized) / 4)
        by_words = math.ceil(len(normalized.split()) * 1.3)
        return max(1, by_chars, by_words)

    def count_messages(self, messages: Iterable[dict[str, str]]) -> int:
        total = 0
        for message in messages:
            total += 4
            total += self.count_text(message.get("content"))
            total += self.count_text(message.get("role"))
        return total + 2
