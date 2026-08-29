#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

say() { printf '%s\n' "$*"; }
warn() { printf 'WARNING: %s\n' "$*" >&2; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

root_exec() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
  elif have sudo; then
    sudo "$@"
  else
    die "This step needs root privileges. Re-run as root or install sudo."
  fi
}

random_hex() {
  local bytes="${1:-32}"
  if have openssl; then
    openssl rand -hex "$bytes"
  elif have python3; then
    python3 - "$bytes" <<'PY'
import secrets, sys
print(secrets.token_hex(int(sys.argv[1])))
PY
  else
    od -An -N"$bytes" -tx1 /dev/urandom | tr -d ' \n'
  fi
}

env_value() {
  local name="$1"
  grep -E "^${name}=" .env 2>/dev/null | tail -n1 | cut -d= -f2- || true
}

set_env_var() {
  local name="$1" value="$2" tmp
  tmp="$(mktemp)"
  if [[ -f .env ]] && grep -qE "^${name}=" .env; then
    awk -v key="$name" -v val="$value" '
      index($0, key "=") == 1 { print key "=" val; next }
      { print }
    ' .env > "$tmp"
  else
    [[ -f .env ]] && cat .env > "$tmp"
    printf '\n%s=%s\n' "$name" "$value" >> "$tmp"
  fi
  chmod 600 "$tmp"
  mv "$tmp" .env
}

ensure_secret_var() {
  local name="$1" bytes="$2"
  if grep -qE "^${name}=" .env 2>/dev/null; then
    return
  fi
  printf '\n%s=%s\n' "$name" "$(random_hex "$bytes")" >> .env
}

ensure_env() {
  if [[ ! -f .env ]]; then
    umask 077
    cat > .env <<EOF
POSTGRES_PASSWORD=$(random_hex 24)
JWT_SECRET=$(random_hex 48)
TURN_SHARED_SECRET=$(random_hex 32)
ACCESS_TOKEN_TTL_SECONDS=900
CORS_ORIGIN=*
MAX_UPLOAD_BYTES=26214400
TURN_HOST=
TURN_PORT=3478
TURN_REALM=chatnu
TURN_MIN_PORT=49160
TURN_MAX_PORT=49200
TURN_DETECT_EXTERNAL_IP=yes
FIREBASE_SERVICE_ACCOUNT_B64=
CHATNU_API_URL=http://10.0.2.2:3000/
CHATNU_WS_URL=ws://10.0.2.2:3000/realtime
CHATNU_BIND_ADDRESS=127.0.0.1
CHATNU_HOST_PORT=3000
CHATNU_EDGE_BIND_ADDRESS=0.0.0.0
CHATNU_HTTPS_PORT=443
CHATNU_PUBLIC_NAME=
CHATNU_TLS_MODE=
EOF
    chmod 600 .env
    say "Created .env with random PostgreSQL, JWT and TURN secrets."
  else
    ensure_secret_var "TURN_SHARED_SECRET" 32
    chmod 600 .env
    [[ -n "$(env_value CHATNU_BIND_ADDRESS)" ]] || set_env_var CHATNU_BIND_ADDRESS "127.0.0.1"
    [[ -n "$(env_value CHATNU_HOST_PORT)" ]] || set_env_var CHATNU_HOST_PORT "3000"
    [[ -n "$(env_value CHATNU_EDGE_BIND_ADDRESS)" ]] || set_env_var CHATNU_EDGE_BIND_ADDRESS "0.0.0.0"
    [[ -n "$(env_value CHATNU_HTTPS_PORT)" ]] || set_env_var CHATNU_HTTPS_PORT "443"
    grep -q '^CHATNU_PUBLIC_NAME=' .env || set_env_var CHATNU_PUBLIC_NAME ""
    grep -q '^CHATNU_TLS_MODE=' .env || set_env_var CHATNU_TLS_MODE ""
  fi
}

require_docker() {
  have docker || die "Docker Engine is required."
  docker compose version >/dev/null 2>&1 || die "Docker Compose v2 is required (docker compose)."
}

ensure_api_image() {
  if ! docker image inspect chatnu-api:local >/dev/null 2>&1; then
    say "Building the ChatNU API image (first online install only)..."
    docker compose build api
  fi
}

ensure_edge_image() {
  if ! docker image inspect nginx:1.27-alpine >/dev/null 2>&1; then
    say "Fetching the Nginx edge image..."
    docker pull nginx:1.27-alpine
  fi
}

start_base_stack() {
  ensure_api_image
  docker compose up -d --no-build
}

listener_lines() {
  local proto="$1"
  if have ss; then
    if [[ "$proto" == "tcp" ]]; then ss -H -ltnp 2>/dev/null || true
    else ss -H -lunp 2>/dev/null || true
    fi
  elif have netstat; then
    if [[ "$proto" == "tcp" ]]; then netstat -ltnp 2>/dev/null | tail -n +3 || true
    else netstat -lunp 2>/dev/null | tail -n +3 || true
    fi
  fi
}

port_in_use() {
  local proto="$1" port="$2"
  listener_lines "$proto" | awk '{print $4}' | grep -Eq "[:.]${port}$|\\]:${port}$"
}

listener_info() {
  local proto="$1" port="$2"
  listener_lines "$proto" | grep -E "[:.]${port}([[:space:]]|$)|\\]:${port}([[:space:]]|$)" || true
}

find_free_tcp_port() {
  local start="$1" max="${2:-65535}" port
  for ((port=start; port<=max; port++)); do
    if ! port_in_use tcp "$port"; then
      printf '%s\n' "$port"
      return 0
    fi
  done
  return 1
}

find_free_turn_port() {
  local start="${1:-3478}" port
  for ((port=start; port<=start+100; port++)); do
    if ! port_in_use tcp "$port" && ! port_in_use udp "$port"; then
      printf '%s\n' "$port"
      return 0
    fi
  done
  return 1
}

first_local_ip() {
  if have hostname; then
    hostname -I 2>/dev/null | tr ' ' '\n' | grep -E '^[0-9a-fA-F:.]+$' | grep -v '^127\.' | head -n1 || true
  fi
}

all_local_ips() {
  if have hostname; then
    hostname -I 2>/dev/null | tr ' ' '\n' | grep -E '^[0-9a-fA-F:.]+$' | grep -v '^127\.' | sort -u || true
  fi
}

validate_public_name() {
  local value="$1"
  [[ "$value" =~ ^[A-Za-z0-9.-]+$ || "$value" =~ ^[0-9A-Fa-f:]+$ ]]
}

is_ip_literal() {
  local value="$1"
  [[ "$value" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ || "$value" == *:* ]]
}

format_origin() {
  local host="$1" port="$2" host_part="$host"
  [[ "$host" == *:* && "$host" != \[*\] ]] && host_part="[$host]"
  if [[ "$port" == "443" ]]; then
    printf 'https://%s' "$host_part"
  else
    printf 'https://%s:%s' "$host_part" "$port"
  fi
}

api_port() {
  local value
  value="$(env_value CHATNU_HOST_PORT)"
  printf '%s\n' "${value:-3000}"
}

health_ok() {
  local port
  port="$(api_port)"
  local url="http://127.0.0.1:${port}/health"
  if have curl; then
    curl -fsS --max-time 3 "$url" >/dev/null 2>&1 && return 0
  fi
  docker compose exec -T api node -e \
    "fetch('http://127.0.0.1:3000/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))" \
    >/dev/null 2>&1
}

wait_for_health() {
  local port
  port="$(api_port)"
  local url="http://127.0.0.1:${port}/health"
  for _ in $(seq 1 60); do
    if health_ok; then
      say "ChatNU API is healthy: $url"
      return 0
    fi
    sleep 2
  done
  warn "API did not become healthy. Recent logs:"
  docker compose logs --tail=150 api >&2 || true
  return 1
}

install_packages_for_public_tls() {
  if ! have nginx; then
    say "Nginx is not installed. Installing it..."
    if have apt-get; then
      root_exec apt-get update
      root_exec env DEBIAN_FRONTEND=noninteractive apt-get install -y nginx
    elif have dnf; then
      root_exec dnf install -y nginx
    elif have yum; then
      root_exec yum install -y nginx
    else
      die "Could not install Nginx automatically on this distribution."
    fi
  fi

  if ! have certbot; then
    say "Certbot is not installed. Installing it..."
    if have apt-get; then
      root_exec apt-get update
      root_exec env DEBIAN_FRONTEND=noninteractive apt-get install -y certbot python3-certbot-nginx
    elif have dnf; then
      root_exec dnf install -y certbot python3-certbot-nginx
    elif have yum; then
      root_exec yum install -y certbot python3-certbot-nginx
    else
      die "Could not install Certbot automatically on this distribution."
    fi
  fi

  if have systemctl; then
    root_exec systemctl enable --now nginx
  fi
}

write_host_nginx_config() {
  local name="$1" port="$2" safe tmp conf
  safe="$(printf '%s' "$name" | tr -cs 'A-Za-z0-9._-' '_')"
  conf="/etc/nginx/conf.d/chatnu-${safe}.conf"
  tmp="$(mktemp)"
  cat > "$tmp" <<EOF
map \$http_upgrade \$connection_upgrade_chatnu {
    default upgrade;
    '' close;
}

server {
    listen 80;
    server_name ${name};

    client_max_body_size 25m;

    location /realtime {
        proxy_pass http://127.0.0.1:${port};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$connection_upgrade_chatnu;
        proxy_set_header Host \$host;
        proxy_set_header Authorization \$http_authorization;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 75s;
    }

    location / {
        proxy_pass http://127.0.0.1:${port};
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header Authorization \$http_authorization;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
  root_exec install -m 0644 "$tmp" "$conf"
  rm -f "$tmp"
  root_exec nginx -t
  if have systemctl; then root_exec systemctl reload nginx
  else root_exec nginx -s reload
  fi
}

setup_public_tls() {
  local name="$1" email
  if is_ip_literal "$name"; then
    die "For the one-click public flow, use a DNS name. IP certificates need a newer short-lived Certbot flow; emergency mode supports IPs directly."
  fi
  install_packages_for_public_tls

  if port_in_use tcp 80 && ! listener_info tcp 80 | grep -qi nginx; then
    warn "TCP/80 is already used by a non-Nginx process:"
    listener_info tcp 80 >&2
    die "Public HTTP-01 issuance needs port 80. Free it or use emergency mode."
  fi
  if port_in_use tcp 443 && ! listener_info tcp 443 | grep -qi nginx; then
    warn "TCP/443 is already used by a non-Nginx process:"
    listener_info tcp 443 >&2
    die "Public HTTPS normally needs port 443. Free it or use emergency mode on an alternate port."
  fi

  write_host_nginx_config "$name" "$(api_port)"

  read -r -p "Optional email for Let's Encrypt expiry/security notices (Enter to skip): " email || true
  say "Requesting a publicly trusted certificate..."
  if [[ -n "${email:-}" ]]; then
    root_exec certbot --nginx --non-interactive --agree-tos --redirect --email "$email" -d "$name"
  else
    root_exec certbot --nginx --non-interactive --agree-tos --redirect --register-unsafely-without-email -d "$name"
  fi

  set_env_var CHATNU_TLS_MODE "public"
  set_env_var CHATNU_HTTPS_PORT "443"
  say "Public TLS is configured through Nginx on 0.0.0.0:80/443."
}

write_emergency_san_config() {
  local name="$1" index=1 ip
  mkdir -p deploy/tls
  {
    echo "basicConstraints=CA:FALSE"
    echo "keyUsage=digitalSignature,keyEncipherment"
    echo "extendedKeyUsage=serverAuth"
    echo "subjectAltName=@alt_names"
    echo
    echo "[alt_names]"
    if is_ip_literal "$name"; then
      echo "IP.${index}=${name}"
    else
      echo "DNS.1=${name}"
    fi
    index=$((index + 1))
    while read -r ip; do
      [[ -n "$ip" && "$ip" != "$name" ]] || continue
      if [[ "$ip" =~ ^[0-9A-Fa-f:.]+$ ]]; then
        echo "IP.${index}=${ip}"
        index=$((index + 1))
      fi
    done < <(all_local_ips)
  } > deploy/tls/server.ext
}

generate_emergency_tls() {
  local name="$1"
  require_docker
  mkdir -p deploy/tls
  chmod 700 deploy/tls

  say "Preparing ChatNU's built-in certificate generator..."
  ensure_api_image

  if [[ ! -s deploy/tls/ca.key || ! -s deploy/tls/ca.crt ]]; then
    say "Generating persistent ChatNU Emergency Local CA..."
    docker compose run --rm --no-deps \
      -v "$ROOT/deploy/tls:/tls" api sh -ceu '
        umask 077
        openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out /tls/ca.key
        openssl req -x509 -new -key /tls/ca.key -sha256 -days 3650 \
          -subj "/CN=ChatNU Emergency Local CA" -out /tls/ca.crt
      '
  else
    say "Reusing the existing emergency CA so enrolled phones keep trusting this server."
  fi

  write_emergency_san_config "$name"
  docker compose run --rm --no-deps \
    -v "$ROOT/deploy/tls:/tls" api sh -ceu "
      umask 077
      openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out /tls/server.key
      openssl req -new -key /tls/server.key -subj '/CN=${name}' -out /tls/server.csr
      openssl x509 -req -in /tls/server.csr -CA /tls/ca.crt -CAkey /tls/ca.key \
        -CAcreateserial -out /tls/server.crt -days 825 -sha256 -extfile /tls/server.ext
      cat /tls/server.crt /tls/ca.crt > /tls/fullchain.pem
      rm -f /tls/server.csr
    "
  root_exec chmod 600 deploy/tls/ca.key deploy/tls/server.key
  root_exec chmod 644 deploy/tls/ca.crt deploy/tls/server.crt deploy/tls/fullchain.pem deploy/tls/server.ext

  docker compose run --rm --no-deps \
    -v "$ROOT/deploy/tls:/tls:ro" api sh -ceu \
    'openssl x509 -in /tls/ca.crt -pubkey -noout \
      | openssl pkey -pubin -outform der \
      | openssl dgst -sha256 -binary \
      | openssl base64 -A'
}

setup_emergency_tls() {
  local name="$1" https_port pin origin
  pin="$(generate_emergency_tls "$name")"
  pin="${pin##*$'\n'}"

  https_port=443
  if port_in_use tcp "$https_port"; then
    https_port="$(find_free_tcp_port 8443 8543)" || die "Could not find a free emergency HTTPS port."
    warn "TCP/443 is occupied; emergency TLS will use ${https_port} instead."
  fi

  set_env_var CHATNU_TLS_MODE "emergency"
  set_env_var CHATNU_EDGE_BIND_ADDRESS "0.0.0.0"
  set_env_var CHATNU_HTTPS_PORT "$https_port"

  ensure_edge_image
  docker compose -f docker-compose.yml -f docker-compose.edge.yml up -d --no-build
  wait_for_health

  origin="$(format_origin "$name" "$https_port")"
  say
  say "Emergency TLS is active."
  say "Server URL: ${origin}"
  say "Emergency enrollment link (paste this whole line into ChatNU Android):"
  say "${origin}#chatnu-ca=${pin}"
  say
  say "The CA private key stays at deploy/tls/ca.key. Back it up securely; do not share it."
}

configure_ports() {
  local current_api chosen_api current_turn chosen_turn

  current_api="$(env_value CHATNU_HOST_PORT)"
  current_api="${current_api:-3000}"
  if port_in_use tcp "$current_api"; then
    chosen_api="$(find_free_tcp_port 3000 3099)" || die "No free local API port found in 3000-3099."
    warn "Local API port ${current_api} is occupied; using ${chosen_api}."
  else
    chosen_api="$current_api"
  fi
  set_env_var CHATNU_BIND_ADDRESS "127.0.0.1"
  set_env_var CHATNU_HOST_PORT "$chosen_api"

  current_turn="$(env_value TURN_PORT)"
  current_turn="${current_turn:-3478}"
  if port_in_use tcp "$current_turn" || port_in_use udp "$current_turn"; then
    chosen_turn="$(find_free_turn_port 3478)" || die "Could not find a free TURN port."
    warn "TURN port ${current_turn} is occupied; using ${chosen_turn} TCP/UDP."
  else
    chosen_turn="$current_turn"
  fi
  set_env_var TURN_PORT "$chosen_turn"
}

open_firewall_if_requested() {
  local https_port turn_port min_port max_port answer
  https_port="$(env_value CHATNU_HTTPS_PORT)"; https_port="${https_port:-443}"
  turn_port="$(env_value TURN_PORT)"; turn_port="${turn_port:-3478}"
  min_port="$(env_value TURN_MIN_PORT)"; min_port="${min_port:-49160}"
  max_port="$(env_value TURN_MAX_PORT)"; max_port="${max_port:-49200}"

  read -r -p "Open ChatNU firewall ports automatically when a supported firewall is active? [Y/n]: " answer || true
  [[ "${answer:-Y}" =~ ^[Nn]$ ]] && return 0

  if have ufw && root_exec ufw status 2>/dev/null | grep -q "Status: active"; then
    if [[ "$(env_value CHATNU_TLS_MODE)" == "public" ]]; then root_exec ufw allow "80/tcp"; fi
    root_exec ufw allow "${https_port}/tcp"
    root_exec ufw allow "${turn_port}/tcp"
    root_exec ufw allow "${turn_port}/udp"
    root_exec ufw allow "${min_port}:${max_port}/udp"
  elif have firewall-cmd && root_exec firewall-cmd --state >/dev/null 2>&1; then
    if [[ "$(env_value CHATNU_TLS_MODE)" == "public" ]]; then root_exec firewall-cmd --permanent --add-port="80/tcp"; fi
    root_exec firewall-cmd --permanent --add-port="${https_port}/tcp"
    root_exec firewall-cmd --permanent --add-port="${turn_port}/tcp"
    root_exec firewall-cmd --permanent --add-port="${turn_port}/udp"
    root_exec firewall-cmd --permanent --add-port="${min_port}-${max_port}/udp"
    root_exec firewall-cmd --reload
  else
    say "No active ufw/firewalld detected; no firewall rules were changed."
  fi
}

print_network_summary() {
  local name mode https_port turn_port min_port max_port origin
  name="$(env_value CHATNU_PUBLIC_NAME)"
  mode="$(env_value CHATNU_TLS_MODE)"
  https_port="$(env_value CHATNU_HTTPS_PORT)"; https_port="${https_port:-443}"
  turn_port="$(env_value TURN_PORT)"; turn_port="${turn_port:-3478}"
  min_port="$(env_value TURN_MIN_PORT)"; min_port="${min_port:-49160}"
  max_port="$(env_value TURN_MAX_PORT)"; max_port="${max_port:-49200}"

  say
  say "=== ChatNU network summary ==="
  say "Internal API: 127.0.0.1:$(api_port) (not exposed directly)"
  [[ -n "$name" ]] && {
    origin="$(format_origin "$name" "$https_port")"
    say "Client server URL: ${origin}"
  }
  say "TLS mode: ${mode:-not configured}"
  say "Public edge bind: 0.0.0.0:${https_port}/tcp"
  say "TURN: ${turn_port}/tcp + ${turn_port}/udp"
  say "TURN relay media: ${min_port}-${max_port}/udp"
  local ips
  ips="$(all_local_ips | paste -sd ', ' -)"
  [[ -n "$ips" ]] && say "Host addresses seen locally: $ips"
  say
  say "Listening sockets matching ChatNU ports:"
  listener_info tcp "$https_port"
  listener_info tcp "$turn_port"
  listener_info udp "$turn_port"
}

wizard() {
  require_docker
  ensure_env
  # Stop only this project's containers before probing ports, without deleting data.
  docker compose -f docker-compose.yml -f docker-compose.edge.yml down >/dev/null 2>&1 || true
  configure_ports

  local detected name mode default_mode
  detected="$(env_value CHATNU_PUBLIC_NAME)"
  [[ -n "$detected" ]] || detected="$(first_local_ip)"
  say
  say "ChatNU server setup"
  say "-------------------"
  say "The API stays private on 127.0.0.1. Only the TLS edge and TURN are exposed publicly."
  read -r -p "Domain or reachable IP [${detected:-chat.example.com}]: " name || true
  name="${name:-${detected:-}}"
  [[ -n "$name" ]] || die "A domain or reachable IP is required."
  validate_public_name "$name" || die "Use only a hostname or IP address, without http://, paths, or credentials."

  set_env_var CHATNU_PUBLIC_NAME "$name"
  set_env_var TURN_HOST "$name"

  default_mode="public"
  say
  say "TLS mode:"
  say "  1) Public / Let's Encrypt (normal Internet)"
  say "  2) Emergency offline CA (blackout / LAN / isolated network)"
  read -r -p "Choose [1]: " mode || true
  mode="${mode:-1}"

  start_base_stack
  wait_for_health

  case "$mode" in
    1|public)
      setup_public_tls "$name"
      ;;
    2|emergency|offline)
      setup_emergency_tls "$name"
      ;;
    *)
      die "Unknown TLS mode."
      ;;
  esac

  open_firewall_if_requested
  print_network_summary

  say
  say "Users create/login to accounts by entering the printed Client server URL on ChatNU's sign-in screen."
  if [[ "$(env_value CHATNU_TLS_MODE)" == "emergency" ]]; then
    say "For emergency mode they must paste the full enrollment link with #chatnu-ca=... on first connection."
  fi
}

offline_export() {
  require_docker
  ensure_env
  local out="${1:-chatnu-offline-images.tar}"
  say "Preparing images for an offline/blackout install..."
  docker compose pull postgres redis turn
  docker pull nginx:1.27-alpine
  docker compose build api
  docker save -o "$out" \
    postgres:16-alpine \
    redis:7-alpine \
    coturn/coturn:4.17.2 \
    nginx:1.27-alpine \
    chatnu-api:local
  say "Offline image bundle created: $out"
  say "Copy the repository plus this TAR to the isolated host, install Docker ahead of time, then run:"
  say "  ./scripts/chatnu.sh offline-import $out"
  say "  ./scripts/chatnu.sh install"
}

offline_import() {
  require_docker
  local input="${1:-chatnu-offline-images.tar}"
  [[ -f "$input" ]] || die "Offline image bundle not found: $input"
  docker load -i "$input"
  say "Offline images loaded. You can now run ./scripts/chatnu.sh install and choose emergency mode."
}

cmd="${1:-install}"
case "$cmd" in
  install|wizard|setup)
    wizard
    ;;
  up)
    require_docker
    ensure_env
    docker compose up -d --build
    wait_for_health
    print_network_summary
    ;;
  emergency)
    require_docker
    ensure_env
    configure_ports
    name="${2:-$(env_value CHATNU_PUBLIC_NAME)}"
    [[ -n "$name" ]] || die "Usage: $0 emergency <domain-or-ip>"
    validate_public_name "$name" || die "Invalid domain/IP."
    set_env_var CHATNU_PUBLIC_NAME "$name"
    set_env_var TURN_HOST "$name"
    start_base_stack
    wait_for_health
    setup_emergency_tls "$name"
    print_network_summary
    ;;
  down)
    require_docker
    docker compose -f docker-compose.yml -f docker-compose.edge.yml down
    ;;
  restart)
    require_docker
    ensure_env
    if [[ "$(env_value CHATNU_TLS_MODE)" == "emergency" ]]; then
      ensure_api_image
      ensure_edge_image
      docker compose -f docker-compose.yml -f docker-compose.edge.yml up -d --no-build --force-recreate
    else
      docker compose up -d --build --force-recreate
    fi
    wait_for_health
    ;;
  reset)
    require_docker
    ensure_env
    warn "reset deletes PostgreSQL, Redis and attachment volumes. Emergency CA files are preserved."
    mode_before_reset="$(env_value CHATNU_TLS_MODE)"
    docker compose -f docker-compose.yml -f docker-compose.edge.yml down -v
    if [[ "$mode_before_reset" == "emergency" ]]; then
      ensure_api_image
      ensure_edge_image
      docker compose -f docker-compose.yml -f docker-compose.edge.yml up -d --no-build
    else
      start_base_stack
    fi
    wait_for_health
    ;;
  logs)
    require_docker
    if [[ "$(env_value CHATNU_TLS_MODE 2>/dev/null || true)" == "emergency" ]]; then
      docker compose -f docker-compose.yml -f docker-compose.edge.yml logs -f --tail=200 api turn edge
    else
      docker compose logs -f --tail=200 api turn
    fi
    ;;
  status)
    require_docker
    ensure_env
    if [[ "$(env_value CHATNU_TLS_MODE)" == "emergency" ]]; then
      docker compose -f docker-compose.yml -f docker-compose.edge.yml ps
    else
      docker compose ps
    fi
    print_network_summary
    ;;
  offline-export)
    offline_export "${2:-chatnu-offline-images.tar}"
    ;;
  offline-import)
    offline_import "${2:-chatnu-offline-images.tar}"
    ;;
  *)
    cat >&2 <<EOF
Usage: $0 {install|up|emergency <host>|down|restart|reset|logs|status|offline-export [tar]|offline-import [tar]}

install        interactive domain/IP + ports + Nginx/Let's Encrypt or emergency TLS wizard
emergency      switch/start emergency pinned TLS without contacting a public CA
offline-export prepare Docker images before a blackout
offline-import load a prepared Docker image bundle on an isolated server
EOF
    exit 2
    ;;
esac
