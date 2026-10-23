"""
Logistic Regression Model — Prediksi Kelulusan Tepat Waktu

Mengklasifikasikan apakah mahasiswa akan menyelesaikan skripsi
tepat waktu (on_time=1) atau terlambat (on_time=0).
"""

import os
import joblib
import numpy as np
import pandas as pd
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split
from sklearn.metrics import (
    accuracy_score,
    precision_score,
    recall_score,
    f1_score,
    classification_report,
    confusion_matrix,
)
from sklearn.preprocessing import StandardScaler

MODEL_DIR = os.path.join(os.path.dirname(__file__), "..", "saved_models")
MODEL_PATH = os.path.join(MODEL_DIR, "logistic_regression.joblib")
SCALER_PATH = os.path.join(MODEL_DIR, "logr_scaler.joblib")

FEATURE_COLUMNS = [
    "current_stage_order",
    "overall_progress_percentage",
    "days_since_start",
    "consultation_frequency",
    "revision_count",
    "stage_completion_rate",
]
TARGET_COLUMN = "on_time"


def train(data_path: str) -> dict:
    """Train the Logistic Regression model and save it."""
    os.makedirs(MODEL_DIR, exist_ok=True)

    df = pd.read_csv(data_path)
    X = df[FEATURE_COLUMNS]
    y = df[TARGET_COLUMN]

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42
    )

    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_test_scaled = scaler.transform(X_test)

    model = LogisticRegression(random_state=42, max_iter=1000)
    model.fit(X_train_scaled, y_train)

    y_pred = model.predict(X_test_scaled)
    y_proba = model.predict_proba(X_test_scaled)

    cm = confusion_matrix(y_test, y_pred)
    metrics = {
        "accuracy": round(accuracy_score(y_test, y_pred), 4),
        "precision": round(precision_score(y_test, y_pred), 4),
        "recall": round(recall_score(y_test, y_pred), 4),
        "f1_score": round(f1_score(y_test, y_pred), 4),
        "confusion_matrix": cm.tolist(),
        "coefficients": {
            col: round(coef, 4)
            for col, coef in zip(FEATURE_COLUMNS, model.coef_[0])
        },
    }

    joblib.dump(model, MODEL_PATH)
    joblib.dump(scaler, SCALER_PATH)

    print(f"🎯 Logistic Regression trained → Accuracy = {metrics['accuracy']}")
    print(f"   Precision = {metrics['precision']}, Recall = {metrics['recall']}, F1 = {metrics['f1_score']}")
    return metrics


def predict(features: dict) -> dict:
    """
    Predict if student will complete thesis on time.
    
    Args:
        features: dict with keys matching FEATURE_COLUMNS
    Returns:
        dict with prediction, probability, and risk level
    """
    model = joblib.load(MODEL_PATH)
    scaler = joblib.load(SCALER_PATH)

    X = np.array([[features[col] for col in FEATURE_COLUMNS]])
    X_scaled = scaler.transform(X)
    prediction = model.predict(X_scaled)[0]
    probabilities = model.predict_proba(X_scaled)[0]

    prob_on_time = round(probabilities[1], 4)
    prob_late = round(probabilities[0], 4)

    # Risk level classification
    if prob_late >= 0.7:
        risk_level = "HIGH"
        risk_label = "Risiko Tinggi Terlambat"
    elif prob_late >= 0.4:
        risk_level = "MEDIUM"
        risk_label = "Risiko Sedang"
    else:
        risk_level = "LOW"
        risk_label = "Risiko Rendah"

    return {
        "prediction": "TEPAT_WAKTU" if prediction == 1 else "TERLAMBAT",
        "probability_on_time": prob_on_time,
        "probability_late": prob_late,
        "risk_level": risk_level,
        "risk_label": risk_label,
        "model": "Logistic Regression",
        "features_used": FEATURE_COLUMNS,
        "input_values": features,
    }
