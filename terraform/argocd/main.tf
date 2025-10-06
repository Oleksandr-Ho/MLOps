# Створюємо namespace для ArgoCD, якщо він ще не існує.
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.argocd_namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

# Встановлюємо ArgoCD через офіційний Helm-чарт.
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_chart_version
  namespace        = kubernetes_namespace.argocd.metadata[0].name
  create_namespace = false
  timeout          = var.helm_release_timeout

  # Передаємо власні налаштування сервісу з окремого файлу.
  values = [file("${path.module}/values/argocd-values.yaml")]

  # Підказуємо Terraform, що ArgoCD треба оновлювати автоматично при зміні values.
  atomic          = true
  cleanup_on_fail = true

  depends_on = [kubernetes_namespace.argocd]

  lifecycle {
    precondition {
      condition     = local.cluster_name != null
      error_message = "Не вдалося зчитати назву EKS-кластера зі state-файла. Перевірте параметри cluster_state_bucket/key."
    }
  }
}
