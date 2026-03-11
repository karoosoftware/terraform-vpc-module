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
