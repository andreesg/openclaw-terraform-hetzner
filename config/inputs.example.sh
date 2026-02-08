#!/bin/bash
# ============================================
# OpenClaw - Input Configuration Example
# ============================================
# Copy this file to inputs.sh and fill in your values:
#   cp config/inputs.example.sh config/inputs.sh
#
# Source before running Terraform:
#   source config/inputs.sh
#
# NEVER commit inputs.sh to version control

# ============================================
# REQUIRED: Hetzner Cloud API Token
# ============================================
# Generate at: https://console.hetzner.cloud/ -> Projects -> API Tokens
export HCLOUD_TOKEN="CHANGE_ME_your-hcloud-token-here"

# Terraform reads this as var.hcloud_token
export TF_VAR_hcloud_token="$HCLOUD_TOKEN"

# ============================================
# REQUIRED: Hetzner Object Storage (S3-compatible)
# ============================================
# For Terraform remote state storage
# Create bucket at: https://console.hetzner.cloud/ -> Object Storage
export S3_ENDPOINT="https://nbg1.your-objectstorage.com"
export S3_ACCESS_KEY="CHANGE_ME_your-s3-access-key"
export S3_SECRET_KEY="CHANGE_ME_your-s3-secret-key"
export S3_BUCKET="openclaw-tfstate"

# Terraform S3 backend uses AWS_ env vars
export AWS_ACCESS_KEY_ID="$S3_ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="$S3_SECRET_KEY"

# ============================================
# REQUIRED: SSH Configuration
# ============================================
# Allowed CIDRs for SSH access (use YOUR_IP/32 for single IPs)
# Find your IP: curl -s ifconfig.me
export TF_VAR_ssh_allowed_cidrs='["0.0.0.0/0"]'

# Fingerprint of your existing Hetzner SSH key (avoids recreating shared keys)
# List yours: curl -s -H "Authorization: Bearer $HCLOUD_TOKEN" https://api.hetzner.cloud/v1/ssh_keys | jq '.ssh_keys[] | {name, fingerprint}'
export TF_VAR_ssh_key_fingerprint="CHANGE_ME_your-ssh-key-fingerprint"

# ============================================
# REQUIRED: Config Directory
# ============================================
# Local path to your openclaw-config repository (used by bootstrap, push-config)
export CONFIG_DIR="/path/to/your/openclaw-config"

# ============================================
# OPTIONAL: Knowledge Base Sync
# ============================================
# Local Obsidian vault path for syncing OpenClaw knowledge base
# Used by: make pull-knowledge
export KNOWLEDGE_VAULT_PATH="$HOME/Documents/openclaw-knowledge"

# ============================================
# REQUIRED: GitHub Container Registry
# ============================================
# For pulling private Docker images during bootstrap and deploy
# Create a PAT at: https://github.com/settings/tokens with read:packages scope
export GHCR_USERNAME="your-github-username"
export GHCR_TOKEN="CHANGE_ME_your-github-pat-with-read-packages-scope"

# ============================================
# OPTIONAL: Claude Setup Token (for Claude Max/Pro subscription)
# ============================================
# Use your Claude subscription instead of paying for API credits.
# Generate with: claude setup-token
# Then run: make setup-auth
export CLAUDE_SETUP_TOKEN=""

# ============================================
# Server Configuration (Optional Overrides)
# ============================================
# export TF_VAR_server_type="cx22"
# export TF_VAR_server_location="nbg1"
