from __future__ import annotations

from collections import Counter
from dataclasses import dataclass
from math import log
from uuid import UUID

from baha_companion.retrieval.utils import tokenize


@dataclass(slots=True)
class BM25Document:
    knowledge_object_id: UUID
    title: str
    topic: str | None
    keywords: list[str]
    retrieval_summary: str
    body: str


class BM25Scorer:
    def __init__(self, *, k1: float = 1.5, b: float = 0.75) -> None:
        self.k1 = k1
        self.b = b

    def score_documents(self, query: str, documents: list[BM25Document]) -> dict[str, float]:
        query_tokens = tokenize(query)
        if not query_tokens or not documents:
            return {}

        weighted_documents = {str(doc.knowledge_object_id): self._weighted_tokens(doc) for doc in documents}
        document_lengths = {key: len(tokens) for key, tokens in weighted_documents.items()}
        average_length = sum(document_lengths.values()) / len(document_lengths)
        document_frequency = Counter()
        for tokens in weighted_documents.values():
            document_frequency.update(set(tokens))

        scores: dict[str, float] = {}
        corpus_size = len(weighted_documents)
        for document_id, tokens in weighted_documents.items():
            token_counts = Counter(tokens)
            score = 0.0
            for term in query_tokens:
                if term not in token_counts:
                    continue
                idf = log(1 + (corpus_size - document_frequency[term] + 0.5) / (document_frequency[term] + 0.5))
                tf = token_counts[term]
                denominator = tf + self.k1 * (1 - self.b + self.b * (document_lengths[document_id] / average_length))
                score += idf * ((tf * (self.k1 + 1)) / denominator)
            if score > 0:
                scores[document_id] = round(score, 6)
        return scores

    def _weighted_tokens(self, document: BM25Document) -> list[str]:
        tokens: list[str] = []
        tokens.extend(tokenize(document.title) * 3)
        if document.topic:
            tokens.extend(tokenize(document.topic) * 2)
        for keyword in document.keywords:
            tokens.extend(tokenize(keyword) * 3)
        tokens.extend(tokenize(document.retrieval_summary) * 2)
        tokens.extend(tokenize(document.body))
        return tokens
