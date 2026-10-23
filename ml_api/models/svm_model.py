"""
SVM Model — Kategorisasi Bidang Topik Skripsi

Mengklasifikasikan topik skripsi ke dalam kategori bidang penelitian
(AI/ML, IoT, Mobile Dev, Web Dev, Data Science, Cybersecurity, Game Dev).
"""

import os
import joblib
import numpy as np
import pandas as pd
from sklearn.svm import SVC
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.model_selection import train_test_split
from sklearn.metrics import (
    accuracy_score,
    classification_report,
    confusion_matrix,
)
from sklearn.pipeline import Pipeline

MODEL_DIR = os.path.join(os.path.dirname(__file__), "..", "saved_models")
MODEL_PATH = os.path.join(MODEL_DIR, "svm_pipeline.joblib")

CATEGORIES = [
    "AI/ML",
    "IoT",
    "Mobile Dev",
    "Web Dev",
    "Data Science",
    "Cybersecurity",
    "Game Dev",
]

# Mapping kategori ke dosen pembimbing yang direkomendasikan (contoh)
LECTURER_RECOMMENDATIONS = {
    "AI/ML": ["Dr. Budi Santoso, M.Kom. (AI & Machine Learning)", "Dr. Siti Rahayu, M.T. (Deep Learning)"],
    "IoT": ["Dr. Agus Prasetyo, M.T. (Embedded Systems)", "Dr. Rina Wulandari, M.Kom. (IoT & Sensors)"],
    "Mobile Dev": ["Dr. Dian Permata, M.Kom. (Mobile Computing)", "Dr. Hendra Wijaya, M.T. (Software Engineering)"],
    "Web Dev": ["Dr. Fajar Nugroho, M.Kom. (Web Technologies)", "Dr. Lisa Kartini, M.T. (Full-Stack Development)"],
    "Data Science": ["Dr. Maya Putri, M.Sc. (Data Science)", "Dr. Reza Ahmad, M.Kom. (Big Data Analytics)"],
    "Cybersecurity": ["Dr. Kurniawan Teguh, M.T. (Cybersecurity)", "Dr. Anita Sari, M.Kom. (Network Security)"],
    "Game Dev": ["Dr. Bambang Irawan, M.Kom. (Game Technology)", "Dr. Novi Handayani, M.T. (Computer Graphics)"],
}


def train(data_path: str) -> dict:
    """Train the SVM text classification model and save it."""
    os.makedirs(MODEL_DIR, exist_ok=True)

    df = pd.read_csv(data_path)
    X = df["combined_text"]
    y = df["category"]

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )

    # Pipeline: TF-IDF Vectorizer → SVM with RBF kernel
    pipeline = Pipeline([
        ("tfidf", TfidfVectorizer(
            max_features=5000,
            ngram_range=(1, 2),
            min_df=2,
        )),
        ("classifier", SVC(
            kernel="rbf",
            C=10.0,
            gamma="scale",
            probability=True,  # Enable probability estimates
            random_state=42,
        )),
    ])

    pipeline.fit(X_train, y_train)

    y_pred = pipeline.predict(X_test)
    cm = confusion_matrix(y_test, y_pred, labels=CATEGORIES)
    report = classification_report(y_test, y_pred, output_dict=True)

    metrics = {
        "accuracy": round(accuracy_score(y_test, y_pred), 4),
        "confusion_matrix": cm.tolist(),
        "per_class": {
            label: {
                "precision": round(report[label]["precision"], 4),
                "recall": round(report[label]["recall"], 4),
                "f1_score": round(report[label]["f1-score"], 4),
            }
            for label in CATEGORIES
            if label in report
        },
        "vocabulary_size": len(pipeline.named_steps["tfidf"].vocabulary_),
    }

    joblib.dump(pipeline, MODEL_PATH)

    print(f"🔬 SVM trained → Accuracy = {metrics['accuracy']}")
    print(f"   Classes: {CATEGORIES}")
    return metrics


def predict(text_fields: dict) -> dict:
    """
    Predict topic category.
    
    Args:
        text_fields: dict with keys: title, description, methodology (optional)
    Returns:
        dict with predicted category, probabilities, and lecturer recommendations
    """
    pipeline = joblib.load(MODEL_PATH)

    combined = (
        f"{text_fields.get('title', '')}. "
        f"{text_fields.get('description', '')} "
        f"{text_fields.get('methodology', '')}"
    )

    prediction = pipeline.predict([combined])[0]
    probabilities = pipeline.predict_proba([combined])[0]
    classes = pipeline.classes_

    prob_dict = {
        cls: round(prob, 4) for cls, prob in zip(classes, probabilities)
    }

    # Sort probabilities descending
    sorted_probs = sorted(prob_dict.items(), key=lambda x: x[1], reverse=True)
    top_3 = sorted_probs[:3]

    return {
        "predicted_category": prediction,
        "confidence": round(max(probabilities), 4),
        "probabilities": prob_dict,
        "top_3_categories": [{"category": cat, "probability": prob} for cat, prob in top_3],
        "recommended_lecturers": LECTURER_RECOMMENDATIONS.get(prediction, []),
        "model": "SVM (RBF Kernel)",
        "input_preview": combined[:200] + "..." if len(combined) > 200 else combined,
    }
