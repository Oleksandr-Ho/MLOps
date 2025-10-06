# Провайдер AWS використовується для зчитування даних про EKS-кластер та автентифікації.
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

# Завантажуємо стейт з попереднього ДЗ, щоб отримати параметри EKS-кластера.
data "terraform_remote_state" "foundation" {
  backend = "s3"
  config = {
    bucket  = var.cluster_state_bucket
    key     = var.cluster_state_key
    region  = var.aws_region
    profile = var.aws_profile
  }
}

locals {
  # Назва кластера та endpoint передаються через outputs попереднього модуля.
  cluster_name     = try(data.terraform_remote_state.foundation.outputs.eks_cluster_name, null)
  cluster_endpoint = try(data.terraform_remote_state.foundation.outputs.eks_cluster_endpoint, null)
}

# Підвантажуємо сертифікат та токен доступу до EKS через AWS API.
data "aws_eks_cluster" "selected" {
  name = local.cluster_name
}

data "aws_eks_cluster_auth" "selected" {
  name = local.cluster_name
}

# Конфігурація Kubernetes-провайдера для застосування ресурсів безпосередньо в кластері.
provider "kubernetes" {
  host                   = local.cluster_endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.selected.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.selected.token
}

# Helm-провайдер використовує ті самі параметри, що й kubernetes.
provider "helm" {
  kubernetes {
    host                   = local.cluster_endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.selected.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.selected.token
  }
}
