# OpenClaw Infrastructure on Hetzner Cloud

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.5-623CE4?logo=terraform)](https://www.terraform.io/)
[![Hetzner Cloud](https://img.shields.io/badge/Hetzner-Cloud-D50C2D?logo=hetzner)](https://www.hetzner.com/cloud)

> Production-ready Terraform infrastructure for deploying OpenClaw on Hetzner Cloud — secure, affordable, and fully automated.

**Deploy your own AI-powered coding assistant in 5 minutes for ~€6/month.**

---

## 🎯 What is This?

This repository provides **infrastructure-as-code** to deploy [OpenClaw](https://github.com/openclaw) on a Hetzner Cloud VPS. It handles everything from server provisioning to firewall configuration, letting you run your own private AI coding assistant with full control over your data.

### What is OpenClaw?

**OpenClaw** is an open-source AI coding assistant powered by Anthropic's Claude. Think of it as having an expert pair programmer who can:

- 🔍 Search and analyze your entire codebase
- ✏️ Write, refactor, and debug code across multiple files
- 🤖 Execute commands and manage your development workflow
- 💬 Provide context-aware suggestions and explanations
- 🔒 Run entirely on your own infrastructure (privacy-first)

Unlike cloud-based assistants, OpenClaw runs on your own server, giving you complete control over your code, API usage, and costs.

---

## 🚀 Why Use This?

### Why Hetzner Cloud?

| Feature | Hetzner Cloud | AWS | DigitalOcean |
|---------|---------------|-----|--------------|
| **2 vCPU, 4GB RAM** | €5.83/mo | ~$30/mo | ~$24/mo |
| **Data transfer** | 20 TB included | Pay per GB | 4 TB included |
| **Price/performance** | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐ |
| **European datacenter** | ✅ (GDPR-friendly) | Optional | Optional |
| **Hourly billing** | ✅ | ✅ | ✅ |

**Cost Breakdown (Monthly):**
- VPS (CX22): €5.83
- Object Storage (state): €0.10
- Backups (optional): €1.17
- **Total: ~€6-7/month** (~$6.50-7.50 USD)

### Why This Terraform Setup?

✅ **Production-Ready**: Remote state, modular structure, automated backups
✅ **Secure by Default**: Firewall, SSH keys only, IP restrictions
✅ **Zero-Config VPS**: Cloud-init handles all software installation
✅ **Simple Deployment**: Single `make` command to deploy updates
✅ **Repeatable**: Destroy and recreate infrastructure in minutes
✅ **Well-Documented**: Clear examples, troubleshooting, and lifecycle guides

---

## ⚡ Quick Start (5 Minutes)

### Prerequisites

1. **Hetzner Cloud Account** → [Sign up](https://console.hetzner.cloud/) (€20 free credit)
2. **Terraform** ≥ 1.5 → [Install](https://developer.hashicorp.com/terraform/install)
3. **SSH Key** → Already have `~/.ssh/id_rsa.pub`? You're good!

### Step 1: Get Your API Tokens

1. **Hetzner Cloud API Token**: [Generate here](https://console.hetzner.cloud/) (Read & Write)
2. **Hetzner Object Storage Credentials**: Create a bucket `openclaw-tfstate` and generate S3 credentials

### Step 2: Configure Secrets

```bash
# Clone this repo
git clone https://github.com/yourusername/openclaw-terraform-hetzner.git
cd openclaw-terraform-hetzner

# Copy and edit configuration
cp config/inputs.example.sh config/inputs.sh
vim config/inputs.sh  # Add your tokens

# Copy and edit application secrets
cp secrets/openclaw.env.example secrets/openclaw.env
vim secrets/openclaw.env  # Add ANTHROPIC_API_KEY, etc.

# Load environment
source config/inputs.sh
```

### Step 3: Deploy Infrastructure

```bash
# Initialize Terraform
make init

# Preview changes
make plan

# Deploy! (takes ~2 minutes)
make apply
```

### Step 4: Bootstrap & Start OpenClaw

```bash
# Wait 2-3 minutes for cloud-init to complete, then:
make bootstrap  # Sets up Docker, config files, backups
make deploy     # Pulls image and starts container
make status     # Verify it's running
```

🎉 **Done!** Your OpenClaw instance is now running.

### Step 5: Connect to OpenClaw

OpenClaw runs on `127.0.0.1:18789` (loopback only for security). Access it via SSH tunnel:

```bash
# Create SSH tunnel
ssh -L 18789:localhost:18789 openclaw@$(make ip -s)

# Or use the Makefile helper
make ssh  # Tunnel is auto-configured
```

Then visit `http://localhost:18789` in your browser.

---

## 📊 Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    Your Laptop                          │
│  ┌──────────────┐        ┌──────────────┐              │
│  │ This Repo    │        │ Config Repo  │              │
│  │ (Terraform)  │        │ (Docker)     │              │
│  └──────┬───────┘        └──────┬───────┘              │
│         │                       │                       │
│         ├───── make apply ──────┤                       │
│         ├───── make bootstrap ──┤                       │
│         └───── make deploy ─────┘                       │
└─────────────────────────────────────────────────────────┘
                        │
                        │ SSH/SCP
                        ▼
┌─────────────────────────────────────────────────────────┐
│              Hetzner Cloud VPS (CX22)                   │
│  ┌─────────────────────────────────────────────────┐   │
│  │ Ubuntu 24.04 LTS                                │   │
│  │  ┌────────────────────────────────────────┐     │   │
│  │  │ Docker Container: openclaw-gateway     │     │   │
│  │  │  - Binds to 127.0.0.1:18789           │     │   │
│  │  │  - Anthropic Claude API client        │     │   │
│  │  │  - Code analysis & execution          │     │   │
│  │  └────────────────────────────────────────┘     │   │
│  │                                                  │   │
│  │  /home/openclaw/                                │   │
│  │  ├── openclaw/                                  │   │
│  │  │   ├── docker-compose.yml                     │   │
│  │  │   └── .env (secrets)                         │   │
│  │  └── .openclaw/                                 │   │
│  │      ├── openclaw.json (config)                 │   │
│  │      └── workspace/ (persistent data)           │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  Firewall: SSH only (configurable IPs)                 │
└─────────────────────────────────────────────────────────┘
                        │
                        │ Terraform State
                        ▼
┌─────────────────────────────────────────────────────────┐
│        Hetzner Object Storage (S3-compatible)           │
│        Bucket: openclaw-tfstate                         │
└─────────────────────────────────────────────────────────┘
```

### Infrastructure Components

- **Server**: Hetzner Cloud CX22 (2 vCPU, 4GB RAM, 40GB SSD)
- **OS**: Ubuntu 24.04 LTS
- **Firewall**: UFW + Hetzner Cloud Firewall (SSH only, configurable source IPs)
- **Storage**: Hetzner Object Storage for Terraform state
- **Automation**: Cloud-init for zero-touch server setup
- **Backups**: Automated daily backups via systemd timer

---

## 🛠️ Usage

### Available Make Targets

#### Infrastructure Management

| Command | Description |
|---------|-------------|
| `make init` | Initialize Terraform backend |
| `make plan` | Preview infrastructure changes |
| `make apply` | Deploy/update infrastructure |
| `make destroy` | Tear down all infrastructure |
| `make output` | Show all Terraform outputs |
| `make ip` | Show server IP address |
| `make fmt` | Format Terraform files |
| `make validate` | Validate configuration |

#### Application Operations

| Command | Description |
|---------|-------------|
| `make bootstrap` | Initial OpenClaw setup on VPS (run once after apply) |
| `make deploy` | Pull latest Docker image and restart container |
| `make push-env` | Push `secrets/openclaw.env` to VPS |
| `make push-config` | Push config files from CONFIG_DIR to VPS |
| `make logs` | Stream live Docker container logs |
| `make status` | Check OpenClaw status and health |

#### Server Access

| Command | Description |
|---------|-------------|
| `make ssh` | SSH as `openclaw` user (non-root) |
| `make ssh-root` | SSH as `root` user |

#### Backup & Restore

| Command | Description |
|---------|-------------|
| `make backup-now` | Run backup immediately on VPS |
| `make restore BACKUP=<file>` | Restore from a backup archive |

---

## 🔄 Two-Repo Architecture

This infrastructure repo works with a **config repo** that contains the OpenClaw application:

### This Repo (openclaw-terraform-hetzner)
- Terraform infrastructure code
- Deploy scripts
- Secrets management (`config/inputs.sh`, `secrets/openclaw.env`)

### Config Repo ([openclaw-docker-config](https://github.com/yourusername/openclaw-docker-config))
- `docker/Dockerfile` — Image build
- `docker/docker-compose.yml` — Service definition
- `config/openclaw.json` — Runtime configuration
- `scripts/build-and-push.sh` — Build and push to GHCR
- `skills/`, `hooks/` — OpenClaw customizations

**Key Principle**: Everything is pushed from your laptop to the VPS. Nothing is built or cloned on the server.

### VPS Directory Layout

| Path | Contents | Managed By |
|------|----------|------------|
| `~/openclaw/docker-compose.yml` | Service definition | `make bootstrap` |
| `~/openclaw/.env` | Secrets (API keys) | `make push-env` |
| `~/.openclaw/openclaw.json` | Runtime config | `make push-config` |
| `~/.openclaw/workspace/` | Persistent data | OpenClaw app |
| `~/scripts/backup.sh` | Backup script | `make bootstrap` |

---

## 📚 Common Workflows

### First-Time Setup (Detailed)

```bash
# 1. Clone and configure
git clone https://github.com/yourusername/openclaw-terraform-hetzner.git
cd openclaw-terraform-hetzner

# 2. Set up infrastructure secrets
cp config/inputs.example.sh config/inputs.sh
vim config/inputs.sh
# Required:
#   - HCLOUD_TOKEN (Hetzner Cloud API)
#   - AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY (S3 state)
#   - TF_VAR_ssh_public_key_path (your SSH public key)
#   - CONFIG_DIR (path to your openclaw-docker-config repo)

# 3. Set up application secrets
cp secrets/openclaw.env.example secrets/openclaw.env
vim secrets/openclaw.env
# Required:
#   - ANTHROPIC_API_KEY (get from https://console.anthropic.com/)
#   - Optional: TELEGRAM_BOT_TOKEN, BRAVE_API_KEY, etc.

# 4. Load environment and deploy infrastructure
source config/inputs.sh
make init
make plan   # Review what will be created
make apply  # Deploy (confirm with 'yes')

# 5. Wait 2-3 minutes for cloud-init to complete
# You can check status with: make ssh-root && cloud-init status

# 6. Bootstrap OpenClaw
make bootstrap
# This copies docker-compose.yml, sets up backup scripts, creates directories

# 7. Start OpenClaw
make deploy
# This pulls the Docker image and starts the container

# 8. Verify
make status
make logs
```

### Daily Operations

**Deploy a new version** (after updating code in config repo):

```bash
# In config repo: build and push image
cd $CONFIG_DIR
./scripts/build-and-push.sh

# In this repo: pull and restart
make deploy
make logs  # Watch it start up
```

**Update configuration** (openclaw.json, skills, hooks):

```bash
# Edit files in config repo
vim $CONFIG_DIR/config/openclaw.json

# Push to VPS
make push-config

# Restart container to pick up changes
make deploy
```

**Update secrets** (API keys, tokens):

```bash
vim secrets/openclaw.env
make push-env
make deploy  # Restart to load new secrets
```

**Update infrastructure** (server size, firewall rules):

```bash
# Edit variables in config/inputs.sh
vim config/inputs.sh
source config/inputs.sh

# Preview and apply
make plan
make apply
```

### Monitoring

```bash
# Check if OpenClaw is healthy
make status

# Stream live logs
make logs

# SSH in to investigate
make ssh
docker ps
docker logs openclaw-gateway
```

### Backup & Recovery

Backups run automatically daily at 3 AM UTC via systemd timer.

**Manual backup**:
```bash
make backup-now
```

**List backups** (SSH into VPS):
```bash
make ssh
ls -lh ~/.openclaw/backups/
```

**Restore from backup**:
```bash
make restore BACKUP=openclaw_backup_20260208_030000.tar.gz
```

**Download backup to laptop**:
```bash
scp openclaw@$(make ip -s):~/.openclaw/backups/openclaw_backup_*.tar.gz ./
```

---

## 🔧 Customization

### Restrict SSH to Your IP

For better security, limit SSH access to your IP addresses:

```bash
# In config/inputs.sh
export TF_VAR_ssh_allowed_cidrs='["203.0.113.50/32", "198.51.100.25/32"]'
```

Then apply:
```bash
source config/inputs.sh
make plan && make apply
```

### Change Server Size

```bash
# In config/inputs.sh
export TF_VAR_server_type="cx32"  # 4 vCPU, 8GB RAM, €11.66/mo
```

Available types:
- `cx22` — 2 vCPU, 4GB RAM — €5.83/mo (default)
- `cx32` — 4 vCPU, 8GB RAM — €11.66/mo
- `cx42` — 8 vCPU, 16GB RAM — €23.32/mo
- `cx52` — 16 vCPU, 32GB RAM — €46.64/mo

See [all server types](https://www.hetzner.com/cloud#pricing).

### Change Datacenter Location

```bash
# In config/inputs.sh
export TF_VAR_server_location="fsn1"
```

Available locations:
- `nbg1` — Nuremberg, Germany (default)
- `fsn1` — Falkenstein, Germany
- `hel1` — Helsinki, Finland
- `ash` — Ashburn, Virginia, USA
- `hil` — Hillsboro, Oregon, USA

---

## 🐛 Troubleshooting

### "SSH connection refused" or "Permission denied"

**Cause**: Cloud-init may still be running, or your IP isn't allowed.

**Solution**:
```bash
# 1. Wait for cloud-init (can take 2-3 minutes)
make ssh-root
cloud-init status --wait

# 2. Verify your IP is allowed
# Check config/inputs.sh TF_VAR_ssh_allowed_cidrs
# Find your IP: curl ifconfig.me

# 3. Verify SSH key path is correct
ls -la ~/.ssh/id_rsa.pub
```

### "Docker: permission denied"

**Cause**: User needs to log out/in for Docker group membership.

**Solution**:
```bash
make ssh
exit
make ssh  # Log back in
docker ps  # Should work now
```

### "Container not starting" or "Health check failed"

**Cause**: Missing environment variables or config files.

**Solution**:
```bash
# Check logs
make logs

# Common issues:
# 1. Missing ANTHROPIC_API_KEY
vim secrets/openclaw.env
make push-env && make deploy

# 2. Missing openclaw.json
make push-config && make deploy

# 3. SSH into VPS and check manually
make ssh
cd ~/openclaw
docker compose logs
docker compose ps
cat .env  # Verify secrets are present
```

### "Terraform state locked"

**Cause**: Previous operation didn't complete cleanly.

**Solution**:
```bash
# Force unlock (use the Lock ID from error message)
cd infra/terraform/envs/prod
terraform force-unlock <LOCK_ID>
```

### "Backend initialization failed"

**Cause**: S3 credentials not set or bucket doesn't exist.

**Solution**:
```bash
# 1. Verify credentials
source config/inputs.sh
echo $AWS_ACCESS_KEY_ID  # Should not be empty

# 2. Verify bucket exists
# Login to Hetzner Console → Object Storage → verify "openclaw-tfstate" bucket

# 3. Re-init
make init
```

### "cloud-init taking too long"

**Cause**: Large package downloads on first boot.

**Solution**:
```bash
# SSH as root and monitor
make ssh-root

# Watch cloud-init logs
tail -f /var/log/cloud-init-output.log

# Check status
cloud-init status --wait
```

### Still stuck?

1. **Check logs**: `make logs` and `make ssh` to investigate
2. **Destroy and recreate**: `make destroy && make apply && make bootstrap && make deploy`
3. **Open an issue**: [GitHub Issues](https://github.com/yourusername/openclaw-terraform-hetzner/issues)

---

## 🔒 Security Best Practices

✅ **SSH Keys Only**: Password authentication is disabled
✅ **Firewall Configured**: UFW + Hetzner Cloud Firewall (SSH only)
✅ **IP Restrictions**: Configure `ssh_allowed_cidrs` to limit access
✅ **Loopback Binding**: OpenClaw binds to `127.0.0.1` (access via SSH tunnel only)
✅ **Secrets Management**: All secrets in `.gitignore`d files
✅ **Automated Backups**: Daily backups with retention policy

### Recommended Actions

1. **Restrict SSH by IP**:
   ```bash
   export TF_VAR_ssh_allowed_cidrs='["YOUR_IP/32"]'
   ```

2. **Use strong API keys**: Generate dedicated tokens with minimal permissions

3. **Enable 2FA**: On Hetzner Cloud console account

4. **Regular updates**: Keep Ubuntu packages updated
   ```bash
   make ssh
   sudo apt update && sudo apt upgrade -y
   ```

5. **Monitor access**: Check SSH logs regularly
   ```bash
   make ssh
   sudo tail -f /var/log/auth.log
   ```

---

## 📁 Project Structure

```
.
├── infra/
│   ├── terraform/
│   │   ├── globals/               # Shared provider versions and backend docs
│   │   ├── envs/prod/             # Production environment config
│   │   └── modules/hetzner-vps/   # Reusable VPS module
│   └── cloud-init/
│       └── user-data.yml.tpl      # VM initialization template
├── deploy/
│   ├── bootstrap.sh               # First-time VPS setup
│   ├── deploy.sh                  # Deploy latest Docker image
│   ├── backup.sh                  # Backup script (runs on VPS)
│   ├── restore.sh                 # Restore from backup
│   ├── logs.sh                    # Stream container logs
│   └── status.sh                  # Health check
├── scripts/
│   ├── push-env.sh                # Push secrets to VPS
│   └── push-config.sh             # Push config files to VPS
├── config/
│   ├── inputs.sh                  # Your secrets (git-ignored)
│   └── inputs.example.sh          # Template for inputs.sh
├── secrets/
│   ├── openclaw.env               # App secrets (git-ignored)
│   └── openclaw.env.example       # Template
├── Makefile                       # All automation commands
├── README.md                      # This file
└── CLAUDE.md                      # AI assistant context
```

---

## 🤝 Contributing

We welcome contributions! Here's how you can help:

### Ways to Contribute

- 🐛 **Report bugs**: [Open an issue](https://github.com/yourusername/openclaw-terraform-hetzner/issues)
- 💡 **Suggest features**: Share ideas for improvements
- 📖 **Improve docs**: Fix typos, add examples, clarify instructions
- 🔧 **Submit PRs**: Add new features or fix bugs
- ⭐ **Star the repo**: Help others discover this project

### Development Setup

```bash
# Fork and clone your fork
git clone https://github.com/YOUR_USERNAME/openclaw-terraform-hetzner.git
cd openclaw-terraform-hetzner

# Create a branch
git checkout -b feature/your-feature-name

# Make changes, test locally
source config/inputs.sh
make validate
make plan

# Commit and push
git add .
git commit -m "feat: add your feature"
git push origin feature/your-feature-name

# Open a PR on GitHub
```

### Code Standards

- **Terraform**: Use `terraform fmt` before committing
- **Scripts**: Use ShellCheck for bash scripts
- **Commits**: Follow [Conventional Commits](https://www.conventionalcommits.org/)
- **Docs**: Update README.md for user-facing changes

---

## 📋 Comparison to Alternatives

| Approach | Cost/mo | Setup Time | Control | Privacy |
|----------|---------|------------|---------|---------|
| **This (Hetzner)** | ~$7 | 5 min | Full | Full |
| AWS EC2 (t3.medium) | ~$30 | 30 min | Full | Full |
| DigitalOcean | ~$24 | 15 min | Full | Full |
| Cloud IDE (GitHub Codespaces) | ~$40 | 2 min | Limited | Partial |
| SaaS AI Assistant | $20-40 | 1 min | None | None |

**When to use this**:
- ✅ You want full control over your AI assistant
- ✅ You care about data privacy and compliance
- ✅ You want to minimize costs
- ✅ You're comfortable with infrastructure-as-code

**When NOT to use this**:
- ❌ You need zero-maintenance SaaS
- ❌ You don't have an Anthropic API key
- ❌ You're not familiar with basic DevOps concepts

---

## 🌟 Related Projects

- **[OpenClaw](https://github.com/openclaw)** — The core AI assistant engine
- **[openclaw-docker-config](https://github.com/yourusername/openclaw-docker-config)** — Docker compose and config for OpenClaw
- **[Terraform Hetzner Cloud Provider](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs)** — Official provider docs

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

You are free to:
- ✅ Use commercially
- ✅ Modify
- ✅ Distribute
- ✅ Use privately

---

## 💬 Support

- **Documentation**: This README and [CLAUDE.md](CLAUDE.md)
- **Issues**: [GitHub Issues](https://github.com/yourusername/openclaw-terraform-hetzner/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/openclaw-terraform-hetzner/discussions)
- **Hetzner Docs**: [Hetzner Cloud Documentation](https://docs.hetzner.com/cloud/)
- **Terraform Docs**: [Terraform Documentation](https://developer.hashicorp.com/terraform/docs)

---

## 🙏 Acknowledgments

- **Anthropic** for Claude API and AI research
- **Hetzner** for affordable, reliable cloud infrastructure
- **HashiCorp** for Terraform
- **OpenClaw Community** for the core project

---

<div align="center">

**[⬆ Back to Top](#openclaw-infrastructure-on-hetzner-cloud)**

Made with ❤️ by the open-source community

**Ready to deploy?** [Get started in 5 minutes ⚡](#-quick-start-5-minutes)

</div>
