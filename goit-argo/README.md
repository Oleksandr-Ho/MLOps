# GitOps-репозиторій для ArgoCD

Цей каталог слугує шаблоном репозиторію, який потрібно створити окремо (наприклад, `https://github.com/Oleksandr-Ho/goit-argo`).
Саме на цей репозиторій посилається ArgoCD Application з домашнього завдання №7.

## Структура

```
.
├── application.yaml                # Опис деплою MLflow через вендорний Helm-чарт
├── charts/
│   └── mlflow/                     # Розпакований чарт (версія 0.1.4) із внесеними правками
├── namespaces/
│   ├── application
│   │   ├── mlflow-config.yaml      # Демонстраційний ресурс у namespace застосунку
│   │   └── ns.yaml                 # Namespace mlflow
│   └── infra-tools
│       └── ns.yaml                 # Namespace для сервісів на кшталт ArgoCD
└── values/
    └── mlflow-values.yaml          # Додаткові приклади значень (не використовується напряму)
```

## Як використати

1. Створіть на GitHub новий публічний репозиторій `goit-argo` і запуште туди вміст цього каталогу (гілка `main`).
2. Переконайтеся, що у файлі `application.yaml` вказаний саме ваш URL Git-репозиторію.
3. Після `git push` ArgoCD автоматично підхопить Application і розгорне MLflow у namespace `mlflow`.

## Перевірка деплою

```bash
kubectl get applications -n infra-tools
kubectl get pods -n mlflow
```

## Доступ до MLflow UI

Оскільки сервіс працює всередині кластера, використовуйте port-forward на Deployment (або Pod):

```bash
kubectl port-forward deployment/mlflow-tracking -n mlflow 5000:5000
```

Після цього інтерфейс буде доступний за адресою <http://localhost:5000>.

> Після завершення тестів за бажанням можна змінити сервіс `mlflow-tracking` на `ClusterIP`, щоб уникнути зайвих витрат у AWS (наприклад: `kubectl patch svc mlflow-tracking -n mlflow -p '{"spec":{"type":"ClusterIP"}}'`).
