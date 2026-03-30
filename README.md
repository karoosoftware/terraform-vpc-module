# AWS VPC Module

This module creates a baseline AWS VPC with public and private subnets across multiple Availability Zones, with optional shared VPC endpoints for private AWS service access.

## What This Module Creates

- 1 VPC with DNS support and DNS hostnames enabled
- `az_count` public subnets
- `az_count` private subnets
- 1 Internet Gateway
- 1 shared public route table with a default route to the Internet Gateway
- 1 private route table per private subnet
- Route table associations for all public and private subnets
- Optional shared security group for interface VPC endpoints
- Optional interface VPC endpoints for ECR API, ECR DKR, and CloudWatch Logs
- Optional S3 gateway VPC endpoint for private subnet route tables

## Usage

```hcl
module "vpc" {
  source = "git::ssh://git@github.com:karoosoftware/terraform-vpc-module.git?ref=<commit-sha>"

  environment = "prod"
  name_prefix = "platform"
  vpc_cidr    = "10.10.0.0/16"
  az_count    = 2

  create_interface_endpoints      = true
  create_s3_gateway_endpoint      = true
  endpoint_security_group_name    = "platform-prod-vpc-endpoints"
  endpoint_allowed_security_group_ids = [
    "sg-0123456789abcdef0"
  ]

  tags = {
    Owner      = "platform-team"
    CostCenter = "shared-services"
    Terraform  = "true"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `environment` | Environment name (e.g. `prod`, `preprod`) | `string` | n/a | yes |
| `name_prefix` | Optional prefix used for resource `Name` tags (e.g. `platform`) | `string` | `""` | no |
| `vpc_cidr` | CIDR block for the VPC | `string` | `"10.0.0.0/16"` | no |
| `az_count` | How many AZs to spread subnets across (`2` or `3`) | `number` | `2` | no |
| `create_interface_endpoints` | Whether to create shared interface VPC endpoints for private AWS service access | `bool` | `false` | no |
| `create_s3_gateway_endpoint` | Whether to create the shared S3 gateway VPC endpoint | `bool` | `false` | no |
| `endpoint_security_group_name` | Name of the shared security group attached to VPC interface endpoints | `string` | `null` | no |
| `endpoint_allowed_security_group_ids` | Security group IDs allowed to connect to the interface endpoints over HTTPS | `list(string)` | `[]` | no |
| `tags` | Common tags applied to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `vpc_id` | ID of the created VPC |
| `private_subnet_ids` | IDs of the private subnets |
| `public_subnet_ids` | IDs of the public subnets |
| `public_route_table_id` | ID of the public route table |
| `private_route_table_ids` | IDs of the private route tables |
| `endpoint_security_group_id` | ID of the shared security group attached to VPC interface endpoints |
| `endpoint_security_group_name` | Name of the shared security group attached to VPC interface endpoints |
| `interface_vpc_endpoint_ids` | IDs of the shared interface VPC endpoints keyed by service |
| `s3_gateway_vpc_endpoint_id` | ID of the shared S3 gateway VPC endpoint |

## Notes

- Availability Zones are discovered dynamically from the target region.
- Subnet CIDRs are calculated from `vpc_cidr` using `cidrsubnet`.
- Public subnets enable `map_public_ip_on_launch`.
- Private route tables are created without NAT Gateway egress in this version.
- Interface endpoint creation is controlled by `create_interface_endpoints`.
- S3 gateway endpoint creation is controlled by `create_s3_gateway_endpoint`.
- When interface endpoints are enabled, the module creates shared endpoints for ECR API, ECR DKR, and CloudWatch Logs.

## Release Process

- Update the root `VERSION` file in the same change that should be released, using semantic versioning such as `1.0.1`, `1.1.0`, or `2.0.0`.
- Push the change to `develop` and let the `terraform-validate` workflow pass.
- Open a pull request from `develop` to `main` and let the `terraform-validate` workflow pass again.
- Merge the pull request to `main`.
- Pushing to `main` triggers the automated release workflow, which:
  - reads `VERSION`,
  - checks that tag `v<VERSION>` does not already exist,
  - creates and pushes the tag,
  - creates the GitHub release automatically.
- If `VERSION` has not been updated and the tag already exists, validation and release will fail.
- Consume released versions from other Terraform repos by pinning the module source with the released tag, for example:

```bash
source = "git::ssh://git@github.com:karoosoftware/terraform-vpc-module.git?ref=v1.0.0"
```

## Prerequisites

- Terraform 1.x
- AWS provider configured in the root module
- AWS account/region with at least 2 available Availability Zones
