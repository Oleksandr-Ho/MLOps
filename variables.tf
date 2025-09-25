variable "aws_region" {
  description = "AWS region where the infrastructure will be created."
  type        = string
  default     = "eu-central-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to use for authentication."
  type        = string
  default     = "default"
}

variable "cluster_name" {
  description = "Name of the EKS cluster and related resources."
  type        = string
  default     = "mlops-cluster"
}

variable "eks_version" {
  description = "Kubernetes version for the EKS control plane."
  type        = string
  default     = "1.29"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones to use for subnets."
  type        = list(string)
  default     = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
}

variable "private_subnets" {
  description = "CIDR blocks for private subnets."
  type        = list(string)
  default = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24",
  ]
}

variable "public_subnets" {
  description = "CIDR blocks for public subnets."
  type        = list(string)
  default = [
    "10.0.101.0/24",
    "10.0.102.0/24",
    "10.0.103.0/24",
  ]
}

variable "enable_nat_gateway" {
  description = "Whether to create a managed NAT gateway for private subnets."
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Deploy a single NAT gateway to reduce costs."
  type        = bool
  default     = true
}

variable "additional_tags" {
  description = "Extra tags applied to all supported resources."
  type        = map(string)
  default = {
    Owner = "Oleksandr-Ho"
  }
}

variable "cpu_node_group" {
  description = "Configuration for the default CPU-managed node group."
  type = object({
    instance_types = list(string)
    desired_size   = number
    min_size       = number
    max_size       = number
    capacity_type  = string
  })
  default = {
    instance_types = ["t3.small"]
    desired_size   = 1 # можна зменшити до 1 вузла, щоб мінімізувати витрати
    min_size       = 1
    max_size       = 2
    capacity_type  = "ON_DEMAND"
  }
}

variable "gpu_node_group" {
  description = "Configuration for the optional GPU (or placeholder) node group."
  type = object({
    instance_types = list(string)
    desired_size   = number
    min_size       = number
    max_size       = number
    capacity_type  = string
    labels         = map(string)
  })
  default = {
    instance_types = ["t3.small"]
    desired_size   = 0
    min_size       = 0
    max_size       = 2
    capacity_type  = "ON_DEMAND"
    labels = {
      "node-type" = "gpu-placeholder"
    }
  }
}

variable "eks_cluster_log_types" {
  description = "EKS control plane log types to enable."
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "enable_cluster_encryption" {
  description = "Enable envelope encryption for Kubernetes secrets using AWS KMS."
  type        = bool
  default     = true
}
