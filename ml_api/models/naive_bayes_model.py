"""
Naive Bayes Model — Klasifikasi Kualitas Topik Skripsi

Mengklasifikasikan apakah topik skripsi yang diajukan kemungkinan
akan APPROVED, REVISION, atau REJECTED berdasarkan teks pengajuan.
"""

import os
import joblib
import numpy as np
import pandas as pd
from sklearn.naive_bayes import MultinomialNB
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.model_selection import train_test_split
from sklearn.metrics import (
    accuracy_score,
    classification_report,
    confusion_matrix,
)
from sklearn.pipeline import Pipeline

MODEL_DIR = os.path.join(os.path.dirname(__file__), "..", "saved_models")
MODEL_PATH = os.path.join(MODEL_DIR, "naive_bayes_pipeline.joblib")

LABELS = ["APPROVED", "REVISION", "REJECTED"]
LABEL_DESCRIPTIONS = {
    "APPROVED": "Topik layak diterima",
    "REVISION": "Topik perlu direvisi",
    "REJECTED": "Topik ditolak",
}


def train(data_path: str) -> dict:
    """Train the Naive Bayes text classification model and save it."""
    os.makedirs(MODEL_DIR, exist_ok=True)

    df = pd.read_csv(data_path)
    X = df["combined_text"]
    y = df["status"]

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )

    # Pipeline: TF-IDF Vectorizer → Multinomial Naive Bayes
    pipeline = Pipeline([
        ("tfidf", TfidfVectorizer(
            max_features=5000,
            ngram_range=(1, 2),
            stop_words=None,  # Keep Indonesian stop words as features
            min_df=2,
        )),
        ("classifier", MultinomialNB(alpha=0.1)),
    ])

    pipeline.fit(X_train, y_train)

    y_pred = pipeline.predict(X_test)
    cm = confusion_matrix(y_test, y_pred, labels=LABELS)
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
            for label in LABELS
            if label in report
        },
        "vocabulary_size": len(pipeline.named_steps["tfidf"].vocabulary_),
    }

    joblib.dump(pipeline, MODEL_PATH)

    print(f"📝 Naive Bayes trained → Accuracy = {metrics['accuracy']}")
    print(f"   Vocabulary size: {metrics['vocabulary_size']} terms")
    return metrics


def _is_gibberish(text: str) -> bool:
    """Deteksi teks tidak bermakna (acak/keyboard smashing)."""
    words = text.strip().split()
    if len(words) < 3:
        return True
    avg_len = sum(len(w) for w in words) / len(words)
    # Kata normal bahasa Indonesia rata-rata 4-12 karakter
    if avg_len > 15:
        return True
    # Setidaknya 2 kata dengan 3+ karakter unik (bukan "aaa", "fsfs")
    real_words = [w for w in words if len(set(w.lower())) >= 3]
    if len(real_words) < 2:
        return True
    return False


def _check_minimum_quality(text_fields: dict):
    """Validasi kualitas minimum sebelum masuk model ML."""
    title = text_fields.get('title', '').strip()
    background = text_fields.get('background', '').strip()
    problem = text_fields.get('problem_formulation', '').strip()
    methodology = text_fields.get('methodology', '').strip()

    if len(title.split()) < 3:
        return False, "Judul terlalu singkat. Minimal 3 kata."
    if len(background.split()) < 10:
        return False, "Latar belakang terlalu singkat. Jelaskan konteks dan urgensi penelitian."
    if len(problem.split()) < 5:
        return False, "Rumusan masalah terlalu singkat. Tulis minimal 1 pertanyaan penelitian yang jelas."
    if len(methodology.split()) < 5:
        return False, "Metodologi terlalu singkat. Jelaskan metode/pendekatan penelitian."

    # Cek gibberish pada judul dan gabungan teks
    if _is_gibberish(title):
        return False, "Judul tidak dapat dikenali. Gunakan kalimat yang bermakna."
    combined_check = f"{title} {background} {problem} {methodology}"
    if _is_gibberish(combined_check):
        return False, "Teks tidak dapat dikenali. Pastikan menggunakan kalimat yang bermakna."

    return True, ""


def predict(text_fields: dict) -> dict:
    """
    Predict topic quality/status.

    Args:
        text_fields: dict with keys: title, background, problem_formulation, methodology
    Returns:
        dict with predicted status, probabilities per class, and feedback
    """
    # === Validasi sebelum masuk model ML ===
    is_valid, reason = _check_minimum_quality(text_fields)
    if not is_valid:
        return {
            "predicted_status": "REJECTED",
            "predicted_label": LABEL_DESCRIPTIONS["REJECTED"],
            "probabilities": {"APPROVED": 0.0, "REVISION": 0.05, "REJECTED": 0.95},
            "feedback": f"Input tidak valid: {reason}",
            "model": "Naive Bayes (Multinomial) — Pre-validation",
            "input_preview": text_fields.get('title', '')[:200],
        }

    pipeline = joblib.load(MODEL_PATH)

    combined = (
        f"{text_fields.get('title', '')}. "
        f"{text_fields.get('background', '')} "
        f"{text_fields.get('problem_formulation', '')} "
        f"{text_fields.get('methodology', '')}"
    )

    prediction = pipeline.predict([combined])[0]
    probabilities = pipeline.predict_proba([combined])[0]
    classes = pipeline.classes_

    prob_dict = {
        cls: round(prob, 4) for cls, prob in zip(classes, probabilities)
    }

    if prediction == "APPROVED":
        feedback = "Topik skripsi kamu sudah cukup lengkap dan memenuhi standar. Lanjutkan ke tahap berikutnya!"
    elif prediction == "REVISION":
        feedback = "Topik skripsi perlu diperbaiki. Pastikan latar belakang, rumusan masalah, dan metodologi sudah detail dan spesifik."
    else:
        feedback = "Topik skripsi belum memenuhi standar minimum. Perlu perbaikan signifikan pada judul, latar belakang, dan metodologi."

    return {
        "predicted_status": prediction,
        "predicted_label": LABEL_DESCRIPTIONS.get(prediction, prediction),
        "probabilities": prob_dict,
        "feedback": feedback,
        "model": "Naive Bayes (Multinomial)",
        "input_preview": combined[:200] + "..." if len(combined) > 200 else combined,
    }
