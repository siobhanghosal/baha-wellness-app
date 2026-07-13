from __future__ import annotations

from pathlib import Path

from fastapi import UploadFile

from baha_companion.common.exceptions import ValidationError


def validate_upload(
    upload: UploadFile,
    *,
    allowed_content_types: set[str],
    allowed_extensions: set[str],
    max_size_bytes: int,
) -> None:
    suffix = Path(upload.filename or "").suffix.lower()
    if upload.content_type not in allowed_content_types:
        raise ValidationError("Unsupported upload content type.", extra={"content_type": upload.content_type})
    if suffix not in allowed_extensions:
        raise ValidationError("Unsupported upload file extension.", extra={"extension": suffix})
    size_header = upload.headers.get("content-length")
    if size_header and int(size_header) > max_size_bytes:
        raise ValidationError("Uploaded file is too large.", extra={"max_size_bytes": max_size_bytes})
