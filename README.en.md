# distributed-x-infrastructure-cloud-ide · Code-Server on Huawei Cloud

[![License](https://img.shields.io/badge/license-MIT--No--Attribution-green.svg)](LICENSE)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Huawei Cloud](https://img.shields.io/badge/Huawei%20Cloud-ECS%20%7C%20CDN-999999.svg)](https://www.huaweicloud.com/)

## 1. Overview

This practice deploys a browser-based VS Code development environment (code-server) on Huawei Cloud ECS, with optional CDN acceleration for global low-latency access. The stack includes an ECS instance running Ubuntu 22.04 LTS, an Elastic IP (EIP), a security group, and an optional CDN acceleration domain.

This solution is ideal for:
- Developers who need a consistent, cloud-based IDE accessible from any browser
- Teams wanting to standardize development environments
- Scenarios requiring remote development without local setup

---

## 2. Table of Contents

- [1. Overview](#1-overview)
- [2. Table of Contents](#2-table-of-contents)
- [3. Architecture Diagram](#3-architecture-diagram)
- [4. Highlights](#4-highlights)
- [5. Cloud Services Used](#5-cloud-services-used)
- [6. Prerequisites](#6-prerequisites)
- [7. Quick Start](#7-quick-start)
- [8. Step-by-Step Deployment](#8-step-by-step-deployment)
- [9. Usage / Verification](#9-usage--verification)
- [10. Cleanup](#10-cleanup)
- [11. Detailed Explanation](#11-detailed-explanation)
- [12. Dependencies](#12-dependencies)
- [13. FAQ / Troubleshooting](#13-faq--troubleshooting)
- [14. Contributing](#14-contributing)
- [15. License](#15-license)
- [16. Contact / Maintainers](#16-contact--maintainers)

```
├── infra/                 # Terraform infrastructure
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── data.tf
│   ├── versions.tf
│   ├── user_data.sh
│   └── terraform.tfvars.example
├── src/                   # Business code
│   ├── adapter/
│   ├── frontend/
│   └── functions/
├── docs/                  # Documentation
└── README.md
```

---

## 3. Architecture Diagram

```
User → [Optional] CDN → EIP → ECS:8080 (code-server)
└─ Local file (password storage)
```

| Component | Huawei Cloud service |
|---|---|
| Compute | ECS (Elastic Cloud Server) with Ubuntu 22.04 |
| Network | VPC + Subnet + Security Group |
| Public access | EIP (Elastic IP) |
| Acceleration | CDN (Content Delivery Network, optional) |
| Authentication | Password file on the local disk |

---

## 4. Highlights

- **One-command deployment**: `terraform apply` provisions the full stack
- **Optional CDN**: set `cdn_domain_name` to enable global acceleration
- **Secure by default**: SSH key-pair login, password stored locally

---

## 5. Cloud Services Used

- ECS (Elastic Cloud Server)
- VPC (Virtual Private Cloud)
- EIP (Elastic IP)
- CDN (Content Delivery Network, optional)

---

## 6. Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.0
- A Huawei Cloud account with:
- ECS, VPC, EIP, and CDN permissions
- An SSH key pair created in the target region (Console → Elastic Cloud Server → Key Pairs)
- Huawei Cloud CLI credentials configured through environment variables:
```bash
export HW_ACCESS_KEY="<HW_ACCESS_KEY>"
export HW_SECRET_KEY="<HW_SECRET_KEY>"
export HW_REGION_NAME="cn-north-4"
```
- (Optional) An ICP-registered domain if using the `mainland_china` CDN service area

---

## 7. Quick Start

1. **Enter the infra directory:**
```bash
cd infra/
```

2. **Copy and customize variables:**
```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: set key_pair, region, and the optional cdn_domain_name
```

3. **Initialize and apply:**
```bash
terraform init
terraform plan
terraform apply
```

4. **Retrieve the password:**
```bash
$(terraform output -raw password_retrieval_command)
```

5. **Access code-server:**
- Via EIP: `http://<eip>:8080`
- Via CDN (if enabled): `https://<cdn-domain>`

---

## 8. Step-by-Step Deployment

1. Run `terraform init` in the `infra/` directory to initialize the provider.
2. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in the variables.
3. Set the Huawei Cloud AK/SK environment variables.
4. Run `terraform plan` to preview.
5. Run `terraform apply` to deploy.
6. Access code-server through the EIP or CDN domain.

---

## 9. Usage / Verification

After `terraform apply` completes:

1. Get the access URL:
```bash
terraform output vscode_server_public_ip
terraform output vscode_server_cdn_domain
```

2. Get the password:
```bash
# Connect via SSH and read the password file
ssh -i <your-key.pem> ubuntu@<eip>
sudo cat /home/ubuntu/.config/code-server/password.txt
```

3. Open a browser and log in:
- Navigate to `http://<eip>:8080` (or the CDN URL)
- Enter the password
- Start coding!

After deployment, follow these steps to verify that the business functionality works before considering the delivery complete.

---

## 10. Cleanup

To avoid lingering resources, destroy them with:
```bash
terraform destroy
```

---

## 11. Detailed Explanation

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `region` | Huawei Cloud region | `cn-north-4` | No |
| `vscode_server_version` | code-server version | `4.91.1` | No |
| `ecs_flavor_id` | ECS flavor ID (spec) | `s6.2xlarge.2` | No |
| `key_pair` | SSH key pair name | — | **Yes** |
| `cdn_domain_name` | CDN domain (empty = disable CDN) | `""` | No |
| `internet_cidr_block` | Inbound CIDR for port 8080 | `0.0.0.0/0` | No |
| `common_tags` | Tags for all resources | `{Project="code-server"}` | No |

---

## 12. Dependencies

- [code-server](https://github.com/coder/code-server) by Coder
- [Huawei Cloud Terraform Provider](https://registry.terraform.io/providers/huaweicloud/huaweicloud/latest)
- [Huawei Cloud Toolkit](https://marketplace.visualstudio.com/items?itemName=huawei-cloud.huawei-cloud-toolkit) VS Code extension

---

## 13. FAQ / Troubleshooting

**Q: CDN domain shows "inactive" after apply?**
A: CDN domains require the CNAME record to be configured at your DNS provider. Check the `cname` output: `terraform output -raw vscode_server_cdn_domain`.

**Q: How to change the code-server password?**
A: SSH into the ECS, edit `/home/ubuntu/.config/code-server/config.yaml`, then run `sudo systemctl restart code-server@ubuntu`.

**Q: Can I use a different ECS flavor?**
A: Yes, set `ecs_flavor_id` to any available flavor in your region. Use `s6.large.2` for lighter workloads or `c7.xlarge.2` for compute-intensive tasks.

**Q: Security group allows 0.0.0.0/0 on port 8080 — is this safe?**
A: The port is only reachable through the CDN (if enabled) or direct EIP access. For production, enable CDN URL authentication or WAF.

---

## 14. Contributing

Issues and PRs are welcome. Please follow the existing directory structure and code style in this repository.

---

## 15. License

This practice is licensed under MIT No Attribution — see [LICENSE](LICENSE) for details.

---

## 16. Contact / Maintainers
| Item | Content |
|---|---|
| **Creator** | [dgc-git](https://github.com/dgc-git) |
| **Maintainer** | [dgc-git](https://github.com/dgc-git) |
| **Contact** | GitHub Issues / PR (see [Section 14](#14-contributing)) |
