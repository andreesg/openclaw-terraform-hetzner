#!/bin/bash
# =============================================================================
# OpenClaw Push SSH Daemon Config
# =============================================================================
# Purpose: Push config/sshd_config.tpl to the VPS, validate it, and reload
#          sshd. Hardens SSH: disables root login, password auth, etc.
# Usage:   ./scripts/push-sshd-config.sh [VPS_IP]
# =============================================================================

set -euo pipefail

VPS_USER="openclaw"
TERRAFORM_DIR="infra/terraform/envs/prod"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/id_rsa}"
TEMPLATE="config/sshd_config.tpl"

# -----------------------------------------------------------------------------
# Validate template exists
# -----------------------------------------------------------------------------

if [[ ! -f "$TEMPLATE" ]]; then
    echo "Error: $TEMPLATE not found"
    exit 1
fi

# -----------------------------------------------------------------------------
# Resolve server IP
# -----------------------------------------------------------------------------

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

echo "=== Push sshd Config ==="
echo "Server: $VPS_IP"
echo ""

# -----------------------------------------------------------------------------
# Upload and validate
# -----------------------------------------------------------------------------

echo "[...] Uploading config..."
ssh $SSH_OPTS "$VPS_USER@$VPS_IP" 'cat > /tmp/sshd_config_new' < "$TEMPLATE"

echo "[...] Validating config (sshd -t)..."
ssh $SSH_OPTS "$VPS_USER@$VPS_IP" 'sudo sshd -t -f /tmp/sshd_config_new'
echo "[OK]  Config is valid"

# -----------------------------------------------------------------------------
# Apply
# -----------------------------------------------------------------------------

echo "[...] Applying config..."
ssh $SSH_OPTS "$VPS_USER@$VPS_IP" '
    set -e
    sudo cp /tmp/sshd_config_new /etc/ssh/sshd_config
    rm /tmp/sshd_config_new
    sudo systemctl reload ssh
'

echo ""
echo "[OK] sshd config applied (port 22 unchanged, hardening active)"
