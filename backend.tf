terraform {
  backend "s3" {
    bucket  = "mlops-tfstate-9709-8254-3113" # TODO: replace with your unique bucket name
    key     = "global/eks-vpc-cluster.tfstate"
    region  = "eu-central-1"
    profile = "default" # adjust if you use a non-default AWS CLI profile
    encrypt = true
  }
}
