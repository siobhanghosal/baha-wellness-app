from __future__ import annotations

from collections import Counter
from math import log

from baha_rag.schemas import SearchResult


class BM25Scorer:
    def __init__(self, *, k1: float = 1.5, b: float = 0.75) -> None:
        self.k1 = k1
        self.b = b

    def rank(self, query: str, results: list[SearchResult]) -> list[SearchResult]:
        if not results:
            return []
        tokenized_docs = [self._tokens(result.text) for result in results]
        query_terms = self._tokens(query)
        avg_doc_len = sum(len(doc) for doc in tokenized_docs) / len(tokenized_docs)
        doc_freq = Counter(term for doc in tokenized_docs for term in set(doc))

        for result, doc in zip(results, tokenized_docs, strict=True):
            frequencies = Counter(doc)
            score = 0.0
            for term in query_terms:
                if term not in frequencies:
                    continue
                idf = log(1 + (len(results) - doc_freq[term] + 0.5) / (doc_freq[term] + 0.5))
                numerator = frequencies[term] * (self.k1 + 1)
                denominator = frequencies[term] + self.k1 * (1 - self.b + self.b * len(doc) / avg_doc_len)
                score += idf * numerator / denominator
            result.lexical_score = round(score, 6)
        return sorted(results, key=lambda item: item.lexical_score, reverse=True)

    def _tokens(self, text: str) -> list[str]:
        return [token.strip(".,;:!?()[]{}\"'").lower() for token in text.split() if token.strip()]
