from __future__ import annotations

from typing import Generic, TypeVar

from pydantic import BaseModel, ConfigDict, Field

T = TypeVar("T")


class APIModel(BaseModel):
    model_config = ConfigDict(from_attributes=True, populate_by_name=True)


class ErrorDetail(APIModel):
    code: str
    message: str
    details: dict | list | None = None


class ErrorResponse(APIModel):
    error: ErrorDetail
    request_id: str | None = None
    timestamp: str


class PaginationMeta(APIModel):
    page: int = Field(ge=1)
    page_size: int = Field(ge=1)
    total_items: int = Field(ge=0)
    total_pages: int = Field(ge=0)
    has_next_page: bool
    has_previous_page: bool


class PaginatedResponse(APIModel, Generic[T]):
    items: list[T]
    meta: PaginationMeta
