locals {
  remote_state_enabled = var.use_remote_state
}

data "terraform_remote_state" "vpc" {
  count   = local.remote_state_enabled ? 1 : 0
  backend = "s3"

  config = merge(
    {
      bucket = var.vpc_state_bucket
      key    = var.vpc_state_key
      region = coalesce(var.vpc_state_region, var.aws_region)
    },
    var.vpc_state_profile != null ? { profile = var.vpc_state_profile } : {}
  )
}
