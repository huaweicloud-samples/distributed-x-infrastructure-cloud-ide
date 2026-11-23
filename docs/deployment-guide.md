# 部署指南

本指南描述如何在华为云上部署云端开发环境（code-server）。所有命令使用相对路径，在仓库根目录执行；涉及凭据的部分均为占位说明，不包含真实值。

## 1. 前置准备

| 项 | 要求 |
|---|---|
| 账号 | 华为云账号，具备 VPC / 子网 / 安全组 / ECS / EIP / 密钥对创建权限；启用 CDN 时还需 CDN 域名管理权限 |
| 命令行工具 | Terraform >= 1.5（推荐 1.9+），已可访问 `huaweicloud` provider |
| 区域 | 默认 `cn-north-4`（华北-北京四），可在变量文件中调整 |
| 登录方式 | 本地已有 SSH 密钥对，或允许本实践自动创建密钥对 |
| 域名（可选） | 启用 CDN 时需准备已完成备案的加速域名 |

## 2. 配置访问凭据

本实践通过环境变量读取访问凭据，由 Terraform 在初始化时加载。请在当前会话中按华为云「我的凭证」页面获取的 Access Key 与 Secret Key 设置：

```bash
export HW_ACCESS_KEY="<你的AccessKey>"
export HW_SECRET_KEY="<你的SecretKey>"
```

> 请勿将 Access Key / Secret Key 写入任何 `.tf`、`.tfvars` 或提交到版本库。生产环境建议使用更细粒度的临时凭据或统一凭证管理服务。

## 3. 准备变量

复制变量示例并按需修改：

```bash
cd infra
cp terraform.tfvars.example terraform.tfvars
```

至少确认以下变量：

| 变量 | 说明 | 示例 |
|---|---|---|
| `region` | 部署区域 | `cn-north-4` |
| `vscode_server_version` | code-server 版本 | `4.91.1` |
| `ecs_flavor_id` | ECS 规格标识 | 按实际需求选择，示例见变量文件 |
| `create_keypair` | 是否自动创建密钥对 | `true` |
| `key_pair` | 已有密钥对名称（`create_keypair=false` 时必填） | 你的密钥对名称 |
| `cdn_domain_name` | CDN 加速域名，留空则不启用 | `""` |
| `internet_cidr_block` | 允许访问 8080 的源地址段 | 生产环境改为运维者 IP 段 |

> 生产环境务必把 `internet_cidr_block` 收敛到具体 IP 段，避免开发环境对全网开放。

## 4. 初始化与校验

```bash
cd infra
terraform init
terraform validate
terraform fmt -check
```

校验通过（提示配置有效）后再继续。

## 5. 预演与部署

```bash
terraform plan
terraform apply
```

`apply` 完成后会输出以下关键信息（名称以实际输出为准）：

- `vscode_server_public_ip`：ECS 绑定的公网 IP
- `vscode_server_cdn_domain`：CDN 访问地址（未启用时给出提示）
- `vscode_server_instance_id`：实例 ID
- `ssh_command`：SSH 登录命令
- `password_retrieval_command`：读取登录口令的命令

## 6. 访问与验证

1. 获取公网 IP（或 CDN 域名）与登录命令：

```bash
terraform output vscode_server_public_ip
terraform output ssh_command
```

2. 登录实例读取 code-server 口令：

```bash
ssh -i <你的私钥文件> ubuntu@<公网IP>
sudo cat /home/ubuntu/.config/code-server/password.txt
```

3. 浏览器访问并登录：

- 直连：`http://<公网IP>:8080`
- 启用 CDN：`https://<加速域名>`

输入上一步读取的口令即可进入开发环境。若页面无法打开，请检查安全组入站规则是否放行 8080、实例初始化脚本是否执行成功。

## 7. 清理资源

```bash
cd infra
terraform destroy
```

销毁后建议到控制台确认 ECS、EIP、安全组、VPC、密钥对与（如有）CDN 域名均已释放，避免产生遗留资源。

## 8. 常见问题

- **无法 SSH 登录**：确认密钥对匹配、安全组已放行 22 端口、登录用户为镜像默认用户。
- **code-server 页面打不开**：确认安全组已放行 8080，且 `user_data.sh` 安装成功；可通过 SSH 查看服务状态。
- **CDN 访问异常**：确认域名已完成备案与解析，且 `cdn_domain_name` 与域名配置一致。
- **更换规格**：修改 `ecs_flavor_id` 后重新执行 `plan` / `apply`，部分变更会触发实例重建，请先保存开发环境内的数据。
