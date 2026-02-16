# Tailscale VPN Integration Guide

This guide explains how to deploy OpenClaw with Tailscale VPN for secure, private networking.

## Table of Contents

- [Overview](#overview)
- [Why Tailscale?](#why-tailscale)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration Options](#configuration-options)
- [OpenClaw Gateway Integration](#openclaw-gateway-integration)
- [SSH Access via Tailscale](#ssh-access-via-tailscale)
- [Troubleshooting](#troubleshooting)
- [Advanced Configuration](#advanced-configuration)

## Overview

Tailscale creates a secure, encrypted mesh VPN network between your devices and your OpenClaw VPS. When enabled, you can:

- **Access SSH privately**: Connect to your VPS without exposing SSH to the public internet
- **Secure gateway access**: Access the OpenClaw gateway UI via Tailscale instead of a public IP
- **Zero-trust networking**: All traffic is encrypted end-to-end using WireGuard
- **Easy setup**: No complex firewall rules or port forwarding needed

## Why Tailscale?

### Security Benefits

1. **Reduced attack surface**: SSH and gateway ports are not publicly exposed
2. **End-to-end encryption**: All traffic uses WireGuard encryption
3. **Zero-trust model**: Only authenticated devices on your Tailnet can connect
4. **No VPN server management**: Tailscale handles NAT traversal and routing

### Operational Benefits

1. **Stable connections**: Works across network changes (WiFi → mobile, VPN changes, etc.)
2. **Direct connections**: Peer-to-peer when possible, relayed when needed
3. **Multi-platform**: Works on macOS, Linux, Windows, iOS, Android
4. **Free for personal use**: Up to 100 devices on the free tier

## Prerequisites

1. **Tailscale account**: Sign up at [https://tailscale.com](https://tailscale.com) (free for personal use)
2. **Tailscale client**: Install on your laptop/desktop where you'll access OpenClaw
   - macOS: `brew install tailscale`
   - Linux: See [Tailscale Linux install guide](https://tailscale.com/download/linux)
   - Windows: Download from [tailscale.com/download](https://tailscale.com/download)
3. **Tailscale auth key** (optional for auto-setup): Generate at [login.tailscale.com/admin/settings/keys](https://login.tailscale.com/admin/settings/keys)

## Quick Start

### Step 1: Generate Tailscale Auth Key (Optional)

For automatic setup during deployment, generate an auth key:

1. Visit [https://login.tailscale.com/admin/settings/keys](https://login.tailscale.com/admin/settings/keys)
2. Click **Generate auth key**
3. Settings:
   - **Reusable**: ✅ Recommended (allows re-deployment without new keys)
   - **Ephemeral**: ❌ Not recommended (device disappears on shutdown)
   - **Pre-authorized**: ✅ Recommended (auto-approves the device)
   - **Expiration**: 90 days or longer
4. Copy the key (starts with `tskey-auth-`)

**Alternative**: Skip the auth key and authenticate manually after deployment (see Step 4).

### Step 2: Configure Terraform Variables

Edit `config/inputs.sh`:

```bash
# Enable Tailscale
export TF_VAR_enable_tailscale=true

# Provide auth key for automatic setup (or leave empty for manual setup)
export TF_VAR_tailscale_auth_key="tskey-auth-xxxxxxxxxxxxx"

# Optional: Use custom SSH port (recommended with Tailscale)
export TF_VAR_ssh_port=8822
```

Source the configuration:

```bash
source config/inputs.sh
```

### Step 3: Deploy

For **new deployments**:

```bash
make init
make plan
make apply
```

For **existing deployments** (adding Tailscale):

```bash
make plan   # Verify changes
make apply  # Apply Tailscale configuration
```

Wait 2-3 minutes for cloud-init to complete Tailscale installation.

### Step 4: Verify Tailscale Status

Check if Tailscale is running:

```bash
make tailscale-status
```

**If you provided an auth key**, you should see:

```
openclaw-prod     openclaw@    linux   -
```

**If you did NOT provide an auth key**, authenticate manually:

```bash
make tailscale-up
```

Follow the URL provided to authenticate in your browser.

### Step 5: Get Tailscale IP

```bash
make tailscale-ip
```

Example output: `100.64.1.5`

### Step 6: Connect via Tailscale

**SSH via Tailscale**:

```bash
ssh -p 8822 openclaw@100.64.1.5  # Use your Tailscale IP
```

**SSH tunnel to gateway**:

```bash
ssh -p 8822 -N -L 18789:127.0.0.1:18789 openclaw@100.64.1.5
```

Then open `http://localhost:18789` in your browser.

## Configuration Options

### Minimal Configuration (Manual Auth)

Enable Tailscale but authenticate manually after deployment:

```bash
export TF_VAR_enable_tailscale=true
export TF_VAR_tailscale_auth_key=""  # Empty = manual auth
```

After `make apply`, run `make tailscale-up` and authenticate via browser.

### Recommended Configuration (Auto Auth + Custom SSH Port)

Enable Tailscale with automatic authentication and custom SSH port:

```bash
export TF_VAR_enable_tailscale=true
export TF_VAR_tailscale_auth_key="tskey-auth-xxxxxxxxxxxxx"
export TF_VAR_ssh_port=8822
```

This is the **recommended production setup** for maximum security.

### Hybrid Configuration (Tailscale + Public SSH)

Keep SSH accessible on both public IP and Tailscale:

```bash
export TF_VAR_enable_tailscale=true
export TF_VAR_tailscale_auth_key="tskey-auth-xxxxxxxxxxxxx"
export TF_VAR_ssh_port=22  # Keep default SSH port
```

Useful during migration or for backup access.

## OpenClaw Gateway Integration

OpenClaw has native Tailscale support via the `gateway.tailscale` configuration.

### Tailscale Serve Mode

To expose the OpenClaw gateway **only** on your Tailnet (not on the public internet), configure OpenClaw to use Tailscale Serve:

**Example `~/.openclaw/config.json`**:

```json
{
  "version": 1,
  "agent": "main",
  "gateway": {
    "host": "0.0.0.0",
    "port": 18789,
    "tailscale": {
      "mode": "serve",
      "protocol": "https",
      "port": 443
    },
    "auth": {
      "token": "your-gateway-token",
      "allowTailscale": true
    }
  }
}
```

**What this does**:
- Gateway listens on `0.0.0.0:18789` for local access
- Tailscale Serve exposes it at `https://openclaw-prod.tailnet-name.ts.net`
- Only accessible from devices in your Tailnet
- Automatic HTTPS with Tailscale certificates

**Access the gateway**:

```bash
# Find your Tailscale HTTPS URL
ssh -p 8822 openclaw@$(make tailscale-ip) 'sudo tailscale serve status'

# Output example:
# https://openclaw-prod.tailnet-name.ts.net (tailnet only)
#     /   proxy http://127.0.0.1:18789
```

Open `https://openclaw-prod.tailnet-name.ts.net` in your browser.

### Tailscale Funnel Mode (Public HTTPS)

To expose the gateway **publicly** via Tailscale Funnel (with HTTPS):

```json
{
  "gateway": {
    "tailscale": {
      "mode": "funnel",
      "protocol": "https",
      "port": 443
    }
  }
}
```

**Note**: Funnel requires Tailscale admin approval. See [Tailscale Funnel docs](https://tailscale.com/kb/1223/tailscale-funnel/).

### Local-Only Mode (No Tailscale Serve)

If you prefer SSH tunneling over Tailscale Serve:

```json
{
  "gateway": {
    "host": "127.0.0.1",
    "port": 18789
  }
}
```

Then tunnel via Tailscale:

```bash
ssh -p 8822 -N -L 18789:127.0.0.1:18789 openclaw@$(make tailscale-ip)
```

## SSH Access via Tailscale

### Update SSH Config (Recommended)

Add to `~/.ssh/config`:

```ssh
Host openclaw
    HostName 100.64.1.5  # Your Tailscale IP
    User openclaw
    Port 8822
    IdentityFile ~/.ssh/id_rsa  # Or your custom SSH key
    StrictHostKeyChecking accept-new
```

Then connect with:

```bash
ssh openclaw
```

### Direct Connection

```bash
# Get Tailscale IP
TAILSCALE_IP=$(make tailscale-ip)

# SSH
ssh -p 8822 openclaw@$TAILSCALE_IP
```

### Makefile Commands

The Makefile automatically uses the configured SSH port:

```bash
make ssh           # SSH via public IP (uses dynamic port)
make tunnel        # Tunnel via public IP
make tailscale-ip  # Get Tailscale IP for manual connection
```

## Troubleshooting

### Tailscale Not Running

**Check status**:

```bash
make tailscale-status
```

**If service is down**:

```bash
make ssh  # Connect via public IP
sudo systemctl status tailscaled
sudo systemctl restart tailscaled
```

### Authentication Failed

**Manual authentication**:

```bash
make tailscale-up
```

Follow the URL to authenticate.

### Cannot Connect via Tailscale IP

**Verify Tailscale is connected on your laptop**:

```bash
tailscale status
```

You should see `openclaw-prod` in the list.

**Check VPS Tailscale IP**:

```bash
make tailscale-ip
```

**Test connectivity**:

```bash
ping $(make tailscale-ip)
```

### UFW Blocking Tailscale

Tailscale UDP port (41641) should be allowed. Verify:

```bash
make ssh
sudo ufw status numbered
```

You should see:

```
[ X] 41641/udp     ALLOW IN    Anywhere   # Tailscale
```

If missing, add manually:

```bash
sudo ufw allow 41641/udp comment 'Tailscale'
```

### Tailscale Serve Not Working

**Check Tailscale Serve status**:

```bash
ssh -p 8822 openclaw@$(make tailscale-ip) 'sudo tailscale serve status'
```

**Restart Tailscale Serve** (if OpenClaw config changed):

```bash
# OpenClaw automatically manages Tailscale Serve
# Just restart the container:
make deploy
```

## Advanced Configuration

### Custom Tailscale Hostname

By default, the VPS is named `openclaw-prod`. To customize:

Edit `infra/cloud-init/user-data.yml.tpl`:

```yaml
- tailscale up --auth-key="${tailscale_auth_key}" --hostname="my-custom-name" --accept-routes
```

Then `make plan && make apply`.

### Disable Public SSH (Tailscale-Only Access)

**WARNING**: Only do this if you're confident Tailscale is working.

After verifying Tailscale connectivity:

1. Edit `config/inputs.sh`:

```bash
export TF_VAR_ssh_allowed_cidrs='[]'  # Empty list = no public SSH
```

2. Apply changes:

```bash
make plan
make apply
```

3. Verify you can still SSH via Tailscale:

```bash
ssh -p 8822 openclaw@$(make tailscale-ip)
```

### Tailscale Exit Node

To route all VPS traffic through your laptop (for debugging):

**On VPS**:

```bash
sudo tailscale up --accept-routes
```

**On laptop**:

```bash
sudo tailscale up --advertise-exit-node
```

**On VPS** (use laptop as exit node):

```bash
sudo tailscale set --exit-node=<laptop-hostname>
```

### Tailscale ACLs

Control which devices can access the VPS:

1. Visit [https://login.tailscale.com/admin/acls](https://login.tailscale.com/admin/acls)
2. Add ACL rules:

```json
{
  "acls": [
    {
      "action": "accept",
      "src": ["autogroup:members"],
      "dst": ["openclaw-prod:*"]
    }
  ]
}
```

## Security Best Practices

1. **Use reusable, pre-authorized auth keys** for easier re-deployment
2. **Set auth key expiration** to 90 days and rotate regularly
3. **Enable Tailscale MFA** for your account
4. **Use custom SSH port (8822)** to reduce public exposure
5. **Monitor Tailscale access** via the admin console
6. **Keep Tailscale updated** on all devices

## Additional Resources

- [Tailscale Documentation](https://tailscale.com/kb/)
- [Tailscale Serve Guide](https://tailscale.com/kb/1242/tailscale-serve/)
- [Tailscale Funnel Guide](https://tailscale.com/kb/1223/tailscale-funnel/)
- [OpenClaw Gateway Configuration](https://docs.openclaw.ai/gateway/configuration)

## Getting Help

- **Tailscale issues**: [Tailscale Community Forum](https://forum.tailscale.com/)
- **OpenClaw issues**: [OpenClaw GitHub Issues](https://github.com/anthropics/openclaw-terraform-hetzner/issues)
