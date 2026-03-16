# AWS VPC Module

This module creates a baseline AWS VPC with public and private subnets across multiple Availability Zones.

## What This Module Creates

- 1 VPC with DNS support and DNS hostnames enabled
- `az_count` public subnets
- `az_count` private subnets
- 1 Internet Gateway
- 1 shared public route table with a default route to the Internet Gateway
- 1 private route table per private subnet
- Route table associations for all public and private subnets

## Usage

```hcl
module "vpc" {
  source = "git::ssh://git@github.com:karoosoftware/terraform-vpc-module.git?ref=<commit-sha>"

  environment = "prod"
  name_prefix = "platform"
  vpc_cidr    = "10.10.0.0/16"
  az_count    = 2

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
| `tags` | Common tags applied to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `vpc_id` | ID of the created VPC |
| `private_subnet_ids` | IDs of the private subnets |
| `public_subnet_ids` | IDs of the public subnets |
| `public_route_table_id` | ID of the public route table |
| `private_route_table_ids` | IDs of the private route tables |

## Notes

- Availability Zones are discovered dynamically from the target region.
- Subnet CIDRs are calculated from `vpc_cidr` using `cidrsubnet`.
- Public subnets enable `map_public_ip_on_launch`.
- Private route tables are created without NAT Gateway egress in this version.

## Release Process

- Open a pull request and let the Terraform validation workflow pass.
- Merge the change to `main`.
- Create and push a version tag, for example:

```bash
git tag v1.0.0
git push origin v1.0.0
```

- Pushing the tag triggers the release workflow and creates the GitHub release.
- Consume released versions from other Terraform repos by pinning the module source with `?ref=v1.0.0`.

## Prerequisites

- Terraform 1.x
- AWS provider configured in the root module
- AWS account/region with at least 2 available Availability Zones
