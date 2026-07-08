from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class TextChunk:
    ordinal: int
    text: str
    token_count: int


def chunk_text(text: str, *, max_words: int = 360, overlap_words: int = 60) -> list[TextChunk]:
    words = text.split()
    if not words:
        return []
    chunks: list[TextChunk] = []
    start = 0
    ordinal = 0
    while start < len(words):
        end = min(start + max_words, len(words))
        chunk_words = words[start:end]
        chunks.append(TextChunk(ordinal=ordinal, text=" ".join(chunk_words), token_count=len(chunk_words)))
        if end == len(words):
            break
        start = max(0, end - overlap_words)
        ordinal += 1
    return chunks


def chunk_tokens(
    text: str,
    *,
    tokenizer,
    max_tokens: int = 1024,
    overlap_tokens: int = 150,
) -> list[TextChunk]:
    if overlap_tokens >= max_tokens:
        raise ValueError("Token overlap must be smaller than chunk size")
    token_ids = tokenizer.encode(text, add_special_tokens=False)
    if not token_ids:
        return []
    chunks: list[TextChunk] = []
    start = 0
    ordinal = 0
    while start < len(token_ids):
        chunk_ids = token_ids[start : start + max_tokens]
        chunks.append(
            TextChunk(
                ordinal=ordinal,
                text=tokenizer.decode(chunk_ids, skip_special_tokens=True),
                token_count=len(chunk_ids),
            )
        )
        if start + max_tokens >= len(token_ids):
            break
        start += max_tokens - overlap_tokens
        ordinal += 1
    return chunks
