# ============================================
# Required Variables
# ============================================

variable "project_name" {
  description = "Name of the project (used for resource naming)"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "ssh_key_fingerprint" {
  description = "Fingerprint of an existing Hetzner SSH key to use"
  type        = string
}

variable "ssh_allowed_cidrs" {
  description = "List of CIDR blocks allowed to SSH into the server"
  type        = list(string)
  default     = []
}

# ============================================
# Server Configuration
# ============================================

variable "server_type" {
  description = "Hetzner server type (e.g., cx23, cx33)"
  type        = string
  default     = "cx23"
}

variable "server_image" {
  description = "Operating system image for the server"
  type        = string
  default     = "ubuntu-24.04"
}

variable "server_location" {
  description = "Hetzner Cloud datacenter location"
  type        = string
  default     = "nbg1"
  validation {
    condition     = contains(["fsn1", "nbg1", "hel1", "ash", "hil"], var.server_location)
    error_message = "Location must be a valid Hetzner datacenter."
  }
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

variable "cloud_init_user_data" {
  description = "Rendered cloud-init user data content"
  type        = string
}

# ============================================
# Security Configuration
# ============================================

variable "enable_tailscale" {
  description = "Install and configure Tailscale VPN"
  type        = bool
  default     = false
}
