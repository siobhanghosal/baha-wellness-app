#!/usr/bin/env sh
set -eu

if [ "${RUN_MIGRATIONS:-true}" = "true" ]; then
  alembic upgrade head
fi

exec uvicorn baha_companion.main:app --host 0.0.0.0 --port "${PORT:-8000}"

