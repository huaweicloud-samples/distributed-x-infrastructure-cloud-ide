# ============================================================================
# 数据源
# ============================================================================

# 查询 Ubuntu 22.04 公共镜像（锚定正则避免命中 GPU 变体）
data "huaweicloud_images_image" "ubuntu" {
  name        = "Ubuntu 22.04 server 64bit"
  most_recent = true
}

# 查询可用区（用于 ECS 和子网）
data "huaweicloud_availability_zones" "available" {}
