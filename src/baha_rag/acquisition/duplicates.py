from __future__ import annotations

import hashlib


class DuplicateDetector:
    def content_hash(self, content: bytes) -> str:
        return hashlib.sha256(content).hexdigest()

    def normalized_url_key(self, url: str) -> str:
        cleaned = url.split("#", 1)[0].rstrip("/")
        return cleaned.lower()

    def text_fingerprint(self, text: str) -> str:
        tokens = sorted(set(token.strip(".,;:!?()[]{}\"'").lower() for token in text.split()))
        return hashlib.sha256(" ".join(tokens).encode("utf-8")).hexdigest()
