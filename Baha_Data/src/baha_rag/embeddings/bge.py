from __future__ import annotations

import hashlib
from typing import Iterable

import numpy as np

from baha_rag.config import Settings


class EmbeddingService:
    def __init__(self, settings: Settings) -> None:
        self.settings = settings
        self._model = None
        self._model_max_tokens = 510

    @property
    def model_name(self) -> str:
        return self.settings.embedding_model

    def _load_model(self):
        if self._model is None:
            try:
                from sentence_transformers import SentenceTransformer
                import torch
            except ModuleNotFoundError as exc:
                raise RuntimeError(
                    "The BGE embedding backend requires the retrieval runtime dependencies. "
                    "Install the retrieval extra or set EMBEDDING_BACKEND=hash."
                ) from exc

            device = "mps" if torch.backends.mps.is_available() else "cpu"
            self._model = SentenceTransformer(self.settings.embedding_model, device=device)
            self._model_max_tokens = max(32, min(int(self._model.max_seq_length) - 2, 510))
            # Stored chunks are 1,024 tokens; encoding is windowed below.
            self._model.tokenizer.model_max_length = 10_000_000
        return self._model

    @property
    def tokenizer(self):
        return self._load_model().tokenizer

    def embed_texts(self, texts: Iterable[str]) -> list[list[float]]:
        items = list(texts)
        if not items:
            return []
        if self.settings.embedding_backend == "hash":
            return [self._hash_embedding(text) for text in items]
        model = self._load_model()
        vectors = model.encode(
            items,
            normalize_embeddings=True,
            batch_size=self.settings.embedding_batch_size,
            show_progress_bar=False,
        )
        return [vector.astype(float).tolist() for vector in vectors]

    def embed_long_texts(self, texts: Iterable[str]) -> list[list[float]]:
        items = list(texts)
        if self.settings.embedding_backend == "hash":
            return self.embed_texts(items)
        model = self._load_model()
        tokenizer = model.tokenizer
        max_tokens = self._model_max_tokens
        window_texts: list[str] = []
        owners: list[int] = []
        for owner, text in enumerate(items):
            token_ids = tokenizer.encode(text, add_special_tokens=False)
            if not token_ids:
                token_ids = tokenizer.encode("empty", add_special_tokens=False)
            start = 0
            while start < len(token_ids):
                window = token_ids[start : start + max_tokens]
                window_texts.append(
                    tokenizer.decode(window, skip_special_tokens=True)
                )
                owners.append(owner)
                if start + max_tokens >= len(token_ids):
                    break
                start += max_tokens
        window_vectors = np.asarray(
            model.encode(
                window_texts,
                normalize_embeddings=True,
                batch_size=self.settings.embedding_batch_size,
                show_progress_bar=False,
            ),
            dtype=np.float32,
        )
        pooled: list[list[float]] = []
        for owner in range(len(items)):
            owner_vectors = window_vectors[
                [index for index, value in enumerate(owners) if value == owner]
            ]
            vector = owner_vectors.mean(axis=0)
            norm = np.linalg.norm(vector)
            if norm:
                vector /= norm
            pooled.append(vector.astype(float).tolist())
        return pooled

    def embed_query(self, query: str) -> list[float]:
        return self.embed_texts([query])[0]

    def _hash_embedding(self, text: str) -> list[float]:
        dims = self.settings.embedding_dimensions
        vector = np.zeros(dims, dtype=np.float32)
        for token in text.lower().split():
            digest = hashlib.sha256(token.encode("utf-8")).digest()
            index = int.from_bytes(digest[:4], "big") % dims
            sign = 1.0 if digest[4] % 2 == 0 else -1.0
            vector[index] += sign
        norm = np.linalg.norm(vector)
        if norm:
            vector = vector / norm
        return vector.astype(float).tolist()
