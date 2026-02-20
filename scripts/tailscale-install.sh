#!/bin/bash
# =============================================================================
# OpenClaw Tailscale Install
# =============================================================================
# Purpose: Install Tailscale on the running VPS and optionally authenticate.
# Usage:   ./scripts/tailscale-install.sh [VPS_IP]
#
# Set TF_VAR_tailscale_auth_key to authenticate automatically.
# Otherwise run: make tailscale-up
# =============================================================================

set -euo pipefail

VPS_USER="openclaw"
TERRAFORM_DIR="infra/terraform/envs/prod"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/id_rsa}"

if [[ -n "${1:-}" ]]; then
    VPS_IP="$1"
else
    VPS_IP=$(cd "$TERRAFORM_DIR" && terraform output -raw server_ip 2>/dev/null) || {
        echo "Error: Could not get VPS IP from terraform output."
        echo "Usage: $0 <VPS_IP>"
        exit 1
    }
fi

SSH_OPTS="-o StrictHostKeyChecking=accept-new -i $SSH_KEY"

echo "=== Install Tailscale ==="
echo "Server: $VPS_IP"
echo ""

# -----------------------------------------------------------------------------
# Install and start tailscaled
# -----------------------------------------------------------------------------

echo "[...] Installing Tailscale..."
ssh $SSH_OPTS "$VPS_USER@$VPS_IP" \
    'curl -fsSL https://tailscale.com/install.sh | sh && sudo systemctl enable --now tailscaled'
echo "[OK]  Tailscale installed and running"

# -----------------------------------------------------------------------------
# Authenticate
# -----------------------------------------------------------------------------

AUTH_KEY="${TF_VAR_tailscale_auth_key:-}"
if [[ -n "$AUTH_KEY" ]]; then
    echo ""
    echo "[...] Authenticating with auth key..."
    ssh $SSH_OPTS "$VPS_USER@$VPS_IP" \
        "sudo tailscale up --auth-key=\"$AUTH_KEY\" --hostname=\"openclaw-prod\" --accept-routes"
    echo "[OK]  Tailscale authenticated"
else
    echo ""
    echo "[WARN] TF_VAR_tailscale_auth_key not set — authenticate manually:"
    echo "       make tailscale-up"
fi

# -----------------------------------------------------------------------------
# Open UFW for Tailscale
# -----------------------------------------------------------------------------

echo ""
echo "[...] Allowing Tailscale in UFW..."
ssh $SSH_OPTS "$VPS_USER@$VPS_IP" \
    'sudo ufw allow 41641/udp comment "Tailscale" 2>/dev/null || true'
echo "[OK]  UFW updated"

echo ""
echo "=== Done ==="
echo "Check status: make tailscale-status"
echo "Get IP:       make tailscale-ip"
