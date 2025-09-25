locals {
  vpc_outputs = var.use_remote_state ? try(data.terraform_remote_state.vpc[0].outputs, {}) : {}

  resolved_vpc_id = var.vpc_id != null ? var.vpc_id : try(local.vpc_outputs.vpc_id, null)

  resolved_private_subnet_ids = var.private_subnet_ids != null ? var.private_subnet_ids : try(local.vpc_outputs.private_subnet_ids, null)

  cluster_tags = merge({
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }, var.tags)

  configure_kubectl_command = "aws eks --region ${var.aws_region} update-kubeconfig --name ${var.cluster_name}"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.24.1"

  cluster_name                    = var.cluster_name
  cluster_version                 = var.cluster_version
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  cluster_enabled_log_types       = var.cluster_enabled_log_types

  vpc_id     = local.resolved_vpc_id
  subnet_ids = local.resolved_private_subnet_ids

  cluster_encryption_config = var.enable_cluster_encryption ? {
    resources = ["secrets"]
  } : {}

  enable_irsa                              = true
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    cpu = {
      instance_types = var.cpu_node_group_config.instance_types
      desired_size   = var.cpu_node_group_config.desired_size
      min_size       = var.cpu_node_group_config.min_size
      max_size       = var.cpu_node_group_config.max_size
      capacity_type  = var.cpu_node_group_config.capacity_type
    }

    gpu = {
      instance_types = var.gpu_node_group_config.instance_types
      desired_size   = var.gpu_node_group_config.desired_size
      min_size       = var.gpu_node_group_config.min_size
      max_size       = var.gpu_node_group_config.max_size
      capacity_type  = var.gpu_node_group_config.capacity_type
      labels         = var.gpu_node_group_config.labels
    }
  }

  tags = local.cluster_tags

  node_security_group_tags = {
    Name = "${var.cluster_name}-nodes-sg"
  }

  cloudwatch_log_group_retention_in_days = 30
}
