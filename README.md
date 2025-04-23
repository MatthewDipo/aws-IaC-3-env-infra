# EKS 3-Tier Infrastructure with Terragrunt

[![Terraform](https://img.shields.io/badge/Terraform-%E2%89%A51.0-623CE4?logo=terraform)](https://www.terraform.io)
[![Terragrunt](https://img.shields.io/badge/Terragrunt-%E2%89%A50.36-259539?logo=terragrunt)](https://terragrunt.gruntwork.io/)
[![AWS](https://img.shields.io/badge/AWS-Infrastructure-232F3E?logo=amazon-aws)](https://aws.amazon.com/)

## Overview

This project defines and deploys a standard 3-tier application infrastructure on AWS using reusable Terraform modules orchestrated by Terragrunt. It creates distinct, isolated environments (`dev`, `staging`, `prod`) each containing:

1.  **VPC:** A dedicated Virtual Private Cloud with public and private subnets across multiple Availability Zones (AZs) for network isolation and high availability. Includes NAT Gateways for outbound internet access from private subnets.
2.  **EKS Cluster:** An Amazon Elastic Kubernetes Service cluster with managed node groups deployed into the private subnets. Includes configuration for core add-ons (CoreDNS, Kube Proxy, VPC CNI) and an IAM OIDC provider for secure pod access to AWS services (IRSA).
3.  **RDS Instance:** An Amazon Relational Database Service instance (PostgreSQL) deployed into the private subnets, with credentials managed via AWS Secrets Manager.

Terragrunt is used to keep the infrastructure code DRY (Don't Repeat Yourself) by defining common configurations and leveraging shared Terraform modules.

## Architecture

The infrastructure architecture has been broken down into smaller, more manageable components for better visualization and understanding. The architecture is documented in the following sections:

- [Network Architecture (VPC)](docs/architecture.md#1-network-architecture-vpc)
- [EKS Cluster Architecture](docs/architecture.md#2-eks-cluster-architecture)
- [Database Layer](docs/architecture.md#3-database-layer)
- [State Management](docs/architecture.md#4-state-management)

For detailed diagrams and explanations, see the [complete architecture documentation](docs/architecture.md).

## Prerequisites

* **AWS Account:** An active AWS account with necessary permissions to create VPC, EKS, RDS, IAM roles/policies, S3 buckets, DynamoDB tables, Security Groups, NAT Gateways, etc.
* **AWS CLI:** Configured with credentials for your AWS account (`aws configure`). [Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html)
* **Terraform:** Version 1.0 or later. [Installation Guide](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
* **Terragrunt:** Version 0.36 or later. [Installation Guide](https://terragrunt.gruntwork.io/docs/getting-started/install/)
* **kubectl:** To interact with the EKS cluster. [Installation Guide](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
* **(Optional) Docker:** If you intend to build and push container images for deployment onto EKS.

## Directory Structure

```
.
├── live/                # Environment-specific configurations
│   ├── dev/            # Development environment
│   │   ├── env.hcl     # Dev environment variables (e.g., region)
│   │   ├── vpc/        # VPC configuration for Dev
│   │   │   └── terragrunt.hcl
│   │   ├── eks/        # EKS configuration for Dev
│   │   │   └── terragrunt.hcl
│   │   └── rds/        # RDS configuration for Dev
│   │       └── terragrunt.hcl
│   ├── staging/        # Staging environment (similar structure to dev)
│   └── prod/           # Production environment (similar structure to dev)
└── modules/            # Reusable Terraform modules
    ├── vpc/           # VPC module
    ├── eks/           # EKS module
    └── rds/           # RDS module
```

## Getting Started

1. Clone this repository
2. Install prerequisites (AWS CLI, Terraform, Terragrunt, kubectl)
3. Configure AWS credentials (`aws configure`)
4. Navigate to the desired environment directory (e.g., `cd live/dev`)
5. Review and update environment variables in `env.hcl`
6. Deploy infrastructure components in order:
   ```bash
   cd vpc && terragrunt apply
   cd ../eks && terragrunt apply
   cd ../rds && terragrunt apply
   ```

After deployment, important outputs like the EKS cluster endpoint, RDS endpoint, or security group IDs can be viewed using the `terragrunt output` command within the respective component directory (e.g., `cd live/dev/eks && terragrunt output`).

## Cleaning Up

To destroy the infrastructure for an environment, run `terragrunt destroy` within each component directory in the reverse order of creation (RDS, EKS, then VPC), or use `terragrunt run-all destroy` from the environment directory (`live/<environment>`).
