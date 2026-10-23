"""
Training Script — Train all 4 ML models for SkripsiFlow

Usage:
    python train.py
"""

import os
import json
import sys

# Add parent dir to path
sys.path.insert(0, os.path.dirname(__file__))

from data.generate_training_data import (
    generate_completion_time_data,
    generate_ontime_prediction_data,
    generate_topic_quality_data,
    generate_topic_category_data,
)
from models.linear_regression_model import train as train_lr
from models.logistic_regression_model import train as train_logr
from models.naive_bayes_model import train as train_nb
from models.svm_model import train as train_svm


DATA_DIR = os.path.join(os.path.dirname(__file__), "data")
RESULTS_DIR = os.path.join(os.path.dirname(__file__), "saved_models")


def main():
    print("=" * 70)
    print("🚀 SkripsiFlow ML — Training Pipeline")
    print("=" * 70)

    # Step 1: Generate training data
    print("\n📊 Step 1: Generating synthetic training data...")
    print("-" * 50)
    generate_completion_time_data(n=500)
    generate_ontime_prediction_data(n=500)
    generate_topic_quality_data(n=300)
    generate_topic_category_data(n=400)

    all_metrics = {}

    # Step 2: Train Linear Regression
    print("\n" + "=" * 50)
    print("📈 Step 2: Training Linear Regression")
    print("-" * 50)
    metrics_lr = train_lr(os.path.join(DATA_DIR, "completion_time_data.csv"))
    all_metrics["linear_regression"] = metrics_lr

    # Step 3: Train Logistic Regression
    print("\n" + "=" * 50)
    print("🎯 Step 3: Training Logistic Regression")
    print("-" * 50)
    metrics_logr = train_logr(os.path.join(DATA_DIR, "ontime_prediction_data.csv"))
    all_metrics["logistic_regression"] = metrics_logr

    # Step 4: Train Naive Bayes
    print("\n" + "=" * 50)
    print("📝 Step 4: Training Naive Bayes")
    print("-" * 50)
    metrics_nb = train_nb(os.path.join(DATA_DIR, "topic_quality_data.csv"))
    all_metrics["naive_bayes"] = metrics_nb

    # Step 5: Train SVM
    print("\n" + "=" * 50)
    print("🔬 Step 5: Training SVM")
    print("-" * 50)
    metrics_svm = train_svm(os.path.join(DATA_DIR, "topic_category_data.csv"))
    all_metrics["svm"] = metrics_svm

    # Save all metrics
    os.makedirs(RESULTS_DIR, exist_ok=True)
    metrics_path = os.path.join(RESULTS_DIR, "training_metrics.json")
    with open(metrics_path, "w") as f:
        json.dump(all_metrics, f, indent=2)

    # Summary
    print("\n" + "=" * 70)
    print("✅ ALL MODELS TRAINED SUCCESSFULLY!")
    print("=" * 70)
    print(f"\n📊 Training Metrics Summary:")
    print(f"   Linear Regression  — R² Score:  {all_metrics['linear_regression']['r2_score']}")
    print(f"   Logistic Regression — Accuracy: {all_metrics['logistic_regression']['accuracy']}")
    print(f"   Naive Bayes        — Accuracy:  {all_metrics['naive_bayes']['accuracy']}")
    print(f"   SVM                — Accuracy:  {all_metrics['svm']['accuracy']}")
    print(f"\n📁 Models saved to: {os.path.abspath(RESULTS_DIR)}")
    print(f"📄 Metrics saved to: {os.path.abspath(metrics_path)}")
    print(f"\n🚀 Start the API server with: python main.py")


if __name__ == "__main__":
    main()
