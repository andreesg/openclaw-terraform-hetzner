# ============================================
# Server Outputs
# ============================================

output "server_id" {
  description = "The ID of the created server"
  value       = hcloud_server.main.id
}

output "server_name" {
  description = "The name of the created server"
  value       = hcloud_server.main.name
}

output "server_ipv4" {
  description = "The public IPv4 address of the server"
  value       = hcloud_server.main.ipv4_address
}

output "server_ipv6" {
  description = "The public IPv6 address of the server"
  value       = hcloud_server.main.ipv6_address
}

output "server_status" {
  description = "The status of the server"
  value       = hcloud_server.main.status
}

# ============================================
# SSH Outputs
# ============================================

output "ssh_key_id" {
  description = "The ID of the SSH key"
  value       = data.hcloud_ssh_key.main.id
}

output "firewall_id" {
  description = "The ID of the firewall"
  value       = hcloud_firewall.main.id
}

# ============================================
# Connection Outputs
# ============================================

output "ssh_command" {
  description = "SSH command to connect as the application user"
  value       = "ssh ${var.app_user}@${hcloud_server.main.ipv4_address}"
}

output "ssh_command_root" {
  description = "SSH command to connect as root"
  value       = "ssh root@${hcloud_server.main.ipv4_address}"
}
