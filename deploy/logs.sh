#!/bin/bash
# =============================================================================
# OpenClaw Logs Script
# =============================================================================
# Purpose: View Docker container logs from the VPS.
# Usage: ./deploy/logs.sh [VPS_IP]
#
# This script SSHs into the VPS and streams Docker Compose logs.
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

VPS_USER="openclaw"
TERRAFORM_DIR="infra/terraform/envs/prod"

# SSH key and port
SSH_KEY="${SSH_KEY:-$HOME/.ssh/id_rsa}"
SSH_PORT=$(cd "$TERRAFORM_DIR" && terraform output -raw ssh_port 2>/dev/null) || SSH_PORT=22
SSH_OPTS="-o StrictHostKeyChecking=accept-new -i $SSH_KEY -p $SSH_PORT"

# -----------------------------------------------------------------------------
# Get VPS IP
# -----------------------------------------------------------------------------

if [[ -n "${1:-}" ]]; then
    VPS_IP="$1"
else
    if command -v terraform &> /dev/null && [[ -d "$TERRAFORM_DIR/.terraform" ]]; then
        VPS_IP=$(cd "$TERRAFORM_DIR" && terraform output -raw server_ip 2>/dev/null) || {
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

echo "=== OpenClaw Logs ==="
echo "VPS IP: $VPS_IP"
echo "Press Ctrl+C to exit"
echo ""

# -----------------------------------------------------------------------------
# Stream logs
# -----------------------------------------------------------------------------

ssh $SSH_OPTS -t "$VPS_USER@$VPS_IP" \
    "cd ~/openclaw && docker compose logs -f --tail 100"
