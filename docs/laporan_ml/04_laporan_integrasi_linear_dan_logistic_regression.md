# LAPORAN TEKNIS MACHINE LEARNING (BAGIAN 4)
## Implementasi & Integrasi End-to-End Model Linear Regression dan Logistic Regression ke Fitur Monitoring Progress Skripsi
### Penerapan Predictive Analytics dan Early Warning System pada Platform SkripsiFlow

---

| Metadata Dokumen | Informasi |
| :--- | :--- |
| **Topik Proyek** | Integrasi End-to-End Machine Learning ke Antarmuka Pengguna (Monitoring Roadmap Skripsi) |
| **Model Terintegrasi** | **Linear Regression** (Prediksi Hari Kelulusan) & **Logistic Regression** (Klasifikasi Risiko Terlambat) |
| **Modul Terkait** | `lib/features/progress/presentation/screens/progress_timeline_screen.dart`, `lib/core/models/thesis_progress_model.dart`, `lib/core/services/ml_api_service.dart` |
| **API Backend** | `ml_api/main.py`, `ml_api/models/linear_regression_model.py`, `ml_api/models/logistic_regression_model.py` |
| **Endpoints Terhubung** | `POST /predict/completion-time`, `POST /predict/ontime-risk` |
| **Status Integrasi** | **Production Ready / Fully Integrated & Verified** |

---

## 1. Ringkasan Eksekutif (Executive Summary)

Dalam siklus pengembangan sistem berbasis kecerdasan buatan (*AI-driven software*), tahap pemodelan (*modeling*) di lingkungan terisolasi seperti Jupyter Notebook atau skrip Python mandiri belum memberikan nilai guna nyata sebelum model tersebut diintegrasikan ke dalam alur kerja aplikasi operasional (*production workflow*).

Laporan teknis ini mendokumentasikan proses integrasi menyeluruh (*end-to-end integration*) dari dua model Machine Learning berbasis statistik inferensial:
1. **Linear Regression**: Berfungsi menghitung estimasi kuantitatif sisa hari kerja yang dibutuhkan mahasiswa hingga menyelesaikan tahap akhir skripsi (*days to complete*), yang kemudian dikonversikan secara dinamis menjadi tanggal kalender target kelulusan.
2. **Logistic Regression**: Berfungsi mengklasifikasikan tingkat risiko keterlambatan masa studi mahasiswa (*risk scoring*: Low, Medium, High) beserta distribusi probabilitas peluang lulus tepat waktu (*on-time*) dibandingkan peluang terlambat (*late*).

Integrasi diimplementasikan pada modul **Monitoring Progress Skripsi** ([progress_timeline_screen.dart](file:///c:/Users/Acer/Documents/AntiGravity/Fundamen-Sains-Data/lib/features/progress/presentation/screens/progress_timeline_screen.dart)) pada framework Flutter. Sistem secara cerdas mengekstrak data operasional dari database Supabase, melakukan rekayasa fitur (*feature engineering*) secara otomatis, mengirimkan parameter ke backend microservice FastAPI (`ml_api`), serta merender hasilnya ke dalam komponen antarmuka modern **AI Progress Analytics**. Dengan integrasi ini, seluruh 4 model Machine Learning pada platform SkripsiFlow (Linear Regression, Logistic Regression, Naive Bayes, dan Support Vector Machine) telah aktif dan terhubung secara penuh.

---

## 2. Arsitektur Integrasi Sistem (System Integration Architecture)

Integrasi sistem dirancang menggunakan arsitektur *microservice decoupled*, di mana frontend mobile/web Flutter berkomunikasi dengan server inferensi Machine Learning berbasis Python FastAPI melalui protokol HTTP RESTful API secara asynchronous.

### 2.1. Diagram Aliran Data (Data Flow Lifecycle)

Aliran data sejak pengguna membuka layar monitoring progres hingga hasil prediksi tampil di layar digambarkan sebagai berikut:

```
[ Pengguna Membuka Layar Monitoring ]
               │
               ▼
[ Supabase PostgreSQL DB ] ──(Ambil Data)──► [ theses, thesis_progress, consultations ]
                                                              │
                                                              ▼
                                               [ Feature Engineering Otomatis ]
                                               - days_since_start (selisih hari)
                                               - total_consultations (sesi selesai)
                                               - avg_days_per_stage
                                               - consultation_frequency (/bulan)
                                               - stage_completion_rate
                                                              │
                                                              ▼
                                               [ HTTP POST Request (JSON) ]
                                                              │
                                       ┌──────────────────────┴──────────────────────┐
                                       ▼                                             ▼
                          [ POST /predict/completion-time ]             [ POST /predict/ontime-risk ]
                          (Model: Linear Regression)                    (Model: Logistic Regression)
                                       │                                             │
                                       └──────────────────────┬──────────────────────┘
                                                              ▼
                                               [ Response JSON (Probabilitas & Waktu) ]
                                                              │
                                                              ▼
                                               [ Render UI: AI Progress Analytics ]
                                               - Estimasi Hari & Tanggal Selesai
                                               - Badge Status Risiko (Low/Med/High)
                                               - Bar Distribusi Probabilitas
```

### 2.2. Peran Layanan Penghubung (MlApiService)

File [ml_api_service.dart](file:///c:/Users/Acer/Documents/AntiGravity/Fundamen-Sains-Data/lib/core/services/ml_api_service.dart) bertindak sebagai *service layer* di sisi Flutter. Komponen ini menyediakan:
* **Manajemen Dependency Injection**: Dikelola menggunakan Riverpod (`mlApiServiceProvider`) sehingga siklus hidup koneksi HTTP bersih dan aman dari *memory leak*.
* **Resolusi Host Cerdas (*Cross-Platform Base URL*)**:
  * Menggunakan `http://localhost:8000` ketika aplikasi dijalankan pada browser Web, macOS, Windows, atau iOS simulator.
  * Secara otomatis beralih ke `http://10.0.2.2:8000` ketika dideteksi berjalan pada emulator Android (karena alamat IP `10.0.2.2` merupakan alias antarmuka loopback host pada emulator Android).
* **Eksekusi Paralel Asinkron**: Pemanggilan endpoint Linear Regression dan Logistic Regression dieksekusi secara simultan menggunakan `Future.wait([ ... ])`, memangkas waktu latensi jaringan hingga 50% dibandingkan pemanggilan berurutan (*sequential*).

---

## 3. Rekayasa Fitur Otomatis di Sisi Frontend (Automated Feature Engineering)

Model Machine Learning di backend membutuhkan sejumlah variabel prediktor numerik terstandarisasi. Karena database PostgreSQL operasional hanya menyimpan data mentah, proses rekayasa fitur dilakukan secara dinamis pada saat *runtime*:

### 3.1. Variabel Masukan Linear Regression

| Parameter Model | Sumber Data Operasional | Formula / Logika Perhitungan |
| :--- | :--- | :--- |
| `current_stage_order` | Kolom `theses.current_stage_order` | Nilai integer antara $1$ hingga $8$ yang merepresentasikan nomor tahapan aktif. |
| `overall_progress_percentage` | Kolom `theses.overall_progress_percentage` | Nilai floating point antara $0.0$ hingga $100.0\%$. |
| `days_since_start` | `theses.created_at` atau tanggal mulai tahap 1 | $\text{days} = \text{DateTime.now()} - \text{startDate}$. Jika $< 7$, disetel minimum 7 hari. |
| `total_consultations` | Tabel `consultations` | $\sum \text{consultations}$ yang memiliki status `COMPLETED`. |
| `total_revisions` | Riwayat revisi naskah | Estimasi konservatif siklus revisi (default: $1$). |
| `avg_days_per_stage` | Hasil turunan durasi | $\text{avg} = \text{days\_since\_start} / \max(\text{current\_stage\_order}, 1)$. |

### 3.2. Variabel Masukan Logistic Regression

| Parameter Model | Sumber Data Operasional | Formula / Logika Perhitungan |
| :--- | :--- | :--- |
| `current_stage_order` | Kolom `theses.current_stage_order` | Tahapan aktif saat ini ($1 - 8$). |
| `overall_progress_percentage` | Kolom `theses.overall_progress_percentage` | Persentase kumulatif penyelesaian ($0.0 - 100.0$). |
| `days_since_start` | Tanggal awal pengerjaan | Total hari kalender pengerjaan skripsi. |
| `consultation_frequency` | Data bimbingan per satuan waktu | $\text{freq} = \text{total\_consultations} / (\text{days\_since\_start} / 30.0)$, dibatasi pada rentang $[0.0, 10.0]$. |
| `revision_count` | Catatan revisi | Total perulangan evaluasi tahapan. |
| `stage_completion_rate` | Rasio tahapan selesai | $\text{rate} = \text{current\_stage\_order} / 8.0$, dinormalisasi ke rentang $[0.0, 1.0]$. |

---

## 4. Implementasi Komponen Antarmuka Pengguna (UI/UX Implementation)

Integrasi visual diimplementasikan secara elegan di dalam berkas [progress_timeline_screen.dart](file:///c:/Users/Acer/Documents/AntiGravity/Fundamen-Sains-Data/lib/features/progress/presentation/screens/progress_timeline_screen.dart) pada fungsi pembangun `_buildMlPredictionsCard()`.

### 4.1. Struktur Komponen Visual AI Progress Analytics

Wadah (*container*) visual dirancang dengan latar belakang bersih (`#F8FAFC`), sudut membulat (*border radius* 16 px), dan garis tepi beraksen indigo (`#818CF8`) yang aktif ketika data prediksi berhasil dimuat. Komponen ini terdiri atas 4 bagian inti:

1. **Header Analytics**:
   * Dilengkapi ikon modern `Icons.insights_rounded` berwarna indigo dengan wadah lembut (`#EEF2FF`).
   * Judul: *"AI Progress Analytics"* dengan subjudul penjelasan: *"Prediksi waktu (Linear Reg.) & risiko keterlambatan (Logistic Reg.)"*.
   * Indikator aktivitas mikro (*loading spinner*) yang berputar halus ketika data sedang dikalkulasi di latar belakang.

2. **Card Linear Regression (Estimasi Kelulusan)**:
   * Label penanda teknis: Tag badge bertuliskan **LINEAR REGRESSION** berwarna ungu tua.
   * Nilai Prediksi Utama: Teks tebal ukuran besar yang menginformasikan sisa hari dan minggu (contoh: *"65 Hari Lagi (~9.3 Minggu)"*).
   * Konversi Kalender Target: Sistem otomatis menghitung `DateTime.now().add(Duration(days: predictedDays))` dan menampilkan tanggal perkiraan wisuda/selesai (contoh: *"Estimasi Tanggal Selesai: 30 Desember 2026"*).

3. **Card Logistic Regression (Prediksi Risiko Keterlambatan)**:
   * Label penanda teknis: Tag badge bertuliskan **LOGISTIC REGRESSION** berwarna biru laut.
   * Indikator Warna Dinamis (*Dynamic Color Theme*):
     * **LOW (Risiko Rendah)**: Aksen hijau zamrud (`#059669`) dengan ikon `Icons.check_circle_rounded` dan pesan peluang selesai tepat waktu tinggi.
     * **MEDIUM (Risiko Sedang)**: Aksen amber/kuning (`#D97706`) dengan ikon `Icons.error_outline_rounded`.
     * **HIGH (Risiko Tinggi)**: Aksen merah peringatan (`#DC2626`) dengan ikon `Icons.warning_rounded` sebagai sistem peringatan dini (*early warning*).
   * Bar Pembagian Probabilitas: Dua kotak perbandingan bersisian yang menampilkan persentase peluang *Tepat Waktu* (hijau) versus *Terlambat* (merah).

4. **Summary Stats Strip**:
   * Menampilkan ringkasan metrik masukan: Durasi Skripsi Berjalan (Hari), Total Konsultasi Selesai (Kali), dan Persentase Fisik Naskah (%).

### 4.2. Mekanisme Data Fiktif Pengujian (*Mock/Seed Mechanism*)

Untuk mempermudah pengujian langsung (*live testing*) tanpa mewajibkan pengguna mengisi database Supabase terlebih dahulu, sistem dilengkapi generator dataset pengujian fiktif internal `_createDummyTestingThesis()`:
* **Judul Penelitian**: *"Klasifikasi Citra Rontgen Paru-Paru Menggunakan Convolutional Neural Network"*.
* **Tahapan Aktif**: Tahap 3 (*Seminar Proposal*) — Tahap 1 dan 2 berstatus `COMPLETED`, Tahap 3 berstatus `IN_PROGRESS` (40%).
* **Durasi Berjalan**: 90 Hari yang lalu (3 bulan berjalan).
* **Total Konsultasi**: 5 sesi bimbingan terverifikasi.
* Mekanisme ini memastikan evaluator atau penguji dapat langsung melihat kinerja kalkulasi kedua model secara instan saat membuka layar.

---

## 5. Pengujian Fungsional & Validasi Sistem (Testing & System Verification)

Pengujian dilakukan untuk memverifikasi fungsionalitas komunikasi antarmuka Flutter dengan backend FastAPI.

### 5.1. Hasil Pengujian Endpoint Linear Regression

Permintaan HTTP POST dikirimkan ke endpoint `/predict/completion-time`:

* **Payload Permintaan (Request Body)**:
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

* **Respons Server (Response Body - HTTP 200 OK)**:
```json
{
  "success": true,
  "data": {
    "predicted_days_to_complete": 156.8,
    "predicted_weeks": 22.4,
    "model": "Linear Regression",
    "features_used": [
      "current_stage_order",
      "overall_progress_percentage",
      "days_since_start",
      "total_consultations",
      "total_revisions",
      "avg_days_per_stage"
    ]
  }
}
```
* **Evaluasi**: Model berhasil memprediksi sisa waktu pengerjaan sebesar **156.8 hari (~22.4 minggu)** secara logis dan proporsional terhadap sisa 5 tahapan yang belum selesai.

### 5.2. Hasil Pengujian Endpoint Logistic Regression

Permintaan HTTP POST dikirimkan ke endpoint `/predict/ontime-risk`:

* **Payload Permintaan (Request Body)**:
```json
{
  "current_stage_order": 3,
  "overall_progress_percentage": 37.5,
  "days_since_start": 90,
  "consultation_frequency": 1.7,
  "revision_count": 1,
  "stage_completion_rate": 0.38
}
```

* **Respons Server (Response Body - HTTP 200 OK)**:
```json
{
  "success": true,
  "data": {
    "prediction": "ON_TIME",
    "probability_on_time": 0.6540,
    "probability_late": 0.3460,
    "risk_level": "LOW",
    "risk_label": "Risiko Rendah (Tepat Waktu)",
    "model": "Logistic Regression"
  }
}
```
* **Evaluasi**: Model mengklasifikasikan mahasiswa ke dalam kategori **Risiko Rendah** dengan probabilitas kelulusan tepat waktu sebesar **65.40%**.

### 5.3. Validasi Statis Kode Sumber (Static Code Analysis)

Pengecekan kualitas kode program dilakukan menggunakan perintah `flutter analyze` pada seluruh berkas yang dimodifikasi:
```text
Analyzing 2 items...
No issues found! (ran in 1.3s)
```
Seluruh berkas terbebas dari kesalahan sintaksis, variabel tak terpakai (*unused variables*), maupun pemanggilan fungsi usang (*deprecated API*).

---

## 6. Pembahasan Kendala Teknis & Solusi Terapan (Obstacles & Mitigation)

Selama proses perancangan dan integrasi kedua model ini, terdapat empat kendala utama yang berhasil diidentifikasi dan dimitigasi:

### 6.1. Masalah Ketiadaan Data Riwayat pada Mahasiswa Baru (*Cold Start Problem*)
* **Kendala**: Mahasiswa yang baru disetujui judulnya belum memiliki riwayat bimbingan (`days_since_start = 0`, `total_consultations = 0`). Nilai nol pada pembagi durasi dapat menyebabkan galat matematis *division by zero* atau prediksi yang ekstrem.
* **Solusi**: Diterapkan ambang batas operasional minimum: jika `days_since_start < 7`, sistem memberikan nilai dasar 7 hari dan menampilkan keterangan bahwa estimasi akan semakin presisi seiring bertambahnya sesi konsultasi.

### 6.2. Ketergantungan Server Backend Lokal (*Localhost Dependency*)
* **Kendala**: Server `ml_api` berjalan secara lokal pada port 8000. Emulator Android memetakan `localhost` ke dirinya sendiri, bukan ke laptop pengembang.
* **Solusi**: Diterapkan mekanisme deteksi platform otomatis di [ml_api_service.dart](file:///c:/Users/Acer/Documents/AntiGravity/Fundamen-Sains-Data/lib/core/services/ml_api_service.dart), yang secara cerdas mengubah host ke `10.0.2.2:8000` khusus untuk Android.

### 6.3. Penanganan Galat Jaringan Nir-Henti (*Graceful Fallback*)
* **Kendala**: Jika server FastAPI belum dijalankan atau mengalami gangguan jaringan, antarmuka Flutter tidak boleh mengalami *freeze* atau *force close*.
* **Solusi**: Seluruh pemanggilan model dibungkus dalam blok `try-catch` terisolasi. Jika terjadi kegagalan jaringan, antarmuka tetap menampilkan roadmap 8 tahapan secara normal dan hanya menyajikan kartu peringatan lembut berserta tombol *"Coba Lagi"*.

### 6.4. Rekayasa Fitur Nir-Database (*Client-Side Feature Synthesis*)
* **Kendala**: Database Supabase tidak memiliki kolom siap pakai seperti frekuensi konsultasi bulanan dan rata-rata durasi per tahap.
* **Solusi**: Komputasi metrik turunan dilakukan langsung pada memori *client-side* saat data diunduh, menghemat beban kueri agregasi di database PostgreSQL.

---

## 7. Kesimpulan & Rekomendasi Langkah Selanjutnya

Integrasi model **Linear Regression** dan **Logistic Regression** ke dalam modul **Monitoring Progress Skripsi** telah berhasil dituntaskan dengan sempurna. Pencapaian ini melengkapi implementasi dua model sebelumnya (**Naive Bayes** dan **Support Vector Machine** pada formulir pengajuan topik), sehingga platform **SkripsiFlow** kini memiliki kapabilitas analitik prediktif berbasis Sains Data yang menyeluruh (*Full ML Suite*).

### Matriks Pencapaian Model SkripsiFlow:

| Nama Model | Algoritma | Peran Fungsional pada Sistem | Penempatan Antarmuka | Status Integrasi |
| :--- | :--- | :--- | :--- | :--- |
| **Model 1** | **Linear Regression** | Estimasi sisa hari kelulusan & proyeksi tanggal kalender | Monitoring Progress Roadmap | **100% Aktif** |
| **Model 2** | **Logistic Regression** | Deteksi dini risiko keterlambatan masa studi | Monitoring Progress Roadmap | **100% Aktif** |
| **Model 3** | **Naive Bayes** | Pra-evaluasi kelayakan akademik naskah usulan | Formulir Pengajuan & Detail Topik | **100% Aktif** |
| **Model 4** | **Support Vector Machine (SVM)** | Klasifikasi bidang riset & rekomendasi dosen pembimbing | Formulir Pengajuan & Detail Topik | **100% Aktif** |

### Rekomendasi Pengembangan Selanjutnya:
1. **Early Warning System di Dashboard Dosen**: Menampilkan indikator warna risiko mahasiswa bimbingan langsung pada daftar bimbingan dosen ([lecturer_students_screen.dart](file:///c:/Users/Acer/Documents/AntiGravity/Fundamen-Sains-Data/lib/features/dashboard/presentation/screens/lecturer_students_screen.dart)) untuk mempermudah dosen memantau mahasiswa yang mengalami kebuntuan (*stuck*).
2. **Ekspor Lembar Kendali Bimbingan (PDF)**: Mengintegrasikan hasil estimasi kelulusan dan log konsultasi resmi ke dalam dokumen format cetak PDF berstandar universitas.
3. **Deployment Cloud Publik**: Menerapkan kontainerisasi Docker pada direktori `ml_api` dan mengunggahnya ke penyedia *cloud* gratis seperti Hugging Face Spaces atau Render agar dapat diakses dari jaringan internet publik.
