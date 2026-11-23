# ============================================================================
# 输出
# ============================================================================

output "vscode_server_cdn_domain" {
  description = "CDN acceleration domain name for accessing code-server (if CDN enabled)"
  value       = var.cdn_domain_name != "" ? "https://${huaweicloud_cdn_domain.main[0].name}" : "CDN not enabled (set cdn_domain_name to enable)"
}

output "vscode_server_public_ip" {
  description = "Public IP address (EIP) of the code-server ECS"
  value       = huaweicloud_vpc_eip.main.address
}

output "vscode_server_private_ip" {
  description = "Private IP address of the code-server ECS"
  value       = huaweicloud_compute_instance.vscode_server.access_ip_v4
}

output "vscode_server_instance_id" {
  description = "ECS instance ID of the code-server"
  value       = huaweicloud_compute_instance.vscode_server.id
}

output "vscode_server_password_file" {
  description = "Local file path containing the code-server password"
  value       = "/home/ubuntu/.config/code-server/password.txt"
}

output "password_retrieval_command" {
  description = "Command to retrieve the code-server password from the ECS"
  value       = "ssh -i <your-key.pem> ubuntu@${huaweicloud_vpc_eip.main.address} 'sudo cat /home/ubuntu/.config/code-server/password.txt'"
}

output "ssh_command" {
  description = "SSH command to connect to the ECS"
  value       = "ssh -i ${var.key_pair != "" ? "<your-key.pem>" : "${path.module}/code-server-keypair.pem"} ubuntu@${huaweicloud_vpc_eip.main.address}"
}

output "private_key_file" {
  description = "Local path to the auto-generated private key (if create_keypair=true)"
  value       = var.key_pair != "" ? "Using existing keypair: ${var.key_pair}" : "${path.module}/code-server-keypair.pem"
}
