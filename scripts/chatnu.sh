#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

random_hex() {
  local bytes="${1:-32}"
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -hex "$bytes"
  elif command -v python3 >/dev/null 2>&1; then
    python3 - "$bytes" <<'PY'
import secrets, sys
print(secrets.token_hex(int(sys.argv[1])))
PY
  else
    od -An -N"$bytes" -tx1 /dev/urandom | tr -d ' \n'
  fi
}

ensure_env() {
  if [[ -f .env ]]; then
    return
  fi

  umask 077
  local postgres_password jwt_secret
  postgres_password="$(random_hex 24)"
  jwt_secret="$(random_hex 48)"

  cat > .env <<EOF
POSTGRES_PASSWORD=${postgres_password}
JWT_SECRET=${jwt_secret}
ACCESS_TOKEN_TTL_SECONDS=900
CORS_ORIGIN=*
MAX_UPLOAD_BYTES=26214400
CHATNU_API_URL=http://10.0.2.2:3000/
CHATNU_WS_URL=ws://10.0.2.2:3000/realtime
EOF
  chmod 600 .env
  echo "Created .env with randomly generated server secrets."
}

require_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    echo "Docker is required. Install Docker Engine + Compose v2 first." >&2
    exit 1
  fi
  if ! docker compose version >/dev/null 2>&1; then
    echo "Docker Compose v2 is required (the 'docker compose' command)." >&2
    exit 1
  fi
}

wait_for_health() {
  local url="http://127.0.0.1:3000/health"
  for _ in $(seq 1 40); do
    if command -v curl >/dev/null 2>&1 && curl -fsS "$url" >/dev/null 2>&1; then
      echo "ChatNU API is healthy: $url"
      return 0
    fi
    sleep 2
  done
  echo "API did not become healthy. Recent logs:" >&2
  docker compose logs --tail=100 api >&2 || true
  return 1
}

cmd="${1:-up}"
case "$cmd" in
  up)
    require_docker
    ensure_env
    docker compose up -d --build
    wait_for_health
    echo "API: http://127.0.0.1:3000"
    ;;
  down)
    require_docker
    docker compose down
    ;;
  restart)
    require_docker
    ensure_env
    docker compose up -d --build --force-recreate api
    wait_for_health
    ;;
  reset)
    require_docker
    ensure_env
    echo "WARNING: reset deletes PostgreSQL, Redis and attachment volumes." >&2
    docker compose down -v
    docker compose up -d --build
    wait_for_health
    ;;
  logs)
    require_docker
    docker compose logs -f --tail=200 api
    ;;
  status)
    require_docker
    docker compose ps
    ;;
  *)
    echo "Usage: $0 {up|down|restart|reset|logs|status}" >&2
    exit 2
    ;;
esac
