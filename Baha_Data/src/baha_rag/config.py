from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "BAHA Wellness RAG"
    environment: str = "local"
    database_url: str = "postgresql+asyncpg://baha:baha@localhost:5433/baha_rag"
    auth_jwks_url: str | None = None
    auth_jwt_secret: str | None = None
    auth_issuer: str | None = None
    auth_audience: str | None = None
    allow_dev_identity_headers: bool = True
    object_storage_provider: str = "local"
    object_storage_bucket: str | None = None
    object_storage_region: str | None = None
    object_storage_endpoint: str | None = None
    object_storage_public_base_url: str | None = None
    object_storage_prefix: str = "raw"
    embedding_model: str = "BAAI/bge-large-en-v1.5"
    embedding_backend: str = Field(default="bge", pattern="^(bge|hash)$")
    embedding_dimensions: int = 1024
    embedding_chunk_tokens: int = 1024
    embedding_chunk_overlap_tokens: int = 150
    embedding_batch_size: int = 8
    embedding_auto_index: bool = False
    allowed_cors_origins: str = "http://localhost:3000,http://localhost:8080"
    retrieval_top_k: int = 8
    min_confidence: float = 0.35
    buddy_generation_backend: str = Field(
        default="ollama",
        pattern="^(composer|ollama)$",
    )
    buddy_chat_mode: str = Field(
        default="grounded",
        pattern="^(grounded|generic_demo)$",
    )
    buddy_ollama_base_url: str = "http://localhost:11434"
    buddy_ollama_model: str = "qwen3:4b"
    buddy_ollama_timeout_seconds: float = 60.0
    buddy_ollama_keep_alive: str = "10m"
    buddy_ollama_think: bool = False
    buddy_history_window: int = 6
    buddy_min_retrieval_confidence: float = 0.45
    buddy_demo_permissive_mode: bool = True
    storage_root: str = "storage/raw"
    crawl_concurrent_requests: int = 8
    crawl_download_delay_seconds: float = 1.0
    crawl_depth_limit: int = 3

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

    @property
    def cors_origins(self) -> list[str]:
        return [origin.strip() for origin in self.allowed_cors_origins.split(",") if origin.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
