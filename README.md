# Інфраструктура Terraform VPC + EKS

Цей репозиторій містить конфігурацію Terraform, яка розгортає фундамент AWS, готовий до продакшну, для майбутніх ML-навантажень:

- Окрема VPC з публічними та приватними підмережами у трьох зонах доступності.
- Керований кластер EKS із двома групами вузлів (основна CPU-група та GPU-заглушка), побудованими поверх цієї VPC.
- Віддалений стан у S3, щоб ви могли повторно використовувати інфраструктуру в наступних завданнях.

> **Регіон:** конфігурація орієнтована на `eu-central-1` (Франкфурт).

## Структура репозиторію

```
.
├── backend.tf               # Налаштування віддаленого state (S3) для всієї інфраструктури
├── main.tf                  # Кореневий модуль, що з’єднує VPC та EKS
├── variables.tf             # Вхідні змінні з типовими значеннями
├── outputs.tf               # Узагальнені вихідні дані для повторного використання
├── terraform.tf             # Потрібні провайдери та типові теги AWS
├── vpc/                     # Обгортка над модулем terraform-aws-modules/vpc
│   ├── backend.tf           # Документує очікування щодо backend (керується з кореня)
│   ├── main.tf              # Визначення VPC (підмережі, маршрути, NAT)
│   ├── outputs.tf           # Вихідні дані VPC для кореневого модуля
│   ├── terraform.tf         # Вимоги для модуля
│   └── variables.tf         # Параметри, специфічні для VPC
├── eks/                     # Модуль EKS, що керує Kubernetes-кластером
│   ├── backend.tf
│   ├── data.tf              # Додаткове підключення через terraform_remote_state
│   ├── main.tf              # Контроль plane EKS, шифрування секретів та групи вузлів
│   ├── outputs.tf           # Вихідні дані кластера для кореня
│   ├── terraform.tf
│   └── variables.tf
├── terraform/argocd/        # Окремий Terraform-проєкт для встановлення ArgoCD
│   ├── backend.tf
│   ├── main.tf              # namespace + Helm-реліз ArgoCD
│   ├── outputs.tf           # Корисні команди (port-forward, пароль)
│   ├── provider.tf          # Налаштування aws/kubernetes/helm
│   ├── terraform.tf
│   ├── variables.tf
│   └── values/
│       └── argocd-values.yaml
├── goit-argo/               # Шаблон GitOps-репозиторію для MLflow
│   ├── application.yaml
│   ├── namespaces/
│   └── values/
└── README.md
```

## Попередні вимоги

1. **Terraform 1.3+** (перевірено на 1.13.3).
2. **AWS CLI v2** з налаштованими обліковими даними для `eu-central-1`.
3. **kubectl** для взаємодії з кластером EKS після розгортання.
4. **S3-бакет для віддаленого стану Terraform.** Створіть унікальну назву бакета та використовуйте її в наступних домашніх завданнях, щоб мати доступ до стану та вихідних даних.

Приклад створення бакета:

```bash
aws s3api create-bucket \
  --bucket mlops-tfstate-9709-8254-3113 \
  --region eu-central-1 \
  --create-bucket-configuration LocationConstraint=eu-central-1
```

> Замініть `mlops-tfstate-9709-8254-3113` на власну унікальну назву.

## Налаштування

1. Відредагуйте `backend.tf` і замініть значення `bucket` на назву свого S3-бакета. Якщо ви використовуєте `terraform.tfvars`, залиште ту саму назву в `variables.tf`.
2. (Необов’язково) Якщо ви працюєте через AWS CLI-профіль, відмінний від `default`, змініть `aws_profile` у `variables.tf` або передайте через CLI (`-var aws_profile=...`).
3. Корегуйте CIDR, розміри груп вузлів або теги лише за потреби. Типові значення підібрані так, щоб укладатися у Free Tier AWS: CPU-група запускає один вузол `t3.small`, GPU-заглушка має `desired_size = 0` (вузли не створюються, доки ви вручну не збільшите значення).

## Використання

```bash
# Ініціалізуємо провайдери та завантажуємо модулі
terraform init

# Переглядаємо план змін
terraform plan

# Розгортаємо VPC та EKS (EKS може створюватися 15–20 хвилин)
terraform apply
```

Після завершення `apply` налаштуйте `kubectl` за допомогою підказки з виводу (доступ до кластера автоматично надається користувачу/профілю, який запускав Terraform):

```bash
terraform output -raw eks_kubeconfig_command
# Приклад:
# aws eks --region eu-central-1 update-kubeconfig --name mlops-cluster
```

Перевірте стан кластера:

```bash
kubectl get nodes
```

Очікуємо побачити один вузол зі статусом `Ready`, створений CPU-групою. GPU-заглушка тримає `desired_size = 0`, щоб уникати зайвих витрат. Коли AWS відкриє доступ до GPU-типів, можна змінити `instance_types` і `desired_size` та повторно виконати `terraform apply`.

## Розгортання ArgoCD через Terraform

Додатковий модуль (`terraform/argocd`) встановлює ArgoCD у вже створений EKS-кластер.

```bash
cd terraform/argocd
terraform init                     # підвантажує провайдери та модулі
terraform plan \
  -var aws_profile=default         # за потреби вкажіть інший профіль
terraform apply
```

Основні налаштування знаходяться у файлі `values/argocd-values.yaml`. Тут сервіс працює як `ClusterIP`, увімкнено auto-sync параметри та зменшено запити ресурсів, щоб залишатися у межах Free Tier.

Після завершення застосування Terraform ви отримаєте готові підказки у `terraform output`:

```bash
terraform output
```

Вивід містить namespace ArgoCD, назву сервісу для port-forward та готову команду для отримання початкового пароля адміністратора.

## Доступ до ArgoCD UI

1. Отримайте пароль:
   ```bash
   terraform output -raw argocd_initial_admin_password_cmd | bash
   ```
   або скористайтеся командою з попереднього пункту вручну.
2. Запустіть port-forward:
   ```bash
   kubectl port-forward svc/argocd-argocd-server -n infra-tools 8080:443
   ```
3. Відкрийте веб-інтерфейс на <https://localhost:8080> та увійдіть під користувачем `admin`.

> Якщо ви змінили назву Helm-релізу або namespace, підкоригуйте команду port-forward згідно з `terraform output`.

## GitOps-деплой MLflow

1. Створіть окремий публічний репозиторій на GitHub (наприклад, `https://github.com/Oleksandr-Ho/goit-argo`).
2. Скопіюйте вміст каталогу `goit-argo/` у цей репозиторій і запуште в гілку `main`.
3. Файл `application.yaml` уже вказує на вендорний Helm-чарт (розміщений у папці `charts/mlflow`) і містить налаштування auto-sync/self-heal.
4. Після git push ArgoCD автоматично підхопить файл і розгорне MLflow у namespace `mlflow` (чарт використовує базовий образ `python:3.10-slim`, який під час старту встановлює `mlflow==2.9.2`).

Перевірити стан можна командами:

```bash
kubectl get applications -n infra-tools
kubectl get pods -n mlflow
kubectl get svc -n mlflow
```

Для доступу до інтерфейсу MLflow виконайте port-forward:

```bash
kubectl port-forward deployment/mlflow-tracking -n mlflow 5000:5000
```

Після цього UI буде доступний на <http://localhost:5000>. (За потреби можна виконати `kubectl patch svc mlflow-tracking -n mlflow -p '{"spec":{"type":"ClusterIP"}}'`, щоб прибрати автоматично створений LoadBalancer і уникнути зайвих витрат.)

## Посилання на GitOps-репозиторій

- Репозиторій із Application: `https://github.com/Oleksandr-Ho/goit-argo`
- Маніфест `application.yaml` і namespaces знаходяться безпосередньо у корені цього репозиторію.

## Lesson 8 — Моніторинг експериментів

Додані маніфести для GitOps та робочий скрипт `train_and_push.py`, що реалізує вимоги ДЗ8 з трекінгу експериментів. Уся логіка зібрана в каталозі `mlops-experiments/`.

### GitOps-застосунки ArgoCD
- `mlops-experiments/argocd/applications/*.yaml` — чотири `Application`, що підтягують MinIO, PostgreSQL, PushGateway та MLflow (остання вказує на цей же Git-репозиторій).
- Щоб активувати синхронізацію:
  ```bash
  kubectl apply -n infra-tools -f mlops-experiments/argocd/applications/minio.yaml
  kubectl apply -n infra-tools -f mlops-experiments/argocd/applications/postgres.yaml
  kubectl apply -n infra-tools -f mlops-experiments/argocd/applications/mlflow.yaml
  kubectl apply -n infra-tools -f mlops-experiments/argocd/applications/pushgateway.yaml
  ```
- Перевірте статуси через `kubectl get applications -n infra-tools`, а також `kubectl get pods -n mlflow` та `kubectl get pods -n monitoring`.
- Якщо репозиторій або гілка відрізняються, відкоригуйте `repoURL` та `targetRevision` у `mlflow.yaml` перед застосуванням.

### Port-forward для сервісів
- MLflow: `kubectl port-forward svc/mlflow-tracking -n mlflow 5000:5000`
- PushGateway: `kubectl port-forward svc/pushgateway -n monitoring 9091:9091`
- Grafana (якщо встановлена kube-prometheus-stack): `kubectl port-forward svc/prometheus-operator-grafana -n monitoring 3000:80`

### Скрипт експериментів
- Каталог `mlops-experiments/experiments/` містить `requirements.txt` та `train_and_push.py` з коментарями українською.
- Приклад запуску:
  ```bash
  cd mlops-experiments/experiments
  python3 -m venv .venv
  source .venv/bin/activate
  pip install -r requirements.txt
  python train_and_push.py \
    --tracking-uri http://localhost:5000 \
    --pushgateway-url http://localhost:9091
  ```
- Скрипт автоматично логує параметри та метрики в MLflow, пушить `mlflow_accuracy` і `mlflow_loss` у PushGateway та копіює артефакти найкращого запуску у `mlops-experiments/best_model/<run_id>/`.

### Перевірка метрик у Grafana
- Після порт-форварду Grafana відкрийте <http://localhost:3000> і зайдіть до **Explore → Prometheus**.
- Запити `mlflow_accuracy` та `mlflow_loss` покажуть метрики для всіх `run_id`.

### Скріншоти
- ![MLflow UI](docs/screenshots/mlflow-ui.png)
- ![Grafana Explore](docs/screenshots/grafana-explore.png)

> Скріншоти в каталозі `docs/screenshots/` є заглушками — замініть їх реальними зображеннями після перевірки вашого деплою.


## Повторне використання стану в наступних завданнях

Усі вихідні дані зберігаються у віддаленому стані (`global/eks-vpc-cluster.tfstate`). Інші конфігурації Terraform можуть підключитися до них через `terraform_remote_state`:

```hcl
data "terraform_remote_state" "foundation" {
  backend = "s3"
  config = {
    bucket = "<ваш-унікальний-бакет>"
    key    = "global/eks-vpc-cluster.tfstate"
    region = "eu-central-1"
  }
}

locals {
  eks_cluster_name = data.terraform_remote_state.foundation.outputs.eks_cluster_name
  vpc_id           = data.terraform_remote_state.foundation.outputs.vpc_id
}
```

## Очистка

Після тестування залиште S3-бакет (у ньому зберігається стан), але видаліть усі інші ресурси, щоб уникнути витрат:

```bash
terraform destroy
```

## Примітки

- NAT Gateway увімкнений за замовчуванням із одним екземпляром для балансу між функціональністю та витратами. Якщо хочете залишитися лише з публічними підмережами, встановіть `enable_nat_gateway = false`.
- Підтримка віддаленого state закладена в модуль EKS (`use_remote_state = true`) на випадок, якщо ви захочете запускати `vpc/` та `eks/` як окремі конфігурації.
