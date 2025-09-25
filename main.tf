locals {
  cluster_shared_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  public_subnet_tags = merge(local.cluster_shared_tags, {
    "kubernetes.io/role/elb" = "1"
  })

  private_subnet_tags = merge(local.cluster_shared_tags, {
    "kubernetes.io/role/internal-elb" = "1"
  })
}

module "vpc" {
  source = "./vpc"

  name                = "${var.cluster_name}-vpc"
  cidr                = var.vpc_cidr
  azs                 = var.availability_zones
  private_subnets     = var.private_subnets
  public_subnets      = var.public_subnets
  enable_nat_gateway  = var.enable_nat_gateway
  single_nat_gateway  = var.single_nat_gateway
  public_subnet_tags  = local.public_subnet_tags
  private_subnet_tags = local.private_subnet_tags
  tags                = var.additional_tags
}

module "eks" {
  source = "./eks"

  cluster_name              = var.cluster_name
  cluster_version           = var.eks_version
  vpc_id                    = module.vpc.vpc_id
  private_subnet_ids        = module.vpc.private_subnet_ids
  cpu_node_group_config     = var.cpu_node_group
  gpu_node_group_config     = var.gpu_node_group
  cluster_enabled_log_types = var.eks_cluster_log_types
  enable_cluster_encryption = var.enable_cluster_encryption
  aws_region                = var.aws_region
  tags                      = var.additional_tags
  use_remote_state          = false
}
