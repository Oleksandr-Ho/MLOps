terraform {
  backend "s3" {
    bucket  = "mlops-tfstate-9709-8254-3113" # за потреби замініть на власний бакет
    key     = "argocd/terraform.tfstate"
    region  = "eu-central-1"
    profile = "default"
    encrypt = true
  }
}
