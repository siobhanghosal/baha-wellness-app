from __future__ import annotations

import os
from functools import lru_cache
from typing import Annotated, Literal

from pydantic import Field, field_validator, model_validator
from pydantic_settings import BaseSettings, NoDecode, SettingsConfigDict


Environment = Literal["local", "development", "testing", "staging", "production"]


class AppSettings(BaseSettings):
    app_name: str = "BAHA Wellness Companion API"
    app_version: str = "0.1.0"
    environment: Environment = "local"
    debug: bool = False

    api_v1_prefix: str = "/api/v1"
    docs_url: str | None = "/docs"
    redoc_url: str | None = "/redoc"
    openapi_url: str | None = "/openapi.json"
    trusted_hosts: Annotated[list[str], NoDecode] = Field(
        default_factory=lambda: ["localhost", "127.0.0.1", "testserver"]
    )
    allowed_cors_origins: Annotated[list[str], NoDecode] = Field(
        default_factory=lambda: ["http://localhost:3000", "http://localhost:8080"]
    )
    log_level: str = "INFO"
    log_json: bool = True

    database_url: str = "postgresql+asyncpg://baha:baha@localhost:5432/baha_companion"
    database_echo: bool = False
    database_pool_size: int = 10
    database_max_overflow: int = 20
    database_pool_timeout_seconds: int = 30
    database_pool_recycle_seconds: int = 1800

    auth_secret_key: str = "change-me-in-production"
    auth_algorithm: str = "HS256"
    auth_issuer: str = "baha-companion"
    auth_audience: str = "baha-clients"
    access_token_ttl_minutes: int = 15
    refresh_token_ttl_days: int = 14
    refresh_token_idle_minutes: int = 1440
    password_min_length: int = 12
    password_reset_token_ttl_minutes: int = 30
    email_verification_token_ttl_hours: int = 24
    max_failed_login_attempts: int = 5
    failed_login_window_minutes: int = 15
    login_lockout_minutes: int = 15
    require_email_verification_for_login: bool = False

    refresh_cookie_name: str = "baha_refresh_token"
    csrf_cookie_name: str = "baha_csrf_token"
    cookie_domain: str | None = None
    cookie_path: str = "/"
    secure_cookies: bool = False
    cookie_samesite: Literal["lax", "strict", "none"] = "lax"
    enable_cookie_auth: bool = True

    auth_rate_limit_attempts: int = 10
    auth_rate_limit_window_seconds: int = 60
    write_rate_limit_attempts: int = 120
    write_rate_limit_window_seconds: int = 60

    expose_debug_tokens: bool = False
    csrf_header_name: str = "X-CSRF-Token"

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    @field_validator("allowed_cors_origins", mode="before")
    @classmethod
    def parse_cors_origins(cls, value: str | list[str]) -> list[str]:
        if isinstance(value, list):
            return value
        return [origin.strip() for origin in value.split(",") if origin.strip()]

    @field_validator("trusted_hosts", mode="before")
    @classmethod
    def parse_trusted_hosts(cls, value: str | list[str]) -> list[str]:
        if isinstance(value, list):
            return value
        return [host.strip() for host in value.split(",") if host.strip()]

    @property
    def sqlalchemy_sync_database_url(self) -> str:
        if "+asyncpg" in self.database_url:
            return self.database_url.replace("+asyncpg", "+psycopg")
        if "+aiosqlite" in self.database_url:
            return self.database_url.replace("+aiosqlite", "")
        return self.database_url

    @property
    def cors_origins(self) -> list[str]:
        return self.allowed_cors_origins

    @property
    def is_testing(self) -> bool:
        return self.environment == "testing"

    @property
    def is_production(self) -> bool:
        return self.environment in {"staging", "production"}

    @model_validator(mode="after")
    def validate_settings(self) -> "AppSettings":
        if self.is_production and self.auth_secret_key.startswith("change-me"):
            raise ValueError("AUTH_SECRET_KEY must be rotated outside local development.")
        if self.password_min_length < 8:
            raise ValueError("PASSWORD_MIN_LENGTH must be at least 8.")
        if self.cookie_samesite == "none" and not self.secure_cookies:
            raise ValueError("SameSite=None cookies must be secure.")
        if self.is_production and not self.secure_cookies:
            raise ValueError("Production environments must enable secure cookies.")
        return self


class DevelopmentSettings(AppSettings):
    environment: Literal["local", "development"] = "development"
    debug: bool = True
    log_level: str = "DEBUG"
    expose_debug_tokens: bool = True


class TestingSettings(AppSettings):
    environment: Literal["testing"] = "testing"
    debug: bool = True
    database_pool_size: int = 1
    database_max_overflow: int = 0
    secure_cookies: bool = False
    expose_debug_tokens: bool = True


class ProductionSettings(AppSettings):
    environment: Literal["staging", "production"] = "production"
    debug: bool = False
    docs_url: str | None = None
    redoc_url: str | None = None
    openapi_url: str | None = "/openapi.json"
    secure_cookies: bool = True
    require_email_verification_for_login: bool = True


Settings = AppSettings


@lru_cache
def get_settings() -> AppSettings:
    environment = os.getenv("ENVIRONMENT", "local").lower()
    if environment == "testing":
        return TestingSettings()
    if environment in {"staging", "production"}:
        return ProductionSettings()
    if environment in {"local", "development"}:
        return DevelopmentSettings(environment=environment)
    return AppSettings()
