#!/bin/bash
# =============================================================================
# OpenClaw Deploy Latest (GHCR-driven config sync)
# =============================================================================
# Purpose:
#   Deploy latest OpenClaw image from GHCR and restart gateway, while avoiding
#   local config SCP. Runtime config is synced from image by entrypoint when
#   SYNC_CONFIG_FROM_IMAGE=1 in .env.
#
# Usage:
#   ./scripts/deploy-latest-ghcr.sh [VPS_IP]
#
# Optional environment:
#   SSH_KEY_PATH  Path to SSH private key (default: ~/.ssh/openclaw_hetzner_codex if present)
#   CONFIG_DIR    Path to openclaw-docker-config repo (default: ../openclaw-docker-config)
# =============================================================================

set -euo pipefail

VPS_USER="openclaw"
TERRAFORM_DIR="infra/terraform/envs/prod"
ENV_FILE="secrets/openclaw.env"
CONFIG_DIR="${CONFIG_DIR:-../openclaw-docker-config}"
COMPOSE_FILE="${CONFIG_DIR%/}/docker/docker-compose.yml"
REMOTE_ENV_PATH="/home/openclaw/openclaw/.env"
REMOTE_COMPOSE_PATH="/home/openclaw/openclaw/docker-compose.yml"

DEFAULT_SSH_KEY="$HOME/.ssh/openclaw_hetzner_codex"
SSH_KEY_PATH="${SSH_KEY_PATH:-}"

SSH_CMD=(ssh -o StrictHostKeyChecking=accept-new)
SCP_CMD=(scp -o StrictHostKeyChecking=accept-new)

if [[ -z "$SSH_KEY_PATH" && -f "$DEFAULT_SSH_KEY" ]]; then
    SSH_KEY_PATH="$DEFAULT_SSH_KEY"
fi
if [[ -n "$SSH_KEY_PATH" ]]; then
    SSH_CMD+=(-i "$SSH_KEY_PATH")
    SCP_CMD+=(-i "$SSH_KEY_PATH")
fi

if [[ -n "${1:-}" ]]; then
    VPS_IP="$1"
else
    if command -v terraform >/dev/null 2>&1 && [[ -d "$TERRAFORM_DIR/.terraform" ]]; then
        VPS_IP="$(cd "$TERRAFORM_DIR" && terraform output -raw server_ip 2>/dev/null)" || {
            echo "Error: Could not get VPS IP from terraform output."
            echo "Usage: $0 <VPS_IP>"
            exit 1
        }
    else
        echo "Error: No VPS IP provided and terraform not available."
        echo "Usage: $0 <VPS_IP>"
        exit 1
    fi
fi

if [[ ! -f "$ENV_FILE" ]]; then
    echo "Error: $ENV_FILE not found"
    exit 1
fi
if [[ ! -f "$COMPOSE_FILE" ]]; then
    echo "Error: $COMPOSE_FILE not found"
    echo "Set CONFIG_DIR to your openclaw-docker-config path."
    exit 1
fi

REQUIRED_VARS=(
    GHCR_USERNAME
    GHCR_IMAGE_OWNER
    GHCR_TOKEN
    OPENCLAW_GATEWAY_TOKEN
)

MISSING=()
for var in "${REQUIRED_VARS[@]}"; do
    value="$(grep -E "^${var}=" "$ENV_FILE" | head -1 | cut -d= -f2-)"
    if [[ -z "$value" ]]; then
        MISSING+=("$var")
    fi
done

if [[ ${#MISSING[@]} -gt 0 ]]; then
    echo "Error: Missing required values in $ENV_FILE:"
    for var in "${MISSING[@]}"; do
        echo "  - $var"
    done
    exit 1
fi

echo "=== OpenClaw Deploy Latest (GHCR) ==="
echo "VPS: $VPS_USER@$VPS_IP"
echo "Env: $ENV_FILE -> $REMOTE_ENV_PATH"
echo "Compose: $COMPOSE_FILE -> $REMOTE_COMPOSE_PATH"
echo ""

echo "[...] Syncing .env and docker-compose.yml to VPS..."
"${SCP_CMD[@]}" "$ENV_FILE" "$VPS_USER@$VPS_IP:$REMOTE_ENV_PATH"
"${SCP_CMD[@]}" "$COMPOSE_FILE" "$VPS_USER@$VPS_IP:$REMOTE_COMPOSE_PATH"
echo "[OK] Files synced"

echo ""
echo "[...] Pulling latest GHCR image and restarting gateway..."
"${SSH_CMD[@]}" "$VPS_USER@$VPS_IP" "bash -s" <<'REMOTE_SCRIPT'
set -euo pipefail

cd "$HOME/openclaw"

if [[ ! -f ".env" ]]; then
    echo "Error: .env missing at ~/openclaw/.env"
    exit 1
fi
if [[ ! -f "docker-compose.yml" ]]; then
    echo "Error: docker-compose.yml missing at ~/openclaw/docker-compose.yml"
    exit 1
fi

GHCR_USERNAME="$(grep -E '^GHCR_USERNAME=' .env | head -1 | cut -d= -f2-)"
GHCR_TOKEN="$(grep -E '^GHCR_TOKEN=' .env | head -1 | cut -d= -f2-)"
GHCR_IMAGE_OWNER="$(grep -E '^GHCR_IMAGE_OWNER=' .env | head -1 | cut -d= -f2-)"

echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USERNAME" --password-stdin >/dev/null 2>&1
docker manifest inspect "ghcr.io/${GHCR_IMAGE_OWNER}/openclaw-docker-config/openclaw-gateway:latest" >/dev/null

docker compose pull openclaw-gateway
docker compose up -d openclaw-gateway
sleep 5

echo ""
echo "[status]"
docker compose ps

CID="$(docker compose ps -q openclaw-gateway)"
echo ""
echo "[running image]"
docker inspect "$CID" --format '{{.Config.Image}}'

echo ""
echo "[agents]"
jq -r '.agents.list[] | .name' /home/openclaw/.openclaw/openclaw.json || true

echo ""
echo "[health]"
python3 - <<'PY'
import socket
s=socket.socket()
s.settimeout(6)
try:
    s.connect(("127.0.0.1", 18789))
    s.sendall(b"GET / HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n")
    data=s.recv(200)
    if data:
        print(data.decode("latin1","ignore").splitlines()[0])
    else:
        print("No HTTP response")
except Exception as e:
    print("Health check error:", e)
finally:
    s.close()
PY
REMOTE_SCRIPT

echo ""
echo "=== Done ==="
