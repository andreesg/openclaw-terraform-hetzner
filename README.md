# OpenClaw Terraform Hetzner

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Terraform](https://img.shields.io/badge/Terraform-1.5+-purple.svg)](https://www.terraform.io/)

Terraform modules for deploying [OpenClaw](https://github.com/openclaw/openclaw) on Hetzner Cloud. Includes VPS provisioning, firewall configuration, cloud-init automation, and deployment tooling.

## Overview

This repository provides infrastructure-as-code for deploying OpenClaw—an open-source AI coding assistant—on a Hetzner Cloud VPS. The setup includes:

- Modular Terraform structure with remote S3 state backend
- Automated server provisioning via cloud-init
- Firewall configuration (UFW + Hetzner Cloud Firewall)
- Deployment scripts for application lifecycle management
- Backup and restore functionality
- SSH tunneling for secure gateway access

For information about OpenClaw itself, see the [OpenClaw documentation](https://docs.openclaw.ai/).

## Prerequisites

1. **Terraform** >= 1.5 ([Installation Guide](https://developer.hashicorp.com/terraform/install))
2. **Hetzner Cloud Account** with API token ([Console](https://console.hetzner.cloud/))
3. **Hetzner Object Storage** for Terraform state (optional but recommended)
4. **SSH Key** at `~/.ssh/id_rsa.pub`
5. **Docker configuration repo**: [openclaw-docker-config](https://github.com/andreesg/openclaw-docker-config)

## Quick Start

### 1. Clone Repository

```bash
git clone https://github.com/andreesg/openclaw-terraform-hetzner.git
cd openclaw-terraform-hetzner
```

### 2. Configure Secrets

```bash
cp config/inputs.example.sh config/inputs.sh
vim config/inputs.sh  # Add your Hetzner API token and configuration
```

Required variables in `config/inputs.sh`:
- `HCLOUD_TOKEN` - Hetzner Cloud API token
- `TF_VAR_ssh_key_fingerprint` - SSH key fingerprint from Hetzner
- `CONFIG_DIR` - Path to your openclaw-docker-config repository

### 3. Deploy Infrastructure

```bash
source config/inputs.sh
make init
make plan
make apply
```

### 4. Bootstrap OpenClaw

```bash
make bootstrap
make deploy
```

### 5. Verify Deployment

```bash
make status
make logs
```

Access the gateway via SSH tunnel:
```bash
make tunnel  # Opens tunnel on localhost:18789
```

## Architecture

```
┌─────────────────┐
│   Your Laptop   │
│                 │
│  ┌───────────┐  │         ┌─────────────────────┐
│  │ Terraform │──┼────────>│  Hetzner Cloud VPS  │
│  └───────────┘  │         │                     │
│                 │         │  ┌──────────────┐   │
│  ┌───────────┐  │         │  │ Docker       │   │
│  │  Config   │──┼────────>│  │ OpenClaw     │   │
│  │   Repo    │  │         │  └──────────────┘   │
│  └───────────┘  │         │                     │
└─────────────────┘         │  Firewall: SSH only │
                            └─────────────────────┘
                                      │
                                      v
                            ┌─────────────────────┐
                            │ Hetzner Object      │
                            │ Storage (state)     │
                            └─────────────────────┘
```

### Components

| Component | Purpose | Location |
|-----------|---------|----------|
| **infra/terraform/** | Infrastructure definitions | This repo |
| **deploy/** | Deployment automation | This repo |
| **docker/** | Container configuration | [openclaw-docker-config](https://github.com/andreesg/openclaw-docker-config) |
| **config/** | OpenClaw configuration | [openclaw-docker-config](https://github.com/andreesg/openclaw-docker-config) |

## Usage

### Makefile Targets

**Infrastructure:**
```bash
make init       # Initialize Terraform
make plan       # Show infrastructure changes
make apply      # Apply infrastructure changes
make destroy    # Destroy all infrastructure
make output     # Show Terraform outputs
```

**Deployment:**
```bash
make bootstrap  # Initial OpenClaw setup
make deploy     # Pull latest image and restart
make status     # Check deployment status
make logs       # Stream container logs
```

**Operations:**
```bash
make ssh        # SSH to VPS as openclaw user
make tunnel     # Create SSH tunnel to gateway
make backup-now # Trigger backup immediately
make restore    # Restore from backup (BACKUP=filename)
```

**Configuration:**
```bash
make push-env    # Push environment variables
make push-config # Push OpenClaw configuration
make setup-auth  # Configure Claude subscription auth
```

## Configuration

### Server Sizing

Default: CX23 (2 vCPU, 4GB RAM)

To change server type, add to `config/inputs.sh`:
```bash
export TF_VAR_server_type="cx32"  # 4 vCPU, 8GB RAM
```

See [Hetzner server types](https://www.hetzner.com/cloud#pricing).

### Firewall Rules

Default: SSH only from `0.0.0.0/0`

To restrict SSH access:
```bash
# In config/inputs.sh
export TF_VAR_ssh_allowed_cidrs='["203.0.113.50/32"]'
```

Then apply:
```bash
source config/inputs.sh && make plan && make apply
```

### Remote State Backend

The S3 backend configuration is commented out by default in `infra/terraform/envs/prod/main.tf`. To enable:

1. Create Hetzner Object Storage bucket
2. Set credentials in `config/inputs.sh`:
   ```bash
   export AWS_ACCESS_KEY_ID="your-access-key"
   export AWS_SECRET_ACCESS_KEY="your-secret-key"
   ```
3. Uncomment backend block in `main.tf` and update endpoint URL
4. Run `terraform init -migrate-state`

### Switching AI Providers

OpenClaw supports multiple AI providers. This setup defaults to Anthropic Claude, but you can switch to other providers by modifying the configuration in [openclaw-docker-config](https://github.com/andreesg/openclaw-docker-config).

**Supported providers:**
- Anthropic Claude (Opus, Sonnet, Haiku)
- OpenAI (GPT-4, GPT-3.5, o1)
- DeepSeek (V3, R1)
- Local models (via Ollama or LM Studio)

**To switch providers:**

1. Update `openclaw.json` in the config repo:
   ```json
   {
     "agents": {
       "defaults": {
         "model": {
           "primary": "openai/gpt-4"
         }
       }
     },
     "auth": {
       "profiles": {
         "openai:main": {
           "provider": "openai",
           "mode": "token"
         }
       }
     }
   }
   ```

2. Update `secrets/openclaw.env`:
   ```bash
   OPENAI_API_KEY=sk-...
   ```

3. Redeploy:
   ```bash
   make push-config deploy
   ```

See [OpenClaw provider documentation](https://docs.openclaw.ai/providers) for detailed configuration.

## Common Workflows

### Initial Deployment

```bash
# 1. Configure secrets
cp config/inputs.example.sh config/inputs.sh
vim config/inputs.sh

# 2. Deploy infrastructure
source config/inputs.sh
make init plan apply

# 3. Bootstrap application
make bootstrap

# 4. Deploy OpenClaw
make deploy

# 5. Verify
make status logs
```

### Updating OpenClaw

```bash
# Pull latest image and restart
make deploy

# Check logs
make logs
```

### Updating Configuration

```bash
# Edit openclaw.json in config repo
vim ~/path/to/openclaw-docker-config/config/openclaw.json

# Push and restart
make push-config deploy
```

### Backup and Restore

Backups run daily at 02:00 UTC via systemd timer.

```bash
# Manual backup
make backup-now

# List backups
make ssh
ls -lh ~/backups/

# Restore from backup
make restore BACKUP=openclaw-backup-2026-02-08.tar.gz
```

### Accessing the Gateway

OpenClaw gateway runs on `127.0.0.1:18789` (localhost only) for security.

**Access via SSH tunnel:**
```bash
make tunnel  # Creates tunnel: localhost:18789 -> VPS:18789
```

Then open `http://localhost:18789` in your browser. The gateway will ask for your **Gateway Token** — paste your `OPENCLAW_GATEWAY_TOKEN` value (from `secrets/openclaw.env`) into the settings field to authenticate.

## Troubleshooting

### Terraform Init Fails

**Cause:** S3 backend credentials not set

**Solution:**
```bash
source config/inputs.sh
make init
```

Or use local state by commenting out the backend block in `infra/terraform/envs/prod/main.tf`.

### Container Won't Start

**Check logs:**
```bash
make logs
make ssh
docker compose -f ~/openclaw/docker-compose.yml ps
```

**Common causes:**
- Missing environment variables in `.env`
- Invalid OpenClaw configuration
- API key issues

**Fix:**
```bash
make push-env    # Re-push environment variables
make push-config # Re-push OpenClaw config
make deploy      # Restart
```

### Can't SSH to VPS

**Check firewall rules:**
```bash
# Verify your IP is allowed
grep TF_VAR_ssh_allowed_cidrs config/inputs.sh

# Check actual firewall
make ssh-root
ufw status
```

### Permission Denied on ~/.openclaw

If you see `Permission denied` when creating directories under `~/.openclaw` (e.g. during `make setup-auth`), Docker likely took ownership of the directory via the volume mount. This can happen if you ran `make deploy` before bootstrap finished, or if you're re-running bootstrap after a previous deploy.

**Fix:**
```bash
ssh openclaw@VPS_IP "sudo chown -R openclaw:openclaw ~/.openclaw"
```

Then re-run `make bootstrap` or `make setup-auth`.

### Bootstrap Fails

**Verify prerequisites:**
```bash
# Check CONFIG_DIR is set and exists
echo $CONFIG_DIR
ls $CONFIG_DIR/docker/docker-compose.yml

# Verify GHCR credentials
docker login ghcr.io -u YOUR_GITHUB_USERNAME
```

### API Billing Error

**Anthropic API key issues:**

If using API key (not subscription):
```bash
# Check key is set
make ssh
grep ANTHROPIC_API_KEY ~/openclaw/.env

# Verify key has credits at console.anthropic.com
```

If using Claude subscription:
```bash
# Re-run setup-auth
make setup-auth

# Verify auth profile exists
make ssh
cat ~/.openclaw/agents/main/agent/auth-profiles.json
```

## Security Considerations

### SSH Access

- Default allows SSH from anywhere (`0.0.0.0/0`)
- **Recommended:** Restrict to your IP in `config/inputs.sh`
- Use SSH keys, not passwords
- Rotate keys regularly

### Secrets Management

- Never commit `config/inputs.sh` or `secrets/openclaw.env`
- Use environment variables for all credentials
- Rotate API tokens periodically
- Review `.gitignore` before committing

### Firewall

- Default configuration: SSH only
- Gateway binds to `127.0.0.1` (localhost)
- Access via SSH tunnel, not direct exposure
- Review `infra/terraform/modules/hetzner-vps/main.tf` for firewall rules

### API Keys

- Monitor API usage and costs
- Set spending limits at provider dashboards
- Prefer subscription auth over API keys when available
- Never expose keys in logs or errors

### Updates

- Keep Terraform providers updated
- Update OpenClaw regularly for security patches
- Monitor security advisories for dependencies
- Review cloud-init script before changes

## Project Structure

```
.
├── infra/
│   ├── terraform/
│   │   ├── globals/          # Shared configuration
│   │   ├── envs/prod/        # Production environment
│   │   └── modules/          # Reusable modules
│   │       └── hetzner-vps/  # VPS module
│   └── cloud-init/
│       └── user-data.yml.tpl # Server initialization
├── deploy/                   # Deployment scripts
│   ├── bootstrap.sh          # Initial setup
│   ├── deploy.sh             # Deploy/update
│   ├── backup.sh             # Backup script
│   └── restore.sh            # Restore script
├── scripts/                  # Utility scripts
│   ├── push-env.sh           # Push secrets to VPS
│   ├── push-config.sh        # Push config to VPS
│   └── setup-auth.sh         # Setup subscription auth
├── config/
│   └── inputs.example.sh     # Configuration template
└── secrets/
    └── openclaw.env.example  # Secrets template
```

## Infrastructure Costs

See [Hetzner Cloud pricing](https://www.hetzner.com/cloud#pricing) for current rates. This setup uses a small shared VPS (default: CX23) plus minimal object storage for Terraform state.

> **Note:** Prices exclude Anthropic/OpenAI API costs.

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

**Ways to contribute:**
- Report bugs via [GitHub Issues](https://github.com/andreesg/openclaw-terraform-hetzner/issues)
- Submit feature requests
- Improve documentation
- Submit pull requests
- Share your deployment experiences

## Related Projects

- **[OpenClaw](https://github.com/openclaw/openclaw)** — The AI coding assistant this infrastructure deploys
- **[openclaw-docker-config](https://github.com/andreesg/openclaw-docker-config)** — Docker and OpenClaw configuration (companion repo)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- **Issues:** [GitHub Issues](https://github.com/andreesg/openclaw-terraform-hetzner/issues)
- **Discussions:** [GitHub Discussions](https://github.com/andreesg/openclaw-terraform-hetzner/discussions)
- **OpenClaw Docs:** [docs.openclaw.ai](https://docs.openclaw.ai/)
