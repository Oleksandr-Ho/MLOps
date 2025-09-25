module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.3"

  name = var.name
  cidr = var.cidr

  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_ipv6                   = false
  enable_nat_gateway            = var.enable_nat_gateway
  single_nat_gateway            = var.single_nat_gateway
  enable_dns_hostnames          = true
  enable_dns_support            = true
  manage_default_security_group = true
  manage_default_network_acl    = true
  manage_default_route_table    = true
  create_igw                    = true
  one_nat_gateway_per_az        = !var.single_nat_gateway
  map_public_ip_on_launch       = true
  private_subnet_tags           = var.private_subnet_tags
  public_subnet_tags            = var.public_subnet_tags

  tags = var.tags
}
