# ============================================
# Production Environment Variables
# ============================================

# ============================================
# Required: API Token
# ============================================

variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true
}

# ============================================
# Required: SSH Configuration
# ============================================

variable "ssh_key_fingerprint" {
  description = "Fingerprint of an existing Hetzner SSH key to use (avoids recreating shared keys)"
  type        = string
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed to SSH (e.g., ['1.2.3.4/32'])"
  type        = list(string)
  default     = []
}

# ============================================
# Project Configuration
# ============================================

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "openclaw"
}

# ============================================
# Server Configuration
# ============================================

variable "server_type" {
  description = "Hetzner server type"
  type        = string
  default     = "cx23"
}

variable "server_location" {
  description = "Hetzner datacenter location"
  type        = string
  default     = "nbg1"
}

# ============================================
# Application Configuration
# ============================================

variable "app_user" {
  description = "Non-root user to create on the server"
  type        = string
  default     = "openclaw"
}

variable "app_directory" {
  description = "Application directory path"
  type        = string
  default     = "/home/openclaw/.openclaw"
}

# ============================================
# Security Configuration
# ============================================

variable "enable_tailscale" {
  description = "Install and configure Tailscale VPN"
  type        = bool
  default     = false
}

variable "tailscale_auth_key" {
  description = "Tailscale auth key for automatic registration (optional)"
  type        = string
  default     = ""
  sensitive   = true
}
