variable "environment" {
  type        = string
  description = "Environment name (e.g. prod, preprod)"
}

variable "name_prefix" {
  type        = string
  description = "Optional prefix used for resource Name tags (e.g. platform). Leave empty to use only environment."
  default     = ""
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "az_count" {
  type        = number
  description = "How many AZs to spread subnets across"
  default     = 2
  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "az_count must be 2 or 3."
  }
}

variable "tags" {
  type        = map(string)
  description = "Common tags applied to resources"
  default     = {}
}

variable "create_interface_endpoints" {
  description = "Whether to create shared interface VPC endpoints for private AWS service access."
  type        = bool
  default     = false
}

variable "create_s3_gateway_endpoint" {
  description = "Whether to create the shared S3 gateway VPC endpoint."
  type        = bool
  default     = false
}

variable "endpoint_security_group_name" {
  description = "Name of the shared security group attached to VPC interface endpoints."
  type        = string
  default     = null

  validation {
    condition     = !var.create_interface_endpoints || var.endpoint_security_group_name != null
    error_message = "endpoint_security_group_name must be set when create_interface_endpoints is true."
  }
}

variable "endpoint_allowed_security_group_ids" {
  description = "Security group IDs allowed to connect to the interface endpoints over HTTPS."
  type        = list(string)
  default     = []
}