variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster."
  type        = string
  default     = "1.29"
}

variable "vpc_id" {
  description = "ID of the VPC that hosts the EKS cluster."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.use_remote_state || var.vpc_id != null
    error_message = "Provide vpc_id when use_remote_state is false."
  }
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs where the EKS worker nodes will run."
  type        = list(string)
  default     = null
  nullable    = true

  validation {
    condition     = var.use_remote_state || var.private_subnet_ids != null
    error_message = "Provide private_subnet_ids when use_remote_state is false."
  }
}

variable "cluster_enabled_log_types" {
  description = "EKS control plane logs to enable."
  type        = list(string)
  default     = []
}

variable "enable_cluster_encryption" {
  description = "Enable encryption of Kubernetes secrets using AWS KMS."
  type        = bool
  default     = true
}

variable "cpu_node_group_config" {
  description = "Configuration for the primary CPU node group."
  type = object({
    instance_types = list(string)
    desired_size   = number
    min_size       = number
    max_size       = number
    capacity_type  = string
  })
}

variable "gpu_node_group_config" {
  description = "Configuration for the optional GPU (or placeholder) node group."
  type = object({
    instance_types = list(string)
    desired_size   = number
    min_size       = number
    max_size       = number
    capacity_type  = string
    labels         = map(string)
  })
}

variable "tags" {
  description = "Tags to propagate to supported AWS resources."
  type        = map(string)
  default     = {}
}

variable "aws_region" {
  description = "AWS region used for the EKS deployment (re-used for remote state)."
  type        = string
}

variable "use_remote_state" {
  description = "Whether to resolve VPC inputs via terraform_remote_state instead of direct variables."
  type        = bool
  default     = false
}

variable "vpc_state_bucket" {
  description = "S3 bucket that stores the VPC Terraform state file. Required when use_remote_state is true."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = !var.use_remote_state || (var.vpc_state_bucket != null && length(trim(var.vpc_state_bucket)) > 0)
    error_message = "vpc_state_bucket must be specified when use_remote_state is true."
  }
}

variable "vpc_state_key" {
  description = "Key of the VPC Terraform state file. Required when use_remote_state is true."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = !var.use_remote_state || (var.vpc_state_key != null && length(trim(var.vpc_state_key)) > 0)
    error_message = "vpc_state_key must be specified when use_remote_state is true."
  }
}

variable "vpc_state_region" {
  description = "Region where the VPC Terraform state bucket resides."
  type        = string
  default     = null
  nullable    = true
}

variable "vpc_state_profile" {
  description = "Optional AWS profile used to access the remote VPC state."
  type        = string
  default     = null
  nullable    = true
}
