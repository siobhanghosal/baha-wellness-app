from __future__ import annotations

from baha_companion.config.settings import AppSettings


def test_settings_parse_csv_hosts_and_cors_from_env(monkeypatch):
    monkeypatch.setenv("TRUSTED_HOSTS", "localhost,127.0.0.1,testserver")
    monkeypatch.setenv("ALLOWED_CORS_ORIGINS", "http://localhost:3000,http://localhost:8080")
    monkeypatch.setenv("AUTH_SECRET_KEY", "test-secret-key-with-32-bytes-minimum")

    settings = AppSettings()

    assert settings.trusted_hosts == ["localhost", "127.0.0.1", "testserver"]
    assert settings.allowed_cors_origins == ["http://localhost:3000", "http://localhost:8080"]
