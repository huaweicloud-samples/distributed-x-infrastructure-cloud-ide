# ============================================================================
# 变量定义
# ============================================================================

variable "region" {
  description = "华为云区域"
  type        = string
  default     = "cn-north-4" # 北京四

  validation {
    condition = contains([
      "cn-north-4",
      "cn-east-3",
      "cn-south-1",
      "ap-southeast-1"
    ], var.region)
    error_message = "Region must be one of: cn-north-4, cn-east-3, cn-south-1, ap-southeast-1."
  }
}

variable "vscode_server_version" {
  description = "Version of code-server to install"
  type        = string
  default     = "4.91.1"
}

variable "ecs_flavor_id" {
  description = "ECS flavor ID (spec) for code-server."
  type        = string
  default     = "s6.2xlarge.2"
}

variable "key_pair" {
  description = "SSH key pair name for ECS access. If empty, a new keypair will be auto-created."
  type        = string
  default     = "" # 空则自动创建密钥对（见 main.tf）
}

variable "create_keypair" {
  description = "Whether to auto-create an SSH keypair if key_pair is not specified"
  type        = bool
  default     = true
}

variable "cdn_domain_name" {
  description = "CDN acceleration domain name. Leave empty to skip CDN creation."
  type        = string
  default     = ""
}

variable "internet_cidr_block" {
  description = "CIDR block for inbound access to port 8080"
  type        = string
  default     = "0.0.0.0/0"
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project = "code-server"
  }
}
