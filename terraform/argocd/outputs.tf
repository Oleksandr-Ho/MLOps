locals {
  # Сервіс ArgoCD для port-forward: <release>-argocd-server
  argocd_server_service = "${helm_release.argocd.name}-argocd-server"
}

output "argocd_namespace" {
  description = "Namespace, де розгорнуто ArgoCD."
  value       = kubernetes_namespace.argocd.metadata[0].name
}

output "argocd_server_service" {
  description = "Назва сервісу ArgoCD, який використовуємо для port-forward."
  value       = local.argocd_server_service
}

output "argocd_initial_admin_password_cmd" {
  description = "Команда для отримання початкового пароля адміністратора ArgoCD."
  value       = "kubectl -n ${kubernetes_namespace.argocd.metadata[0].name} get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d"
}
