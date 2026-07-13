from __future__ import annotations

from math import ceil

from fastapi import Query
from pydantic import BaseModel, ConfigDict, Field

from baha_companion.common.schemas import PaginationMeta


class PaginationParams(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    page: int = Field(default=1, ge=1)
    page_size: int = Field(default=20, ge=1, le=100)

    @property
    def offset(self) -> int:
        return (self.page - 1) * self.page_size


def pagination_params(
    page: int = Query(default=1, ge=1, description="1-based page number"),
    page_size: int = Query(default=20, ge=1, le=100, description="Page size"),
) -> PaginationParams:
    return PaginationParams(page=page, page_size=page_size)


def build_pagination_meta(*, total_items: int, page: int, page_size: int) -> PaginationMeta:
    total_pages = ceil(total_items / page_size) if total_items else 0
    return PaginationMeta(
        page=page,
        page_size=page_size,
        total_items=total_items,
        total_pages=total_pages,
        has_next_page=page < total_pages,
        has_previous_page=page > 1,
    )
