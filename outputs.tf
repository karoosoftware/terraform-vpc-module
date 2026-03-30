output "vpc_id" {
  value = aws_vpc.this.id
}

output "private_subnet_ids" {
  value = [for s in aws_subnet.private : s.id]
}

output "public_subnet_ids" {
  value = [for s in aws_subnet.public : s.id]
}

output "public_route_table_id" {
  value = aws_route_table.public.id
}

output "private_route_table_ids" {
  value = [for rt in aws_route_table.private : rt.id]
}

output "endpoint_security_group_id" {
  description = "ID of the shared security group attached to VPC interface endpoints."
  value       = var.create_interface_endpoints ? aws_security_group.endpoints[0].id : null
}

output "endpoint_security_group_name" {
  description = "Name of the shared security group attached to VPC interface endpoints."
  value       = var.create_interface_endpoints ? aws_security_group.endpoints[0].name : null
}

output "interface_vpc_endpoint_ids" {
  description = "IDs of the shared interface VPC endpoints."
  value       = { for name, endpoint in aws_vpc_endpoint.interface : name => endpoint.id }
}

output "s3_gateway_vpc_endpoint_id" {
  description = "ID of the shared S3 gateway VPC endpoint."
  value       = var.create_s3_gateway_endpoint ? aws_vpc_endpoint.s3[0].id : null
}