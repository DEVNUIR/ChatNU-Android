#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

cmd="${1:-up}"
case "$cmd" in
  up)
    if [[ ! -f .env ]]; then
      cp .env.example .env
      echo "Created .env. Change secrets before exposing this server to the internet."
    fi
    docker compose up -d --build
    echo "ChatNU API: http://127.0.0.1:3000"
    echo "Health:     http://127.0.0.1:3000/health"
    ;;
  down)
    docker compose down
    ;;
  reset)
    docker compose down -v
    docker compose up -d --build
    ;;
  logs)
    docker compose logs -f --tail=200 api
    ;;
  status)
    docker compose ps
    ;;
  *)
    echo "Usage: $0 {up|down|reset|logs|status}" >&2
    exit 2
    ;;
esac
