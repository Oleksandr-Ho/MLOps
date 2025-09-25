output "vpc_id" {
  description = "The ID of the created VPC."
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block associated with the created VPC."
  value       = module.vpc.vpc_cidr_block
}

output "private_subnet_ids" {
  description = "IDs of private subnets."
  value       = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "IDs of public subnets."
  value       = module.vpc.public_subnets
}

output "private_subnet_arns" {
  description = "ARNs of private subnets."
  value       = module.vpc.private_subnet_arns
}

output "public_subnet_arns" {
  description = "ARNs of public subnets."
  value       = module.vpc.public_subnet_arns
}
