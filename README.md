# distributed-x-infrastructure-cloud-ide · Code-Server on Huawei Cloud

[![License](https://img.shields.io/badge/license-MIT--No--Attribution-green.svg)](LICENSE)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Huawei Cloud](https://img.shields.io/badge/Huawei%20Cloud-ECS%20%7C%20CDN-999999.svg)](https://www.huaweicloud.com/)

## 1. 简介 / Overview

### 简介

本实践在华为云 ECS 上部署基于浏览器的 VS Code 开发环境（code-server），并可选配 CDN 加速，实现全球低延迟访问。技术栈包括运行 Ubuntu 22.04 LTS 的 ECS 实例、弹性公网 IP（EIP）、安全组，以及可选的 CDN 加速域名。

本方案适用于：
- 需要从任意浏览器访问统一云端 IDE 的开发者
- 希望标准化开发环境的团队
- 需要远程开发且无需本地环境配置的场景

---

## 2. 目录

- [1. 简介 / Overview](#1-简介--overview)
- [2. 目录](#2-目录)
- [3. 架构图](#3-架构图)
- [4. 方案亮点](#4-方案亮点)
- [5. 涉及云服务](#5-涉及云服务)
- [6. 前置条件](#6-前置条件)
- [7. 快速开始](#7-快速开始)
- [8. 分步部署](#8-分步部署)
- [9. 使用方法 / 验证](#9-使用方法--验证)
- [10. 清理资源](#10-清理资源)
- [11. 详细说明](#11-详细说明)
- [12. 依赖](#12-依赖)
- [13. FAQ / 故障排除](#13-faq--故障排除)
- [14. 贡献指南](#14-贡献指南)
- [15. 许可证](#15-许可证)
- [16. 联系方式 / 维护者](#16-联系方式--维护者)

```
├── infra/                 # Terraform 基础设施
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── data.tf
│   ├── versions.tf
│   ├── user_data.sh
│   └── terraform.tfvars.example
├── src/                   # 业务代码
│   ├── adapter/
│   ├── frontend/
│   └── functions/
├── docs/                  # 文档
└── README.md
```

---

## 3. 架构图

```
用户 → [可选] CDN → EIP → ECS:8080（code-server）
└─ 本地文件（密码存储）
```

| 组件 | 华为云服务 |
|---|---|
| 计算 | 运行 Ubuntu 22.04 的 ECS（弹性云服务器） |
| 网络 | VPC + 子网 + 安全组 |
| 公网访问 | EIP（弹性公网 IP） |
| 加速 | CDN（内容分发网络，可选） |
| 认证 | 本地磁盘上的密码文件 |

---

## 4. 方案亮点

- **一键部署**：`terraform apply` 创建完整技术栈
- **可选 CDN**：设置 `cdn_domain_name` 即可启用全球加速
- **默认安全**：SSH 密钥对登录，密码存储在本地

---

## 5. 涉及云服务

- ECS（弹性云服务器）
- VPC（虚拟私有云）
- EIP（弹性公网 IP）
- CDN（内容分发网络，可选）

---

## 6. 前置条件

- [Terraform](https://www.terraform.io/downloads) >= 1.0
- 华为云账号，并具备以下条件：
- 具备 ECS、VPC、EIP、CDN 权限
- 在目标区域已创建 SSH 密钥对（控制台 → 弹性云服务器 → 密钥对）
- 已通过环境变量配置华为云 CLI 凭据：
```bash
export HW_ACCESS_KEY="<HW_ACCESS_KEY>"
export HW_SECRET_KEY="<HW_SECRET_KEY>"
export HW_REGION_NAME="cn-north-4"
```
- （可选）若使用 `mainland_china` CDN 服务区域，需具备已备案的域名

---

## 7. 快速开始

1. **进入 infra 目录：**
```bash
cd infra/
```

2. **复制并修改变量：**
```bash
cp terraform.tfvars.example terraform.tfvars
# 编辑 terraform.tfvars：设置 key_pair、region，以及可选的 cdn_domain_name
```

3. **初始化并部署：**
```bash
terraform init
terraform plan
terraform apply
```

4. **获取密码：**
```bash
$(terraform output -raw password_retrieval_command)
```

5. **访问 code-server：**
- 通过 EIP：`http://<eip>:8080`
- 通过 CDN（如已启用）：`https://<cdn-domain>`

---

## 8. 分步部署

1. 在 `infra/` 目录执行 `terraform init` 初始化 provider。
2. 复制 `terraform.tfvars.example` 为 `terraform.tfvars` 并填写变量。
3. 设置华为云 AK/SK 环境变量。
4. 执行 `terraform plan` 预览。
5. 执行 `terraform apply` 部署。
6. 通过 EIP 或 CDN 域名访问 code-server。

---

## 9. 使用方法 / 验证

### 使用方法与验证

`terraform apply` 完成后：

1. 获取访问地址：
```bash
terraform output vscode_server_public_ip
terraform output vscode_server_cdn_domain
```

2. 获取密码：
```bash
# 通过 SSH 连接并读取密码文件
ssh -i <your-key.pem> ubuntu@<eip>
sudo cat /home/ubuntu/.config/code-server/password.txt
```

3. 打开浏览器登录：
- 访问 `http://<eip>:8080`（或 CDN 地址）
- 输入密码
- 开始编码！

部署完成后请按本节步骤自行验证，确认业务功能可用，方可视为交付完成。

---

## 10. 清理资源

为避免资源持续占用，执行以下命令销毁资源：
```bash
terraform destroy
```

---

## 11. 详细说明

| 变量 | 说明 | 默认值 | 是否必填 |
|----------|-------------|---------|----------|
| `region` | 华为云区域 | `cn-north-4` | 否 |
| `vscode_server_version` | code-server 版本 | `4.91.1` | 否 |
| `ecs_flavor_id` | ECS 规格 ID | `s6.2xlarge.2` | 否 |
| `key_pair` | SSH 密钥对名称 | — | **是** |
| `cdn_domain_name` | CDN 域名（留空 = 禁用 CDN） | `""` | 否 |
| `internet_cidr_block` | 8080 端口的入站 CIDR | `0.0.0.0/0` | 否 |
| `common_tags` | 所有资源的标签 | `{Project="code-server"}` | 否 |

---

## 12. 依赖

- Coder 出品的 [code-server](https://github.com/coder/code-server)
- [Huawei Cloud Terraform Provider](https://registry.terraform.io/providers/huaweicloud/huaweicloud/latest)
- VS Code 扩展 [Huawei Cloud Toolkit](https://marketplace.visualstudio.com/items?itemName=huawei-cloud.huawei-cloud-toolkit)

---

## 13. FAQ / 故障排除

### FAQ

**Q：apply 后 CDN 域名显示「inactive」？**
A：CDN 域名需要在 DNS 服务商处配置 CNAME 记录。查看 `cname` 输出：`terraform output -raw vscode_server_cdn_domain`。

**Q：如何修改 code-server 密码？**
A：SSH 登录 ECS，编辑 `/home/ubuntu/.config/code-server/config.yaml`，然后执行 `sudo systemctl restart code-server@ubuntu`。

**Q：可以使用其他 ECS 规格吗？**
A：可以，将 `ecs_flavor_id` 设为所在区域任意可用规格。轻量负载用 `s6.large.2`，计算密集型任务用 `c7.xlarge.2`。

**Q：安全组对 8080 端口放通 0.0.0.0/0 是否安全？**
A：该端口仅能通过 CDN（如已启用）或直接 EIP 访问。生产环境建议启用 CDN URL 鉴权或 WAF。

---

## 14. 贡献指南

欢迎提交 Issue 与 PR。请遵循仓库内现有目录结构与代码风格。

---

## 15. 许可证

本实践采用 MIT No Attribution 许可证，详见 [LICENSE](LICENSE)。

---

## 16. 联系方式 / 维护者
| 项 | 内容 |
|---|---|
| **创建者** | [dgc-git](https://github.com/dgc-git) |
| **维护者** | [dgc-git](https://github.com/dgc-git) |
| **联系方式** | GitHub Issues / PR（见[第 14 节](#14-贡献指南)） |
