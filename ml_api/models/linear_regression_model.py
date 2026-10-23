"""
Linear Regression Model — Prediksi Waktu Penyelesaian Skripsi

Memprediksi estimasi jumlah hari yang dibutuhkan mahasiswa untuk
menyelesaikan skripsi berdasarkan fitur progress saat ini.
"""

import os
import joblib
import numpy as np
import pandas as pd
from sklearn.linear_model import LinearRegression
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
from sklearn.preprocessing import StandardScaler

MODEL_DIR = os.path.join(os.path.dirname(__file__), "..", "saved_models")
MODEL_PATH = os.path.join(MODEL_DIR, "linear_regression.joblib")
SCALER_PATH = os.path.join(MODEL_DIR, "lr_scaler.joblib")

FEATURE_COLUMNS = [
    "current_stage_order",
    "overall_progress_percentage",
    "days_since_start",
    "total_consultations",
    "total_revisions",
    "avg_days_per_stage",
]
TARGET_COLUMN = "days_to_complete"


def train(data_path: str) -> dict:
    """Train the Linear Regression model and save it."""
    os.makedirs(MODEL_DIR, exist_ok=True)

    df = pd.read_csv(data_path)
    X = df[FEATURE_COLUMNS]
    y = df[TARGET_COLUMN]

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42
    )

    # Scale features for better performance
    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_test_scaled = scaler.transform(X_test)

    # Train model
    model = LinearRegression()
    model.fit(X_train_scaled, y_train)

    # Evaluate
    y_pred = model.predict(X_test_scaled)
    metrics = {
        "mae": round(mean_absolute_error(y_test, y_pred), 2),
        "rmse": round(np.sqrt(mean_squared_error(y_test, y_pred)), 2),
        "r2_score": round(r2_score(y_test, y_pred), 4),
        "coefficients": {
            col: round(coef, 4)
            for col, coef in zip(FEATURE_COLUMNS, model.coef_)
        },
        "intercept": round(model.intercept_, 4),
    }

    # Save
    joblib.dump(model, MODEL_PATH)
    joblib.dump(scaler, SCALER_PATH)

    print(f"📈 Linear Regression trained → R² = {metrics['r2_score']}")
    print(f"   MAE = {metrics['mae']} days, RMSE = {metrics['rmse']} days")
    return metrics


def predict(features: dict) -> dict:
    """
    Predict days to complete thesis.
    
    Args:
        features: dict with keys matching FEATURE_COLUMNS
    Returns:
        dict with predicted_days and model info
    """
    model = joblib.load(MODEL_PATH)
    scaler = joblib.load(SCALER_PATH)

    X = np.array([[features[col] for col in FEATURE_COLUMNS]])
    X_scaled = scaler.transform(X)
    prediction = model.predict(X_scaled)[0]

    return {
        "predicted_days_to_complete": round(max(0, prediction), 1),
        "predicted_weeks": round(max(0, prediction) / 7, 1),
        "model": "Linear Regression",
        "features_used": FEATURE_COLUMNS,
        "input_values": features,
    }
