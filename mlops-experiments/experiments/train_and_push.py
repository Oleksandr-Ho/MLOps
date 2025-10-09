#!/usr/bin/env python3
"""Скрипт для тренування кількох моделей, логування результатів у MLflow та публікації метрик у Prometheus PushGateway."""

from __future__ import annotations

import argparse
import itertools
import logging
import os
import shutil
from pathlib import Path
from typing import Dict, List, Tuple

import mlflow
import mlflow.sklearn  # noqa: F401 - імпорт потрібен для завантаження модуля логування моделей
import numpy as np
from mlflow.tracking import MlflowClient
from prometheus_client import CollectorRegistry, Gauge, push_to_gateway
from sklearn.datasets import load_iris
from sklearn.metrics import accuracy_score, log_loss
from sklearn.model_selection import train_test_split
from sklearn.neural_network import MLPClassifier
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler


LOGGER = logging.getLogger("train_and_push")


def parse_args() -> argparse.Namespace:
    """Зчитуємо параметри CLI, щоб не хардкодити адреси сервісів."""

    parser = argparse.ArgumentParser(
        description="Тренує декілька моделей MLP на Iris та шле метрики у MLflow + PushGateway.",
    )
    parser.add_argument(
        "--tracking-uri",
        default=os.getenv("MLFLOW_TRACKING_URI", "http://localhost:5000"),
        help="URI вашого MLflow Tracking Server (port-forward або адреса сервісу).",
    )
    parser.add_argument(
        "--experiment-name",
        default=os.getenv("MLFLOW_EXPERIMENT_NAME", "iris-monitoring"),
        help="Назва експерименту у MLflow, куди складатимуться всі запуски.",
    )
    parser.add_argument(
        "--pushgateway-url",
        default=os.getenv("PUSHGATEWAY_URL", "http://localhost:9091"),
        help="Адреса PushGateway. Для локального запуску зручно port-forward'ити 9091.",
    )
    parser.add_argument(
        "--pushgateway-job",
        default=os.getenv("PUSHGATEWAY_JOB", "mlops-homework"),
        help="Назва job, з якою відправляємо метрики в PushGateway.",
    )
    parser.add_argument(
        "--test-size",
        type=float,
        default=0.2,
        help="Частка вибірки, що піде у тест. Корисно для швидких експериментів.",
    )
    parser.add_argument(
        "--random-state",
        type=int,
        default=42,
        help="Фіксуємо зерно генератора випадкових чисел для відтворюваності.",
    )
    return parser.parse_args()


def prepare_dataset(test_size: float, random_state: int) -> Tuple[np.ndarray, ...]:
    """Готуємо датасет Iris; стандартне розбиття на train/test."""

    iris = load_iris(as_frame=True)
    features = iris.data
    target = iris.target

    # Стандартизуємо дані, щоб MLP сходився навіть з маленьким learning_rate.
    X_train, X_test, y_train, y_test = train_test_split(
        features,
        target,
        test_size=test_size,
        random_state=random_state,
        stratify=target,
    )
    return X_train.values, X_test.values, y_train.values, y_test.values


def build_param_grid() -> List[Dict[str, float]]:
    """Формуємо сітку гіперпараметрів, з якими будемо запускати експерименти."""

    learning_rates = [0.001, 0.01, 0.1]
    epochs = [120, 220, 320]
    hidden_units = [32, 64]

    grid: List[Dict[str, float]] = []
    for lr, epoch, units in itertools.product(learning_rates, epochs, hidden_units):
        grid.append(
            {
                "learning_rate_init": lr,
                "max_iter": epoch,
                "hidden_layer_sizes": units,
            },
        )
    return grid


def push_metrics(pushgateway_url: str, job_name: str, run_id: str, accuracy: float, loss: float) -> None:
    """Відправляємо метрики для кожного запуску у PushGateway окремим реєстром."""

    registry = CollectorRegistry()
    accuracy_gauge = Gauge(
        "mlflow_accuracy",
        "Класифікаційна точність моделі з експерименту MLflow.",
        ["run_id"],
        registry=registry,
    )
    loss_gauge = Gauge(
        "mlflow_loss",
        "Log-loss моделі з експерименту MLflow.",
        ["run_id"],
        registry=registry,
    )

    accuracy_gauge.labels(run_id=run_id).set(accuracy)
    loss_gauge.labels(run_id=run_id).set(loss)

    # Даємо зрозуміле логування, аби при збоях одразу бачити причину.
    try:
        push_to_gateway(pushgateway_url, job=job_name, registry=registry)
        LOGGER.info("Метрики run_id=%s відправлені у PushGateway %s", run_id, pushgateway_url)
    except Exception as err:  # noqa: BLE001 - хочемо бачити будь-яку проблему з мережею одразу
        LOGGER.error("Не вдалося відправити метрики до PushGateway: %s", err)


def cleanup_best_model_dir(directory: Path) -> None:
    """Очищуємо best_model/, залишаючи службові файли на кшталт .gitkeep."""

    if not directory.exists():
        directory.mkdir(parents=True, exist_ok=True)
        return

    for item in directory.iterdir():
        if item.name.startswith(".gitkeep"):
            continue
        if item.is_dir():
            shutil.rmtree(item)
        else:
            item.unlink()


def copy_best_model(run_id: str, destination: Path) -> None:
    """Завантажуємо артефакти найкращого запуску та копіюємо їх у best_model/."""

    cleanup_best_model_dir(destination)
    local_dir = mlflow.artifacts.download_artifacts(run_id=run_id, artifact_path="model")

    target_dir = destination / run_id
    shutil.copytree(local_dir, target_dir, dirs_exist_ok=True)
    LOGGER.info("Артефакти найкращої моделі скопійовані у %s", target_dir)


def run_experiments(args: argparse.Namespace) -> None:
    """Основний цикл експериментів: тренуємо, логумо, пушимо."""

    X_train, X_test, y_train, y_test = prepare_dataset(args.test_size, args.random_state)
    mlflow.set_tracking_uri(args.tracking_uri)
    mlflow.set_experiment(args.experiment_name)

    best_run_id: str | None = None
    best_accuracy = -1.0

    for params in build_param_grid():
        # У кожному запуску створюємо пайплайн: масштабування + MLP для мультикласу.
        pipeline = Pipeline(
            steps=[
                ("scaler", StandardScaler()),
                (
                    "classifier",
                    MLPClassifier(
                        hidden_layer_sizes=(params["hidden_layer_sizes"],),
                        learning_rate_init=params["learning_rate_init"],
                        max_iter=params["max_iter"],
                        early_stopping=True,
                        n_iter_no_change=20,
                        random_state=args.random_state,
                        verbose=False,
                    ),
                ),
            ],
        )

        with mlflow.start_run() as active_run:
            run_id = active_run.info.run_id
            LOGGER.info(
                "Запускаємо тренування run_id=%s з параметрами %s",
                run_id,
                params,
            )

            pipeline.fit(X_train, y_train)

            y_pred = pipeline.predict(X_test)
            y_proba = pipeline.predict_proba(X_test)

            accuracy = accuracy_score(y_test, y_pred)
            loss = log_loss(y_test, y_proba)

            # Фіксуємо гіперпараметри, щоб простіше було шукати найкрарий запуск.
            mlflow.log_params(params)
            mlflow.log_metric("accuracy", float(accuracy))
            mlflow.log_metric("loss", float(loss))
            mlflow.sklearn.log_model(pipeline, artifact_path="model")

            push_metrics(args.pushgateway_url, args.pushgateway_job, run_id, accuracy, loss)

            if accuracy > best_accuracy:
                best_accuracy = accuracy
                best_run_id = run_id
                LOGGER.info("Поточний run_id=%s став новим лідером із accuracy=%.4f", run_id, accuracy)

    if best_run_id is None:
        raise RuntimeError("Жодного успішного запуску не відбулося – перевірте логування вище.")

    client = MlflowClient()
    destination_dir = Path(__file__).resolve().parents[1] / "best_model"
    copy_best_model(best_run_id, destination_dir)

    best_run_info = client.get_run(best_run_id)
    LOGGER.info(
        "Найкращий запуск: %s із accuracy=%.4f та loss=%.4f",
        best_run_id,
        best_run_info.data.metrics.get("accuracy"),
        best_run_info.data.metrics.get("loss"),
    )


def main() -> None:
    """Точка входу зі стандартним конфігуруванням логів."""

    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
    args = parse_args()
    run_experiments(args)


if __name__ == "__main__":
    main()
