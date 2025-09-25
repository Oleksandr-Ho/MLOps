output "vpc_id" {
  description = "Identifier of the provisioned VPC."
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Identifiers of private subnets used by the EKS node groups."
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Identifiers of public subnets for load balancers and ingress."
  value       = module.vpc.public_subnet_ids
}

output "eks_cluster_name" {
  description = "Name of the created EKS cluster."
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Endpoint URL for the EKS control plane."
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_security_group_id" {
  description = "Security group ID associated with the EKS control plane."
  value       = module.eks.cluster_security_group_id
}

output "eks_kubeconfig_command" {
  description = "Helper command to update kubeconfig for this cluster."
  value       = module.eks.configure_kubectl
}

output "eks_managed_node_groups" {
  description = "Details about the managed node groups defined in this deployment."
  value       = module.eks.managed_node_groups
}
