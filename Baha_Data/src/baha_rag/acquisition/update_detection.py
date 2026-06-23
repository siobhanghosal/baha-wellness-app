from __future__ import annotations


class IncrementalUpdateDetector:
    def changed(
        self,
        *,
        previous_hash: str | None,
        current_hash: str,
        previous_etag: str | None = None,
        current_etag: str | None = None,
        previous_last_modified: str | None = None,
        current_last_modified: str | None = None,
    ) -> bool:
        if previous_hash and previous_hash == current_hash:
            return False
        if previous_etag and current_etag and previous_etag == current_etag:
            return False
        if previous_last_modified and current_last_modified and previous_last_modified == current_last_modified:
            return False
        return True
