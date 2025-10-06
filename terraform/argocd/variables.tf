variable "aws_region" {
  description = "AWS-регіон, у якому працює EKS-кластер."
  type        = string
  default     = "eu-central-1"
}

variable "aws_profile" {
  description = "Назва AWS CLI профілю для автентифікації."
  type        = string
  default     = "default"
}

variable "cluster_state_bucket" {
  description = "S3-бакет, де зберігається стан Terraform з інфраструктурою кластера."
  type        = string
  default     = "mlops-tfstate-9709-8254-3113"
}

variable "cluster_state_key" {
  description = "Ключ (шлях) до state-файла з описом кластера."
  type        = string
  default     = "global/eks-vpc-cluster.tfstate"
}

variable "argocd_namespace" {
  description = "Namespace, у якому буде розгорнуто ArgoCD."
  type        = string
  default     = "infra-tools"
}

variable "argocd_chart_version" {
  description = "Версія Helm-чарту ArgoCD."
  type        = string
  default     = "6.7.12"
}

variable "helm_release_timeout" {
  description = "Час очікування (у секундах) на встановлення Helm-релізу."
  type        = number
  default     = 600
}
