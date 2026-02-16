# =============================================================================
# OpenClaw Infrastructure Makefile
# =============================================================================
# Usage: make <target> [ENV=prod]

SHELL := /bin/bash
.PHONY: init plan apply destroy ssh ssh-root tunnel output ip fmt validate clean help \
        bootstrap deploy push-env push-config setup-auth backup-now restore logs status \
        workspace-sync

# Default target
.DEFAULT_GOAL := help

# Default values
ENV ?= prod
TERRAFORM_DIR := infra/terraform/envs/$(ENV)

# Server IP - can be overridden or read from Terraform
SERVER_IP ?= $(shell cd $(TERRAFORM_DIR) && terraform output -raw server_ip 2>/dev/null)

# Colors
GREEN  := \033[0;32m
YELLOW := \033[1;33m
RED    := \033[0;31m
BLUE   := \033[0;34m
BOLD   := \033[1m
NC     := \033[0m

# =============================================================================
# Terraform Commands
# =============================================================================

init: ## Initialize Terraform backend
	@echo -e "$(GREEN)[INFO]$(NC) Initializing Terraform for $(ENV)..."
	@cd $(TERRAFORM_DIR) && terraform init

plan: ## Preview Terraform changes
	@echo -e "$(GREEN)[INFO]$(NC) Planning Terraform changes for $(ENV)..."
	@cd $(TERRAFORM_DIR) && terraform plan

apply: ## Apply Terraform changes
	@echo -e "$(YELLOW)[WARN]$(NC) This will modify infrastructure for $(ENV)"
	@cd $(TERRAFORM_DIR) && terraform apply

destroy: ## Destroy all managed infrastructure
	@echo -e "$(RED)[DANGER]$(NC) This will DESTROY all infrastructure for $(ENV)!"
	@cd $(TERRAFORM_DIR) && terraform destroy

fmt: ## Format Terraform files
	@echo -e "$(GREEN)[INFO]$(NC) Formatting Terraform files..."
	@terraform fmt -recursive infra/

validate: ## Validate Terraform configuration
	@echo -e "$(GREEN)[INFO]$(NC) Validating Terraform..."
	@cd $(TERRAFORM_DIR) && terraform init -backend=false -input=false > /dev/null 2>&1 && terraform validate
	@echo ""
	@echo -e "$(GREEN)[INFO]$(NC) Validating shell scripts..."
	@for script in deploy/*.sh scripts/*.sh; do bash -n "$$script" && echo "  $$script: OK"; done
	@echo ""
	@echo -e "$(GREEN)All validations passed!$(NC)"

# =============================================================================
# Utility Commands
# =============================================================================

ssh: ## SSH into the server as the openclaw user
	@echo -e "$(GREEN)[INFO]$(NC) Connecting to $(SERVER_IP)..."
	ssh openclaw@$(SERVER_IP)

ssh-root: ## SSH into the server as root
	@echo -e "$(YELLOW)[WARN]$(NC) Connecting as root to $(SERVER_IP)..."
	ssh root@$(SERVER_IP)

tunnel: ## Open SSH tunnel to OpenClaw gateway (localhost:18789)
	@echo -e "$(GREEN)[INFO]$(NC) Opening tunnel to $(SERVER_IP):18789..."
	@echo -e "  Gateway available at $(BOLD)http://localhost:18789$(NC)"
	@echo -e "  $(BOLD)Ctrl+C$(NC) to close"
	@echo ""
	@ssh -N -L 18789:127.0.0.1:18789 openclaw@$(SERVER_IP)

output: ## Show all Terraform outputs
	@cd $(TERRAFORM_DIR) && terraform output

ip: ## Show server IP address
	@cd $(TERRAFORM_DIR) && terraform output -raw server_ip

clean: ## Clean up Terraform files (keeps state)
	rm -rf $(TERRAFORM_DIR)/.terraform/
	rm -f $(TERRAFORM_DIR)/.terraform.lock.hcl

# =============================================================================
# Deploy Commands
# =============================================================================

bootstrap: ## Bootstrap OpenClaw on the VPS (run once after apply)
	@echo -e "$(BLUE)[DEPLOY]$(NC) Bootstrapping OpenClaw on VPS..."
	@./deploy/bootstrap.sh

deploy: ## Pull latest image and restart container on the VPS
	@echo -e "$(BLUE)[DEPLOY]$(NC) Deploying latest image to VPS..."
	@./deploy/deploy.sh

push-env: ## Push secrets/openclaw.env to the VPS
	@echo -e "$(BLUE)[DEPLOY]$(NC) Pushing secrets to VPS..."
	@./scripts/push-env.sh

push-config: ## Push config files from CONFIG_DIR to the VPS
	@echo -e "$(BLUE)[DEPLOY]$(NC) Pushing config to VPS..."
	@./scripts/push-config.sh

setup-auth: ## Set up Claude subscription auth on the VPS
	@echo -e "$(BLUE)[AUTH]$(NC) Setting up Claude subscription auth..."
	@./scripts/setup-auth.sh

backup-now: ## Run backup now on the VPS
	@echo -e "$(GREEN)[INFO]$(NC) Running backup on $(SERVER_IP)..."
	ssh -o StrictHostKeyChecking=accept-new openclaw@$(SERVER_IP) \
		'bash -s' < ./deploy/backup.sh

restore: ## Restore from backup (use BACKUP=filename)
ifndef BACKUP
	@echo -e "$(RED)[ERROR]$(NC) BACKUP variable required"
	@echo "Usage: make restore BACKUP=openclaw_backup_20240115_030000.tar.gz"
	@echo ""
	@echo "To list available backups:"
	@echo "  ssh openclaw@$(SERVER_IP) 'ls ~/backups/'"
	@exit 1
endif
	./deploy/restore.sh $(BACKUP)

logs: ## Stream Docker logs from the VPS
	@echo -e "$(GREEN)[INFO]$(NC) Streaming logs from VPS..."
	@./deploy/logs.sh

status: ## Check OpenClaw status on the VPS
	@echo -e "$(GREEN)[INFO]$(NC) Checking VPS status..."
	@./deploy/status.sh

workspace-sync: ## Sync workspace to GitHub now
	@echo -e "$(GREEN)[INFO]$(NC) Syncing workspace on $(SERVER_IP)..."
	ssh -o StrictHostKeyChecking=accept-new openclaw@$(SERVER_IP) \
		'cd ~/openclaw && docker compose exec workspace-sync workspace-sync.sh'


# =============================================================================
# Help
# =============================================================================

help: ## Show this help message
	@echo -e "$(BOLD)OpenClaw Infrastructure$(NC)"
	@echo ""
	@echo -e "Usage: make <target> [ENV=prod]"
	@echo ""
	@echo -e "$(BOLD)Terraform:$(NC)"
	@echo -e "  $(GREEN)init$(NC)            Initialize Terraform backend"
	@echo -e "  $(GREEN)plan$(NC)            Preview Terraform changes"
	@echo -e "  $(YELLOW)apply$(NC)           Apply Terraform changes"
	@echo -e "  $(RED)destroy$(NC)         Destroy all managed infrastructure"
	@echo -e "  $(GREEN)fmt$(NC)             Format Terraform files"
	@echo -e "  $(GREEN)validate$(NC)        Validate Terraform configuration"
	@echo ""
	@echo -e "$(BOLD)Deploy:$(NC)"
	@echo -e "  $(BLUE)bootstrap$(NC)       Bootstrap OpenClaw on the VPS (run once)"
	@echo -e "  $(BLUE)deploy$(NC)          Pull latest image and restart container"
	@echo -e "  $(BLUE)push-env$(NC)        Push secrets/openclaw.env to the VPS"
	@echo -e "  $(BLUE)push-config$(NC)     Push config files to the VPS"
	@echo -e "  $(BLUE)setup-auth$(NC)      Set up Claude subscription auth"
	@echo ""
	@echo -e "$(BOLD)Operations:$(NC)"
	@echo -e "  $(GREEN)ssh$(NC)             SSH as openclaw user"
	@echo -e "  $(GREEN)ssh-root$(NC)        SSH as root"
	@echo -e "  $(GREEN)tunnel$(NC)          SSH tunnel to gateway (localhost:18789)"
	@echo -e "  $(GREEN)status$(NC)          Check VPS status"
	@echo -e "  $(GREEN)logs$(NC)            Stream Docker logs"
	@echo -e "  $(GREEN)backup-now$(NC)      Run backup now"
	@echo -e "  $(GREEN)restore$(NC)         Restore from backup (BACKUP=filename)"
	@echo -e "  $(GREEN)workspace-sync$(NC)  Sync workspace to GitHub now"
	@echo -e "  $(GREEN)output$(NC)          Show Terraform outputs"
	@echo -e "  $(GREEN)ip$(NC)              Show server IP"
	@echo ""
	@echo -e "$(BOLD)Quick Start:$(NC)"
	@echo "  source config/inputs.sh"
	@echo "  make init && make plan && make apply"
	@echo "  make bootstrap && make deploy"
	@echo "  make status"
