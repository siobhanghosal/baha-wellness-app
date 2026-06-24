#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is not installed or not on PATH."
  exit 1
fi

echo "Starting local BAHA database and API..."
docker compose up -d --build postgres api

echo
echo "Waiting for API health..."
for _ in {1..30}; do
  if curl -fsS http://localhost:8000/health >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

echo
echo "Local stack status:"
docker compose ps

LAN_IP=""
for iface in en0 en1; do
  if command -v ipconfig >/dev/null 2>&1; then
    candidate="$(ipconfig getifaddr "$iface" 2>/dev/null || true)"
    if [ -n "$candidate" ]; then
      LAN_IP="$candidate"
      break
    fi
  fi
done

echo
echo "Local API:"
echo "  http://localhost:8000"
echo "Database on host:"
echo "  postgresql://baha:baha@localhost:5433/baha_rag"

if [ -n "$LAN_IP" ]; then
  echo
  echo "Use this from your physical Android phone on the same Wi-Fi:"
  echo "  http://$LAN_IP:8000"
else
  echo
  echo "Could not auto-detect LAN IP. Run 'ipconfig getifaddr en0' on macOS."
fi

echo
echo "Student app example:"
if [ -n "$LAN_IP" ]; then
  echo "  flutter run --dart-define=BAHA_API_BASE_URL=http://$LAN_IP:8000"
else
  echo "  flutter run --dart-define=BAHA_API_BASE_URL=http://<your-lan-ip>:8000"
fi
