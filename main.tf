data "aws_availability_zones" "available" {
  state = "available"
}

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
