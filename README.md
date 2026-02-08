# OpenClaw VPS - Hetzner Cloud Terraform

Terraform configuration for deploying an OpenClaw VPS on Hetzner Cloud.

## Infrastructure Overview

- **Server**: Hetzner Cloud CX22 (2 vCPU, 4GB RAM)
- **OS**: Ubuntu 24.04 LTS
- **Location**: Configurable (default: Nuremberg, Germany)
- **Firewall**: SSH-only inbound (configurable source IP restriction)
- **State**: Remote S3 backend on Hetzner Object Storage
- **App**: Runs as a Docker container pulled from GHCR (no build on VPS)

### Pre-installed Software

The cloud-init configuration automatically installs:

- Docker & Docker Compose plugin
- Git, curl, jq
- UFW firewall (configured for SSH only)

### User Setup

- Creates `openclaw` user with sudo and Docker group access
- SSH keys are copied from root
- Application directories created at `/home/openclaw/.openclaw/`

## Prerequisites

1. **Terraform** >= 1.5 installed ([Installation Guide](https://developer.hashicorp.com/terraform/install))
2. **Hetzner Cloud Account** with API token ([Get Token](https://console.hetzner.cloud/))
3. **Hetzner Object Storage** bucket for Terraform state
4. **SSH Key Pair** at `~/.ssh/id_rsa.pub`

## Setup

### 1. Configure Secrets

```bash
# Copy example config and edit with your values
cp config/inputs.example.sh config/inputs.sh
vim config/inputs.sh
```

The `config/inputs.sh` file contains:
- `HCLOUD_TOKEN` - Your Hetzner Cloud API token
- `TF_VAR_hcloud_token` - Same token for Terraform variable
- `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` - S3 credentials for state backend
- `TF_VAR_ssh_allowed_cidrs` - List of IP addresses for SSH access
- `TF_VAR_ssh_public_key_path` - Path to your SSH public key
- `CONFIG_DIR` - Local path to your openclaw-config repository

> **Security**: Never commit `config/inputs.sh`. It's already in `.gitignore`.

### 2. Source Configuration

```bash
# Load environment variables
source config/inputs.sh
```

### 3. Initialize and Deploy

```bash
# Initialize Terraform (connects to S3 backend)
make init

# Preview changes
make plan

# Deploy infrastructure
make apply
```

### 4. Connect to Server

```bash
# SSH as openclaw user
make ssh
```

## Usage

### Available Make Targets

#### Terraform

| Target | Description |
|--------|-------------|
| `make init` | Initialize Terraform backend |
| `make plan` | Preview infrastructure changes |
| `make apply` | Deploy/update infrastructure |
| `make destroy` | Tear down all infrastructure |
| `make ssh` | SSH as openclaw user |
| `make ssh-root` | SSH as root user |
| `make output` | Show all Terraform outputs |
| `make ip` | Show server IP address |
| `make fmt` | Format Terraform files |
| `make validate` | Validate configuration and scripts |

#### Deploy & Operations

| Target | Description |
|--------|-------------|
| `make bootstrap` | Initial OpenClaw setup on VPS (run once after apply) |
| `make deploy` | Pull latest image and restart container |
| `make push-env` | Push secrets/openclaw.env to the VPS |
| `make push-config` | Push config files from CONFIG_DIR to VPS |
| `make backup-now` | Run backup immediately on VPS |
| `make restore BACKUP=<file>` | Restore from a backup archive |
| `make logs` | Stream Docker container logs |
| `make status` | Check OpenClaw status and health |
| `make help` | Show help message |

### Outputs

After deployment, view outputs with:

```bash
make output
make ip
```

## Deployment Model

This repo works together with a **config repo** (e.g., `ag-openclaw_config`) that contains:
- `docker/docker-compose.yml` — service definition
- `docker/Dockerfile` — image build
- `config/openclaw.json` — runtime configuration
- `scripts/build-and-push.sh` — builds and pushes the Docker image to GHCR

Everything is pushed from your laptop to the VPS — nothing is built or cloned on the server.

**What lives where on the VPS:**

| Path | Contents | Pushed by |
|------|----------|-----------|
| `~/openclaw/docker-compose.yml` | Service definition | `make bootstrap` |
| `~/openclaw/.env` | Secrets (API keys, tokens) | `make push-env` |
| `~/.openclaw/openclaw.json` | Runtime config | `make push-config` |
| `~/.openclaw/workspace/` | Persistent data (conversations) | Created by app |

## Lifecycle

### First-Time Setup

```bash
# 1. Configure infrastructure secrets
cp config/inputs.example.sh config/inputs.sh
vim config/inputs.sh    # HCLOUD_TOKEN, S3 creds, CONFIG_DIR, GHCR creds

# 2. Configure application secrets
cp secrets/openclaw.env.example secrets/openclaw.env
vim secrets/openclaw.env    # ANTHROPIC_API_KEY, TELEGRAM_BOT_TOKEN, etc.

# 3. Provision VPS
source config/inputs.sh
make init && make plan && make apply

# 4. Bootstrap (wait 2-3 min for cloud-init first)
make bootstrap

# 5. Pull image and start
make deploy

# 6. Check it's running
make status
```

### Day-to-Day Workflows

**Deploy a new Docker image** (app code or Dockerfile changed in config repo):

```bash
# In the config repo: build and push image
cd $CONFIG_DIR && ./scripts/build-and-push.sh

# In this repo: pull new image and restart
make deploy
```

**Change runtime config** (openclaw.json, security-rules, etc.):

```bash
# Edit files in the config repo, then push to VPS
make push-config
```

**Change secrets** (API keys, tokens):

```bash
vim secrets/openclaw.env
make push-env
```

**Change docker-compose.yml** (ports, volumes, image tag):

```bash
# Edit in config repo, then re-run bootstrap to SCP it
make bootstrap
make deploy
```

**Change infrastructure** (server type, firewall CIDRs):

```bash
source config/inputs.sh
make plan && make apply
```

### Monitoring

```bash
make status       # Health check + system info
make logs         # Stream live Docker logs
```

### Backup & Restore

Backups run automatically daily at 3 AM. For manual operations:

```bash
make backup-now
make restore BACKUP=openclaw_backup_20240115_030000.tar.gz
```

### Destroy & Recreate

```bash
make destroy
make init && make apply
make bootstrap && make deploy
```

## Customization

### Restrict SSH Access

For better security, restrict SSH access to your IPs in `config/inputs.sh`:

```bash
export TF_VAR_ssh_allowed_cidrs='["203.0.113.50/32", "198.51.100.25/32"]'
```

### Change Server Size

```bash
export TF_VAR_server_type="cx32"  # 4 vCPU, 8GB RAM
```

### Change Location

```bash
export TF_VAR_server_location="fsn1"  # Falkenstein, Germany
```

Available locations:
- `nbg1` - Nuremberg, Germany
- `fsn1` - Falkenstein, Germany
- `hel1` - Helsinki, Finland
- `ash` - Ashburn, USA
- `hil` - Hillsboro, USA

## Terraform Remote State

State is stored remotely in Hetzner Object Storage (S3-compatible):

- **Bucket**: `openclaw-tfstate`
- **Key**: `prod/terraform.tfstate`
- **Endpoint**: Configured in `infra/terraform/envs/prod/main.tf`

Credentials are set via `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables (sourced from `config/inputs.sh`).

## Troubleshooting

### Cloud-init Not Complete

After deployment, cloud-init may still be running. Check status:

```bash
make ssh-root
cloud-init status
```

### SSH Connection Refused

1. Wait for cloud-init to complete
2. Verify your IP is allowed in the firewall
3. Check SSH key path in `config/inputs.sh`

### Docker Permission Denied

Log out and back in for group membership to take effect:

```bash
exit
make ssh
```

## Security Notes

- SSH keys are the only authentication method (password disabled)
- UFW firewall allows only SSH by default
- Hetzner firewall provides additional network-level protection
- OpenClaw gateway binds to loopback only (127.0.0.1:18789) — access via SSH tunnel
- Consider restricting `ssh_allowed_cidrs` to your IP addresses

## Files

```
.
├── infra/
│   ├── terraform/
│   │   ├── globals/
│   │   │   ├── backend.tf          # S3 backend documentation
│   │   │   └── versions.tf         # Shared provider versions
│   │   ├── envs/prod/
│   │   │   ├── main.tf             # Backend, provider, module call, outputs
│   │   │   └── variables.tf        # Environment variables
│   │   └── modules/hetzner-vps/
│   │       ├── main.tf             # SSH key, firewall, server resources
│   │       ├── variables.tf        # Module input variables
│   │       └── outputs.tf          # Server IP, SSH, firewall outputs
│   └── cloud-init/
│       └── user-data.yml.tpl       # Cloud-init configuration template
├── deploy/
│   ├── bootstrap.sh                # Initial VPS setup (run once after apply)
│   ├── deploy.sh                   # Pull latest image and restart
│   ├── backup.sh                   # Backup script (runs on VPS)
│   ├── restore.sh                  # Restore from backup
│   ├── logs.sh                     # Stream Docker logs
│   └── status.sh                   # Check status and health
├── config/
│   ├── inputs.sh                   # Your secrets (git-ignored)
│   └── inputs.example.sh           # Example config template
├── scripts/
│   ├── push-env.sh                 # Push secrets to VPS
│   └── push-config.sh              # Push config files to VPS
├── secrets/
│   ├── openclaw.env                # Application secrets (git-ignored)
│   └── openclaw.env.example        # Example secrets template
├── Makefile                        # Automation targets
├── README.md                       # This file
└── CLAUDE.md                       # AI assistant context
```

## License

MIT
