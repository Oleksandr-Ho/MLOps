output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for the Kubernetes API server."
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group attached to the EKS control plane."
  value       = module.eks.cluster_security_group_id
}

output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL for the EKS cluster."
  value       = module.eks.cluster_oidc_issuer_url
}

output "cluster_oidc_provider_arn" {
  description = "ARN of the IAM OIDC provider associated with the EKS cluster."
  value       = module.eks.oidc_provider_arn
}

output "configure_kubectl" {
  description = "Helper command to set up kubectl for this cluster."
  value       = local.configure_kubectl_command
}

output "managed_node_groups" {
  description = "Details of the EKS managed node groups."
  value       = module.eks.eks_managed_node_groups
}
