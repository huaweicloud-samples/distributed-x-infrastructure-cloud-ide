terraform {
  required_version = ">= 1.0"

  required_providers {
    huaweicloud = {
      source  = "huaweicloud/huaweicloud"
      version = "~> 1.70"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }

  backend "local" {}
}

provider "huaweicloud" {
  region = var.region
  # AK/SK 从环境变量读取，不硬编码
  # export HW_ACCESS_KEY="your-access-key"
  # export HW_SECRET_KEY="your-secret-key"
}
