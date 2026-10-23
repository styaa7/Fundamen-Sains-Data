"""
SkripsiFlow ML API — FastAPI Server

Provides REST API endpoints for all 4 ML models:
  1. POST /predict/completion-time   — Linear Regression
  2. POST /predict/ontime-risk       — Logistic Regression
  3. POST /predict/topic-quality     — Naive Bayes
  4. POST /predict/topic-category    — SVM
  5. GET  /models/metrics            — Training metrics

Usage:
    uvicorn main:app --host 0.0.0.0 --port 8000 --reload
"""

import os
import json
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import Optional

# Import ML models
from models.linear_regression_model import predict as predict_lr
from models.logistic_regression_model import predict as predict_logr
from models.naive_bayes_model import predict as predict_nb
from models.svm_model import predict as predict_svm

# =============================================================================
# FastAPI App Setup
# =============================================================================
app = FastAPI(
    title="SkripsiFlow ML API",
    description="API Machine Learning untuk SkripsiFlow — SaaS Bimbingan Skripsi",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# CORS — allow Flutter app to connect
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, restrict this
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# =============================================================================
# Request/Response Models (Pydantic)
# =============================================================================

# --- Linear Regression ---
class CompletionTimeRequest(BaseModel):
    current_stage_order: int = Field(..., ge=1, le=8, description="Tahapan saat ini (1-8)")
    overall_progress_percentage: float = Field(..., ge=0, le=100, description="Persentase progress keseluruhan")
    days_since_start: int = Field(..., ge=1, description="Jumlah hari sejak mulai skripsi")
    total_consultations: int = Field(..., ge=0, description="Total jumlah konsultasi")
    total_revisions: int = Field(..., ge=0, description="Total jumlah revisi topik")
    avg_days_per_stage: float = Field(..., ge=0, description="Rata-rata hari per tahapan")

    model_config = {
        "json_schema_extra": {
            "examples": [
                {
                    "current_stage_order": 3,
                    "overall_progress_percentage": 37.5,
                    "days_since_start": 90,
                    "total_consultations": 5,
                    "total_revisions": 1,
                    "avg_days_per_stage": 30.0,
                }
            ]
        }
    }


# --- Logistic Regression ---
class OntimeRiskRequest(BaseModel):
    current_stage_order: int = Field(..., ge=1, le=8, description="Tahapan saat ini (1-8)")
    overall_progress_percentage: float = Field(..., ge=0, le=100, description="Persentase progress")
    days_since_start: int = Field(..., ge=1, description="Jumlah hari sejak mulai")
    consultation_frequency: float = Field(..., ge=0, description="Frekuensi konsultasi per bulan")
    revision_count: int = Field(..., ge=0, description="Jumlah revisi topik")
    stage_completion_rate: float = Field(..., ge=0, description="Rasio stage selesai vs expected")

    model_config = {
        "json_schema_extra": {
            "examples": [
                {
                    "current_stage_order": 4,
                    "overall_progress_percentage": 50.0,
                    "days_since_start": 120,
                    "consultation_frequency": 1.5,
                    "revision_count": 2,
                    "stage_completion_rate": 0.8,
                }
            ]
        }
    }


# --- Naive Bayes ---
class TopicQualityRequest(BaseModel):
    title: str = Field(..., min_length=5, description="Judul topik skripsi")
    background: str = Field(..., min_length=10, description="Latar belakang penelitian")
    problem_formulation: str = Field(..., min_length=10, description="Rumusan masalah")
    methodology: str = Field(..., min_length=10, description="Metodologi penelitian")

    model_config = {
        "json_schema_extra": {
            "examples": [
                {
                    "title": "Implementasi Algoritma Machine Learning untuk Prediksi Kelulusan Mahasiswa",
                    "background": "Perkembangan teknologi AI memberikan dampak signifikan pada sektor pendidikan tinggi.",
                    "problem_formulation": "Bagaimana merancang model prediksi yang akurat untuk memprediksi kelulusan mahasiswa?",
                    "methodology": "Penelitian ini menggunakan metode CRISP-DM dengan algoritma Random Forest dan SVM.",
                }
            ]
        }
    }


# --- SVM ---
class TopicCategoryRequest(BaseModel):
    title: str = Field(..., min_length=5, description="Judul topik skripsi")
    description: str = Field(..., min_length=10, description="Deskripsi topik")
    methodology: Optional[str] = Field("", description="Metodologi (opsional)")

    model_config = {
        "json_schema_extra": {
            "examples": [
                {
                    "title": "Sistem Smart Home Otomatis Berbasis Arduino dan MQTT",
                    "description": "Penelitian ini merancang sistem IoT yang menghubungkan perangkat rumah melalui jaringan internet.",
                    "methodology": "Menggunakan mikrokontroler Arduino Mega dengan sensor DHT22 dan modul WiFi ESP8266.",
                }
            ]
        }
    }


# =============================================================================
# API Endpoints
# =============================================================================

@app.get("/", tags=["Root"])
def root():
    return {
        "service": "SkripsiFlow ML API",
        "version": "1.0.0",
        "endpoints": {
            "prediction": [
                "POST /predict/completion-time",
                "POST /predict/ontime-risk",
                "POST /predict/topic-quality",
                "POST /predict/topic-category",
            ],
            "info": [
                "GET /models/metrics",
                "GET /docs",
            ],
        },
    }


@app.post("/predict/completion-time", tags=["Predictions"])
def predict_completion_time(request: CompletionTimeRequest):
    """
    📈 Linear Regression — Prediksi Waktu Penyelesaian Skripsi
    
    Memprediksi estimasi jumlah hari yang dibutuhkan mahasiswa
    untuk menyelesaikan skripsi berdasarkan progress saat ini.
    """
    try:
        result = predict_lr(request.model_dump())
        return {"success": True, "data": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Prediction error: {str(e)}")


@app.post("/predict/ontime-risk", tags=["Predictions"])
def predict_ontime_risk(request: OntimeRiskRequest):
    """
    🎯 Logistic Regression — Prediksi Risiko Keterlambatan
    
    Mengklasifikasikan apakah mahasiswa akan selesai tepat waktu
    atau terlambat, beserta tingkat risiko (LOW/MEDIUM/HIGH).
    """
    try:
        result = predict_logr(request.model_dump())
        return {"success": True, "data": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Prediction error: {str(e)}")


@app.post("/predict/topic-quality", tags=["Predictions"])
def predict_topic_quality(request: TopicQualityRequest):
    """
    📝 Naive Bayes — Pra-Evaluasi Kualitas Topik Skripsi
    
    Mengklasifikasikan topik skripsi apakah kemungkinan APPROVED,
    REVISION, atau REJECTED berdasarkan teks pengajuan.
    """
    try:
        result = predict_nb(request.model_dump())
        return {"success": True, "data": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Prediction error: {str(e)}")


@app.post("/predict/topic-category", tags=["Predictions"])
def predict_topic_category(request: TopicCategoryRequest):
    """
    🔬 SVM — Kategorisasi Bidang Topik Skripsi
    
    Mengklasifikasikan topik skripsi ke dalam kategori bidang
    penelitian dan merekomendasikan dosen pembimbing.
    """
    try:
        result = predict_svm(request.model_dump())
        return {"success": True, "data": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Prediction error: {str(e)}")


@app.get("/models/metrics", tags=["Model Info"])
def get_model_metrics():
    """
    📊 Get training metrics for all models.
    """
    metrics_path = os.path.join(
        os.path.dirname(__file__), "saved_models", "training_metrics.json"
    )
    if not os.path.exists(metrics_path):
        raise HTTPException(
            status_code=404,
            detail="Training metrics not found. Run 'python train.py' first.",
        )

    with open(metrics_path, "r") as f:
        metrics = json.load(f)

    return {"success": True, "data": metrics}


# =============================================================================
# Run server
# =============================================================================
if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
