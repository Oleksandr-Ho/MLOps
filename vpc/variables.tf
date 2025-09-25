variable "name" {
  description = "Friendly name applied to the VPC and related resources."
  type        = string
}

variable "cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "azs" {
  description = "Availability zones to spread subnets across."
  type        = list(string)
}

variable "private_subnets" {
  description = "CIDR blocks for private subnets inside the VPC."
  type        = list(string)
}

variable "public_subnets" {
  description = "CIDR blocks for public subnets inside the VPC."
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Whether to provision managed NAT gateway(s)."
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Deploy a single NAT gateway for cost savings."
  type        = bool
  default     = true
}

variable "public_subnet_tags" {
  description = "Extra tags applied to public subnets."
  type        = map(string)
  default     = {}
}

variable "private_subnet_tags" {
  description = "Extra tags applied to private subnets."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Common tags applied to all supported resources."
  type        = map(string)
  default     = {}
}
