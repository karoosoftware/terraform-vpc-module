data "aws_availability_zones" "available" {
  state = "available"
}
data "aws_region" "current" {}

locals {
  # Gets the full list of vailable AZ in the region - example: ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  private_subnet_cidrs = {
    for idx, az in local.azs : az => cidrsubnet(var.vpc_cidr, 4, idx)
  }

  public_subnet_cidrs = {
    for idx, az in local.azs : az => cidrsubnet(var.vpc_cidr, 4, idx + var.az_count)
  }

  base_tags = merge(var.tags, {
    Environment = var.environment
  })

  resource_name_prefix = trimspace(var.name_prefix) != "" ? "${trimspace(var.name_prefix)}-${var.environment}" : var.environment
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.base_tags, {
    Name = "${local.resource_name_prefix}-vpc"
  })
}

resource "aws_subnet" "private" {
  for_each = local.private_subnet_cidrs

  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = each.value

  tags = merge(local.base_tags, {
    Name = "${local.resource_name_prefix}-private-${each.key}"
    Tier = "private"
  })
}

resource "aws_subnet" "public" {
  for_each = local.public_subnet_cidrs

  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.key
  cidr_block              = each.value
  map_public_ip_on_launch = true

  tags = merge(local.base_tags, {
    Name = "${local.resource_name_prefix}-public-${each.key}"
    Tier = "public"
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.base_tags, {
    Name = "${local.resource_name_prefix}-igw"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(local.base_tags, {
    Name = "${local.resource_name_prefix}-public-rt"
    Tier = "public"
  })
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  for_each = aws_subnet.private

  vpc_id = aws_vpc.this.id

  tags = merge(local.base_tags, {
    Name = "${local.resource_name_prefix}-private-rt-${each.key}"
    Tier = "private"
  })
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

resource "aws_security_group" "endpoints" {
  count = var.create_interface_endpoints ? 1 : 0

  name        = var.endpoint_security_group_name
  description = "Security group for shared VPC interface endpoints."
  vpc_id      = aws_vpc.this.id

  egress {
    description = "Allow all outbound traffic."
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.base_tags, {
    Name = var.endpoint_security_group_name
  })
}

resource "aws_vpc_security_group_ingress_rule" "endpoint_https" {
  for_each = var.create_interface_endpoints ? toset(var.endpoint_allowed_security_group_ids) : toset([])

  security_group_id            = aws_security_group.endpoints[0].id
  referenced_security_group_id = each.value
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  description                  = "Allow HTTPS from approved workload security groups."
}

resource "aws_vpc_endpoint" "interface" {
  for_each = var.create_interface_endpoints ? {
    ecr_api = "com.amazonaws.${data.aws_region.current.region}.ecr.api"
    ecr_dkr = "com.amazonaws.${data.aws_region.current.region}.ecr.dkr"
    logs    = "com.amazonaws.${data.aws_region.current.region}.logs"
    ses     = "com.amazonaws.${data.aws_region.current.region}.email"
  } : {}

  vpc_id              = aws_vpc.this.id
  service_name        = each.value
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for subnet in aws_subnet.private : subnet.id]
  security_group_ids  = [aws_security_group.endpoints[0].id]
  private_dns_enabled = true

  tags = merge(local.base_tags, {
    Name = "${local.resource_name_prefix}-${each.key}-vpce"
  })
}

resource "aws_vpc_endpoint" "s3" {
  count = var.create_s3_gateway_endpoint ? 1 : 0

  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [for rt in aws_route_table.private : rt.id]

  tags = merge(local.base_tags, {
    Name = "${local.resource_name_prefix}-s3-vpce"
  })
}