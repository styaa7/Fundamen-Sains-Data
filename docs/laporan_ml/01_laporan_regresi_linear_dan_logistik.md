# LAPORAN TEKNIS MACHINE LEARNING (BAGIAN 1)
## Pemodelan Prediksi Estimasi Waktu Penyelesaian dan Risiko Keterlambatan Skripsi
### Penerapan Linear Regression dan Logistic Regression pada Platform SkripsiFlow

---

| Metadata Dokumen | Informasi |
| :--- | :--- |
| **Topik Proyek** | Analisis Progres Skripsi & Deteksi Risiko Early-Warning Mahasiswa |
| **Algoritma** | **Linear Regression** (Regresi Kontinu) & **Logistic Regression** (Klasifikasi Biner) |
| **Modul Terkait** | `ml_api/models/linear_regression_model.py`, `ml_api/models/logistic_regression_model.py` |
| **API Endpoints** | `POST /predict/completion-time`, `POST /predict/ontime-risk` |
| **Status Pemodelan** | Production Ready / Trained & Evaluated |

---

## 1. Ringkasan Eksekutif (Executive Summary)

Dalam pengelolaan tugas akhir di perguruan tinggi, masalah utama yang dihadapi mahasiswa dan pihak program studi adalah keterlambatan masa studi yang diakibatkan oleh kurangnya pemantauan progres berkala dan tidak adanya mekanisme *early-warning system*. 

Laporan ini menyajikan perancangan, implementasi, dan evaluasi dari dua model *supervised learning* berbasis statistik inferensial:
1. **Linear Regression**: Memprediksi estimasi kuantitatif sisa hari yang dibutuhkan mahasiswa untuk menyelesaikan seluruh tahapan skripsi (*days to complete*). Model ini mencapai skor determinasi tinggi **$R^2 = 0.9786$** dengan **MAE sebesar 9.05 hari** dan **RMSE sebesar 11.64 hari**.
2. **Logistic Regression**: Mengklasifikasikan kemungkinan mahasiswa lulus tepat waktu (*on-time*) versus terlambat (*delayed*), sekaligus memetakan probabilitas risiko (*risk scoring*: Low, Medium, High). Model ini menghasilkan **akurasi 89.00%**, **presisi 90.12%**, **recall 96.05%**, dan **F1-Score 92.99%**.

Integrasi kedua model ini pada sistem backend FastAPI memungkinkan dashboard mahasiswa dan dosen pembimbing memberikan visualisasi waktu penyelesaian serta tindakan preventif sebelum mahasiswa melewati batas semester akademik.

---

## 2. Latar Belakang & Perumusan Masalah

Pada aplikasi **SkripsiFlow**, perjalanan skripsi mahasiswa distandarisasi ke dalam 8 tahapan terstruktur:
1. Pengajuan Topik (*Topic Submission*)
2. Proposal Skripsi (*Proposal Preparation*)
3. Seminar Proposal (*Seminar Proposal Presentation*)
4. Revisi Proposal (*Proposal Revision*)
5. Pengumpulan & Analisis Data (*Data Collection & Analysis*)
6. Penulisan Naskah Skripsi (*Draft Thesis Writing*)
7. Sidang Skripsi (*Final Thesis Defense*)
8. Revisi Akhir & Yudisium (*Final Revision & Graduation*)

Permasalahan yang diselesaikan melalui pemodelan ini adalah:
1. **Estimasi Kuantitatif**: Berapa sisa hari kerja nyata yang dibutuhkan mahasiswa untuk menyelesaikan sisa tahapan berdasarkan laju pengerjaan individu dan riwayat revisi?
2. **Identifikasi Dini Risiko**: Apakah ritme konsultasi dan durasi per tahapan saat ini mengindikasikan mahasiswa berada di zona merah (risiko tinggi molor melampaui 180 hari / 1 semester kerja)?

---

## 3. Dataset & Analisis Fitur (Feature Engineering)

Dataset sintetis dimodelkan dengan mengacu langsung pada skema database riil PostgreSQL SkripsiFlow (`theses`, `stages`, `consultations`).

### 3.1. Spesifikasi Fitur Linear Regression
Dataset berukuran $N = 500$ baris dengan komposisi fitur:

| Nama Fitur | Tipe Data | Deskripsi Operasional |
| :--- | :--- | :--- |
| `current_stage_order` | Integer ($1 - 8$) | Nomor tahapan aktif yang sedang dijalani mahasiswa. |
| `overall_progress_percentage` | Float ($0.0 - 100.0$) | Persentase kumulatif penyelesaian skripsi. |
| `days_since_start` | Integer ($\ge 1$) | Total hari kalender sejak SK skripsi diterbitkan. |
| `total_consultations` | Integer ($\ge 0$) | Total sesi bimbingan yang telah divalidasi pembimbing. |
| `total_revisions` | Integer ($\ge 0$) | Jumlah siklus revisi yang dialami pada pengajuan topik/naskah. |
| `avg_days_per_stage` | Float ($\ge 0$) | Rata-rata durasi hari yang dihabiskan untuk menuntaskan satu tahap. |
| **`days_to_complete` (Target)** | Float | Estimasi hari tersisa hingga tahap 8 tervalidasi. |

### 3.2. Spesifikasi Fitur Logistic Regression
Dataset berukuran $N = 500$ baris dengan fitur risiko:

| Nama Fitur | Tipe Data | Deskripsi Operasional |
| :--- | :--- | :--- |
| `current_stage_order` | Integer ($1 - 8$) | Tahapan aktif saat ini. |
| `overall_progress_percentage` | Float ($0.0 - 100.0$) | Persentase kemajuan fisik naskah. |
| `days_since_start` | Integer | Total hari kalender berjalan. |
| `consultation_frequency` | Float | Rata-rata frekuensi bimbingan per bulan ($\text{total} / \text{bulan}$). |
| `revision_count` | Integer | Total catatan revisi berulang. |
| `stage_completion_rate` | Float | Rasio tahapan selesai aktual terhadap target tahapan ideal ($\text{stage} / \text{expected\_stage}$). |
| **`on_time` (Target)** | Binary ($0 / 1$) | $1$ = Tepat Waktu ($\le 180$ hari), $0$ = Terlambat ($> 180$ hari). |

### 3.3. Prapemrosesan Data (Preprocessing)
Kedua model menerapkan teknik normalisasi z-score menggunakan `StandardScaler`:
$$z = \frac{x - \mu}{\sigma}$$
Skalasi ini krusial agar bobot koefisien tidak terdistorsi oleh perbedaan satuan antara persentase ($0-100$) dan hari berjalan ($7-365$). Pemisahan data dilakukan dengan rasio **80% training** dan **20% testing** (`random_state=42`).

---

## 4. Landasan Teori & Arsitektur Model

### 4.1. Linear Regression (Prediksi Hari Penyelesaian)
Persamaan regresi linear berganda dinyatakan sebagai:
$$\hat{y} = \beta_0 + \sum_{j=1}^{p} \beta_j X_j$$
Di mana:
- $\hat{y}$ adalah estimasi `days_to_complete`.
- $\beta_0$ adalah *intercept* (titik potong sumbu).
- $\beta_j$ adalah koefisien bobot dari masing-masing fitur $X_j$.

Optimasi dilakukan menggunakan metode kuadrat terkecil (*Ordinary Least Squares / OLS*) untuk meminimalkan *Residual Sum of Squares* (RSS):
$$\text{RSS} = \sum_{i=1}^{n} (y_i - \hat{y}_i)^2$$

### 4.2. Logistic Regression (Klasifikasi Kelulusan & Tingkat Risiko)
Logistic Regression memetakan kombinasi linear fitur ke dalam nilai probabilitas interval $[0, 1]$ menggunakan fungsi sigmoid:
$$P(Y=1 \mid X) = \sigma(z) = \frac{1}{1 + e^{-z}}$$
$$z = w_0 + \sum_{j=1}^{p} w_j X_j$$

Untuk kebutuhan aplikasi SkripsiFlow, luaran probabilitas $P(\text{Late}) = 1 - P(Y=1)$ dikelompokkan ke dalam 3 tier risiko operasional:
$$\text{Risk Level} = \begin{cases} 
\text{HIGH (Risiko Tinggi Terlambat)}, & \text{jika } P(\text{Late}) \ge 0.70 \\ 
\text{MEDIUM (Risiko Sedang)}, & \text{jika } 0.40 \le P(\text{Late}) < 0.70 \\ 
\text{LOW (Risiko Rendah)}, & \text{jika } P(\text{Late}) < 0.40 
\end{cases}$$

---

## 5. Hasil Pengujian & Evaluasi Kinerja

### 5.1. Kinerja Linear Regression

Pengujian dilakukan terhadap data uji ($N = 100$ sampel). Metrik yang diperoleh adalah:

| Metrik Evaluasi | Nilai Uji | Interpretasi |
| :--- | :---: | :--- |
| **Mean Absolute Error (MAE)** | **$9.05$ hari** | Rata-rata selisih prediksi dengan waktu riil adalah $\pm 9$ hari (~1.3 minggu). |
| **Root Mean Squared Error (RMSE)** | **$11.64$ hari** | Standar deviasi dari residual tergolong rendah, menunjukkan tidak adanya pencilan ekstrem. |
| **Koefisien Determinasi ($R^2$)** | **$0.9786$** | **$97.86\%$** variansi waktu penyelesaian berhasil dijelaskan oleh fitur-fitur progres. |
| **Intercept ($\beta_0$)** | **$115.4990$** | Konstanta dasar waktu skripsi mahasiswa pada skala standar. |

#### Analisis Koefisien Fitur (Feature Importance)
Koefisien regresi pada data terstandarisasi mencerminkan pengaruh murni masing-masing variabel:

| Fitur | Koefisien Terstandarisasi ($\beta$) | Arah & Makna Fisis |
| :--- | :---: | :--- |
| `days_since_start` | **$-85.3614$** | **Penurunan drastis**: Semakin lama hari berjalan yang telah dilalui, sisa hari menuju target absolut berkurang secara signifikan. |
| `avg_days_per_stage` | **$+78.0135$** | **Peningkatan signifikan**: Setiap penambahan rata-rata durasi per tahap memperpanjang sisa hari pengerjaan secara linier. |
| `total_revisions` | **$+10.2026$** | **Penalti waktu**: Setiap revisi menambah waktu penyesuaian naskah dan antrean review dosen. |
| `total_consultations` | **$-2.8565$** | **Akselerasi**: Konsultasi aktif mempercepat penyelesaian dan mencegah kebingungan pengerjaan. |
| `overall_progress_percentage` | **$+1.0839$** | Faktor koreksi penyeimbang tahapan naskah. |
| `current_stage_order` | **$+0.4963$** | Bobot tahapan aktif skripsi. |

---

### 5.2. Kinerja Logistic Regression

Evaluasi klasifikasi pada data uji ($N = 100$ sampel) menghasilkan metrik performa sebagai berikut:

| Metrik Klasifikasi | Nilai Uji | Analisis Kinerja |
| :--- | :---: | :--- |
| **Accuracy** | **$89.00\%$** | $89$ dari $100$ mahasiswa terklasifikasi status kelulusannya secara tepat. |
| **Precision** | **$90.12\%$** | Ketika model memprediksi mahasiswa tepat waktu, probabilitas kebenarannya mencapai $90.12\%$. |
| **Recall (Sensitivity)** | **$96.05\%$** | Model mampu menangkap $96.05\%$ dari seluruh mahasiswa yang memang benar-benar lulus tepat waktu. |
| **F1-Score** | **$92.99\%$** | Keseimbangan harmonis antara presisi dan recall sangat tinggi. |

#### Matriks Konfusi (Confusion Matrix)
Struktur pengujian terhadap $24$ sampel kelas Terlambat ($0$) dan $76$ sampel kelas Tepat Waktu ($1$):

```
                       Prediksi Terlambat (0)    Prediksi Tepat Waktu (1)
Aktual Terlambat (0)             16 (TN)                     8 (FP)
Aktual Tepat Waktu (1)            3 (FN)                    73 (TP)
```

- **True Negative (TN) = 16**: Mahasiswa yang lambat berhasil dideteksi dengan benar sebagai calon terlambat.
- **False Positive (FP) = 8**: Mahasiswa terlambat yang keliru diprediksi tepat waktu (tipe error yang diminimalisir melalui mitigasi risk thresholding).
- **False Negative (FN) = 3**: Hanya 3 mahasiswa tepat waktu yang diprediksi terlambat (tingkat salah peringatan sangat minim, $3.95\%$).
- **True Positive (TP) = 73**: Mahasiswa tepat waktu terdeteksi secara akurat.

#### Analisis Koefisien Logistik
Bobot log-odds ($w_j$) menunjukkan faktor pendorong dan penghambat kelulusan tepat waktu:

| Fitur Risiko | Koefisien Log-Odds ($w$) | Pengaruh terhadap Kelulusan Tepat Waktu |
| :--- | :---: | :--- |
| `overall_progress_percentage` | **$+2.0949$** | Pendorong terkuat kelulusan tepat waktu. |
| `stage_completion_rate` | **$+1.4745$** | Konsistensi memenuhi *milestone* tahapan sesuai jadwal akademik. |
| `current_stage_order` | **$+1.2065$** | Semakin jauh tahapan yang dicapai, semakin tinggi probabilitas tuntas. |
| `consultation_frequency` | **$+0.5859$** | Keaktifan bimbingan per bulan berdampak positif terhadap kelulusan. |
| `days_since_start` | **$-0.3840$** | Pertambahan hari yang terlalu lambat mengikis peluang tepat waktu. |
| `revision_count` | **$-1.7705$** | **Penghambat terbesar**: Revisi berulang mereduksi peluang lulus tepat waktu secara drastis. |

---

## 6. Implementasi & Integrasi Sistem (API Deployment)

Model disimpan menggunakan pustaka `joblib` ke dalam direktori `ml_api/saved_models/` (`linear_regression.joblib`, `logistic_regression.joblib`, beserta scaler `lr_scaler.joblib`, `logr_scaler.joblib`). 

### Contoh Request & Response Linear Regression (`/predict/completion-time`)
**Payload Input:**
```json
{
  "current_stage_order": 3,
  "overall_progress_percentage": 37.5,
  "days_since_start": 90,
  "total_consultations": 5,
  "total_revisions": 1,
  "avg_days_per_stage": 30.0
}
```
**Response JSON:**
```json
{
  "success": true,
  "data": {
    "predicted_days_to_complete": 142.3,
    "predicted_weeks": 20.3,
    "model": "Linear Regression",
    "features_used": [
      "current_stage_order", "overall_progress_percentage",
      "days_since_start", "total_consultations",
      "total_revisions", "avg_days_per_stage"
    ]
  }
}
```

### Contoh Request & Response Logistic Regression (`/predict/ontime-risk`)
**Payload Input:**
```json
{
  "current_stage_order": 4,
  "overall_progress_percentage": 50.0,
  "days_since_start": 120,
  "consultation_frequency": 1.5,
  "revision_count": 2,
  "stage_completion_rate": 0.8
}
```
**Response JSON:**
```json
{
  "success": true,
  "data": {
    "prediction": "TEPAT_WAKTU",
    "probability_on_time": 0.6842,
    "probability_late": 0.3158,
    "risk_level": "LOW",
    "risk_label": "Risiko Rendah",
    "model": "Logistic Regression"
  }
}
```

---

## 7. Pembahasan & Rekomendasi Pengembangan (Future Work)

### 7.1. Pembahasan Praktis (Business Insights)
1. **Pentingnya Membatasi Siklus Revisi**: Koefisien negatif signifikan pada `revision_count` ($-1.7705$) dan penalti waktu ($+10.2$ hari per revisi) membuktikan bahwa hambatan utama skripsi adalah kebuntuan pada revisi proposal/naskah. Fitur feedback terstruktur pada SkripsiFlow terbukti krusial.
2. **Kombinasi Dual-Model**: Linear regression memberikan angka eksak hari pengerjaan, sementara Logistic regression memberikan *sense of urgency* melalui indikator risiko merah/kuning/hijau pada aplikasi Flutter.

### 7.2. Rekomendasi Pengembangan
- **Penyesuaian Kalender Libur/Akademik**: Memperhitungkan jeda semester dan hari libur nasional ke dalam perhitungan `avg_days_per_stage`.
- **Ensemble Metrik**: Mengkombinasikan Logistic Regression dengan model *Tree-based* (seperti XGBoost atau Random Forest) apabila volume dataset riil telah mencapai ribuan data untuk menangkap interaksi non-linier yang lebih kompleks.
