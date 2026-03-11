# AWS VPC Module

This module creates a baseline VPC network in AWS with public and private subnets across multiple Availability Zones.

Current module version path: `modules/aws/vpc/1.0.0`

## What This Module Creates

- 1 VPC with DNS support and DNS hostnames enabled
- `az_count` public subnets (one per AZ)
- `az_count` private subnets (one per AZ)
- 1 Internet Gateway attached to the VPC
- 1 shared public route table with a default route (`0.0.0.0/0`) to the Internet Gateway
- 1 private route table per private subnet
- Route table associations for all public and private subnets

## Design Notes

- Availability Zones are discovered dynamically from the target region.
- Subnet CIDRs are calculated from `vpc_cidr` using `cidrsubnet`.
- Public subnets have `map_public_ip_on_launch = true`.
- Private route tables are created, but no NAT Gateway or outbound internet route is configured for private subnets in this version.
- The module enforces `az_count` to be either `2` or `3`.

## Usage

```hcl
module "vpc" {
  source = "./modules/aws/vpc/1.0.0"

  environment = "prod"
  name_prefix = "platform"
  vpc_cidr    = "10.10.0.0/16"
  az_count    = 2

  tags = {
    Owner       = "platform-team"
    CostCenter  = "shared-services"
    Terraform   = "true"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `environment` | Environment name (e.g. `prod`, `preprod`) | `string` | n/a | yes |
| `name_prefix` | Optional prefix for resource `Name` tags | `string` | `""` | no |
| `vpc_cidr` | CIDR block for the VPC | `string` | `"10.0.0.0/16"` | no |
| `az_count` | Number of AZs to spread subnets across (`2` or `3`) | `number` | `2` | no |
| `tags` | Common tags applied to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `vpc_id` | ID of the created VPC |
| `private_subnet_ids` | IDs of the private subnets |
| `public_subnet_ids` | IDs of the public subnets |
| `public_route_table_id` | ID of the public route table |
| `private_route_table_ids` | IDs of the private route tables |

## Resource Naming and Tags

Resources are named using:

- `<name_prefix>-<environment>-...` when `name_prefix` is set
- `<environment>-...` when `name_prefix` is empty

The module merges user-provided `tags` with:

- `Environment = var.environment`

If duplicate keys are provided, module-computed tag values take precedence for the same key.

## Prerequisites

- Terraform 1.x
- AWS provider configured in the root module
- AWS account/region with at least 2 available AZs

## Limitations (Current Version)

- No NAT Gateways are created
- No Network ACL or Security Group resources are created
- No IPv6 configuration is included
- No dedicated private subnet egress route is configured
