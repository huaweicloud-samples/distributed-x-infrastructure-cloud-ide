# 华为云 code-server 部署 — 核心资源
#
# 架构说明：
#   网络: VPC + 子网 + 安全组 + EIP
#   计算: ECS（Ubuntu 22.04 LTS）运行 code-server
#   认证: 密码本地落盘 + SSH 密钥对
#   加速: 可选 CDN
#
# 关键设计点：
#   1. 安全组放行策略
#   2. 密码存储方式
#   3. 会话管理方式
#   4. 权限管理方式
# ============================================================================

# ----------------------------------------------------------------------------
# 网络层：VPC + 子网 + 安全组
# ----------------------------------------------------------------------------

resource "huaweicloud_vpc" "main" {
  name = "${var.common_tags["Project"]}-vpc"
  cidr = "192.168.0.0/16"
}

resource "huaweicloud_vpc_subnet" "main" {
  name       = "${var.common_tags["Project"]}-subnet"
  vpc_id     = huaweicloud_vpc.main.id
  cidr       = "192.168.1.0/24"
  gateway_ip = "192.168.1.1"

  # DNS 服务器（华为云默认）
  primary_dns   = "100.125.1.250"
  secondary_dns = "100.125.129.250"
}

resource "huaweicloud_networking_secgroup" "main" {
  name        = "${var.common_tags["Project"]}-sg"
  description = "Security group for code-server (CDN origin access)"
}

# 入站：8080 端口（code-server），按变量放行
resource "huaweicloud_networking_secgroup_rule" "allow_8080" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 8080
  port_range_max    = 8080
  remote_ip_prefix  = var.internet_cidr_block
  security_group_id = huaweicloud_networking_secgroup.main.id
}

# 入站：22 端口（SSH 管理，仅密钥对登录）
resource "huaweicloud_networking_secgroup_rule" "allow_ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = var.internet_cidr_block
  security_group_id = huaweicloud_networking_secgroup.main.id
}

# 出方向：华为云默认自带 allow-all egress，无需显式创建（见 docs/13 §3）

# ----------------------------------------------------------------------------
# 弹性公网 IP
# ----------------------------------------------------------------------------

resource "huaweicloud_vpc_eip" "main" {
  publicip {
    type = "5_bgp"
  }
  bandwidth {
    name        = "${var.common_tags["Project"]}-eip-bw"
    size        = 5
    share_type  = "PER"
    charge_mode = "traffic"
  }
}

# ----------------------------------------------------------------------------
# ECS 实例
# ----------------------------------------------------------------------------

# 用户数据脚本（密码写本地文件）
locals {
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    version    = var.vscode_server_version
    PUBLIC_KEY = var.key_pair != "" ? "" : (length(huaweicloud_compute_keypair.main) > 0 ? huaweicloud_compute_keypair.main[0].public_key : "")
  }))

  # 解析最终使用的密钥对名称：用户指定则用用户的，否则用自动创建的
  effective_key_pair = var.key_pair != "" ? var.key_pair : huaweicloud_compute_keypair.main[0].name
}

# 自动创建 SSH 密钥对（当未指定已有密钥对时）
# 私钥写入本地文件 code-server-keypair.pem（权限 600），仅本地留存
resource "huaweicloud_compute_keypair" "main" {
  count    = var.key_pair != "" ? 0 : 1
  name     = "${var.common_tags["Project"]}-keypair"
  key_file = "C:/Users/dgcd/code-server-keypair.pem"
}

resource "huaweicloud_compute_instance" "vscode_server" {
  name               = "${var.common_tags["Project"]}-ecs"
  flavor_id          = var.ecs_flavor_id
  image_id           = data.huaweicloud_images_image.ubuntu.id
  security_group_ids = [huaweicloud_networking_secgroup.main.id]
  key_pair           = local.effective_key_pair
  availability_zone  = data.huaweicloud_availability_zones.available.names[0]

  user_data = local.user_data

  # 确保密钥对完全创建后再渲染 user_data（PUBLIC_KEY 才有值）
  depends_on = [huaweicloud_compute_keypair.main]

  network {
    uuid = huaweicloud_vpc_subnet.main.id
  }

  tags = merge(var.common_tags, {
    Name = "VSCodeServer"
  })
}

# 绑定 EIP 到 ECS
resource "huaweicloud_compute_eip_associate" "main" {
  public_ip   = huaweicloud_vpc_eip.main.address
  instance_id = huaweicloud_compute_instance.vscode_server.id
}

# ----------------------------------------------------------------------------
# CDN 加速域名
# 注意：service_area 决定备案要求（见 docs/10 坑 1）
# mainland_china/global 需 ICP 备案；outside_mainland_china 免备案
# ----------------------------------------------------------------------------

resource "huaweicloud_cdn_domain" "main" {
  count        = var.cdn_domain_name != "" ? 1 : 0
  name         = var.cdn_domain_name
  type         = "web"
  service_area = "outside_mainland_china" # 免备案；生产面向大陆请改 mainland_china 并走备案

  sources {
    active      = 1
    origin      = huaweicloud_vpc_eip.main.address
    origin_type = "ipaddr"
    http_port   = 8080
    https_port  = 443
  }

  # 缓存规则
  cache_settings {
    follow_origin = false
    rules {
      rule_type = "all"
      ttl       = 86400 # default_ttl
      ttl_type  = "s"
    }
  }

  # 高级配置：回源请求头
  configs {
    retrieval_request_header {
      name   = "Authorization"
      action = "set"
      value  = ""
    }
    retrieval_request_header {
      name   = "Host"
      action = "set"
      value  = var.cdn_domain_name
    }
  }

  tags = var.common_tags
}

# ----------------------------------------------------------------------------
# 随机后缀（用于 CDN 缓存策略名称等需要全局唯一的资源）
# ----------------------------------------------------------------------------

resource "random_id" "suffix" {
  byte_length = 4
}
