# LAPORAN TEKNIS MACHINE LEARNING (BAGIAN 2)
## Pra-Evaluasi Kualitas dan Kelayakan Pengajuan Topik Skripsi Menggunakan Natural Language Processing dan Multinomial Naive Bayes
### Penerapan Text Mining pada Platform SkripsiFlow

---

| Metadata Dokumen | Informasi |
| :--- | :--- |
| **Topik Proyek** | Pra-Evaluasi Otomatis Proposal Topik Skripsi Mahasiswa |
| **Algoritma** | **Multinomial Naive Bayes (MNB)** dengan **TF-IDF N-gram Vectorizer** |
| **Modul Terkait** | `ml_api/models/naive_bayes_model.py`, `ml_api/data/generate_training_data.py` |
| **API Endpoints** | `POST /predict/topic-quality` |
| **Status Pemodelan** | Production Ready / Trained & Evaluated |

---

## 1. Ringkasan Eksekutif (Executive Summary)

Tahap awal pengerjaan skripsi sering kali terhambat oleh proses peninjauan proposal judul yang memakan waktu berulang-ulang (*repetitive review cycle*). Banyak mahasiswa mengajukan topik dengan judul yang terlalu dangkal, latar belakang tanpa urgensi data, rumusan masalah yang tidak jelas, atau metodologi yang tidak ilmiah, sehingga membebani waktu dosen pembimbing dan koordinator program studi.

Laporan ini memaparkan pengembangan modul **Pra-Evaluasi Kualitas Topik Skripsi** menggunakan pendekatan Natural Language Processing (NLP) berbasis **Multinomial Naive Bayes (MNB)** yang diperkuat dengan penyaringan aturan heuristik (*rule-based pre-validation & gibberish detector*). 

Model dilatih menggunakan representasi term weighting **TF-IDF dengan Unigram & Bigram ($1, 2$)** pada korpus teks bahasa Indonesia akademik. Pada pengujian data uji tersamar (*stratified test set*), model mencapai **akurasi sebesar 96.67%**, dengan detail:
- **Kelas REJECTED**: Presisi **100.0%**, Recall **100.0%**, F1-Score **100.0%**.
- **Kelas APPROVED**: Presisi **100.0%**, Recall **91.67%**, F1-Score **95.65%**.
- **Kelas REVISION**: Presisi **91.30%**, Recall **100.0%**, F1-Score **95.45%**.

Sistem ini bertindak sebagai filter cerdas pertama pada aplikasi SkripsiFlow sebelum berkas pengajuan masuk ke antrean persetujuan dosen pembimbing.

---

## 2. Latar Belakang & Perumusan Masalah

Pada alur konvensional, penolakan judul topik skripsi sering kali baru diketahui mahasiswa setelah menunggu jadwal review dosen selama 1-2 minggu. Hal ini memicu frustrasi dan menghabiskan sisa waktu semester.

Tujuan dari modul Naive Bayes ini adalah:
1. **Penyaringan Instan (Instant Feedback)**: Memberikan estimasi status kelayakan awal (*APPROVED*, *REVISION*, atau *REJECTED*) beserta rekomendasi tindakan perbaikan dalam hitungan detik pasca pengetikan formulir.
2. **Pencegahan Teks Sampah (Spam & Gibberish Protection)**: Mencegah mahasiswa mengirimkan teks sembarangan, pengetikan acak (*keyboard smashing*), atau teks yang terlalu singkat untuk lolos ke basis data.
3. **Standarisasi Penilaian**: Menilai keselarasan dan kelengkapan empat komponen wajib proposal: Judul (*Title*), Latar Belakang (*Background*), Rumusan Masalah (*Problem Formulation*), dan Metodologi (*Methodology*).

---

## 3. Dataset & Prapemrosesan Teks (NLP Pipeline)

### 3.1. Struktur Data Proposal
Dataset mencakup $N = 300$ sampel proposal penelitian berbahasa Indonesia dengan label status bertingkat:
- **`APPROVED`**: Topik matang, memuat data kuantitatif, referensi ilmiah, metodologi baku (misal: CRISP-DM, R&D, Agile Scrum, Microservices), dan rumusan masalah terukur.
- **`REVISION`**: Topik memiliki potensi namun judul terlalu umum (misal: *"Website e-commerce sederhana"*), latar belakang minim sitasi, atau metodologi belum dijabarkan spesifik.
- **`REJECTED`**: Topik sangat dangkal, hanya berupa frasa tidak ilmiah (misal: *"Membuat website"*, *"Belajar machine learning"*), atau teks asal-asalan.

### 3.2. Pra-Validasi Heuristik & Deteksi Gibberish
Sebelum teks diproses oleh model vektor TF-IDF, sistem mengeksekusi fungsi filter `_check_minimum_quality()` dan `_is_gibberish()`:
1. **Panjang Kata Minimum**:
   - Judul: minimal 3 kata.
   - Latar Belakang: minimal 10 kata.
   - Rumusan Masalah: minimal 5 kata.
   - Metodologi: minimal 5 kata.
2. **Deteksi Teks Acak (Gibberish Heuristic)**:
   - Menghitung rata-rata panjang karakter per kata ($\text{avg\_len} > 15$ dianggap anomali teks acak).
   - Memvalidasi keunikan karakter pada setiap kata ($\ge 3$ karakter unik) guna memfilter masukan seperti *"aaaaa"*, *"asdfghjk"*, atau *"fsfsfsfs"*.
   - Jika lolos uji, keempat kolom teks digabungkan menjadi satu representasi `combined_text`.

### 3.3. Ekstraksi Fitur TF-IDF (Term Frequency - Inverse Document Frequency)
Pipeline pemodelan menggunakan `TfidfVectorizer`:
$$\text{TF-IDF}(t, d, D) = \text{TF}(t, d) \times \text{IDF}(t, D)$$
$$\text{IDF}(t, D) = \log\left(\frac{1 + |D|}{1 + |\{d \in D : t \in d\}|}\right) + 1$$

Konfigurasi Vectorizer:
- **`max_features`**: 5,000 term.
- **`ngram_range`**: $(1, 2)$ — Menangkap kata tunggal (*unigram*) sekaligus pasangan kata (*bigram*) seperti *"machine learning"*, *"rekayasa perangkat"*, *"sistem pakar"*.
- **`min_df`**: 2 — Menyingkirkan kata asing yang hanya muncul satu kali (*typo outliers*).
- **Hasil Ukuran Kosakata Terbentuk (`vocabulary_size`)**: **1,095 lema / n-gram unik**.

---

## 4. Landasan Teori Algoritma Multinomial Naive Bayes

Multinomial Naive Bayes didasarkan pada Teorema Bayes dengan asumsi independensi bersyarat (*conditional independence*) antar fitur kata:

$$P(C_k \mid X) = \frac{P(C_k) \prod_{i=1}^{m} P(w_i \mid C_k)^{f_i}}{P(X)}$$

Di mana:
- $C_k \in \{\text{APPROVED}, \text{REVISION}, \text{REJECTED}\}$ adalah kelas status.
- $X = (w_1, w_2, \dots, w_m)$ adalah vektor frekuensi kata dalam dokumen.
- $P(C_k)$ adalah probabilitas prior dari kelas $C_k$.
- $P(w_i \mid C_k)$ adalah probabilitas kemunculan kata $w_i$ pada dokumen berkategori $C_k$.

### Laplace Smoothing (Penghalusan Peluang)
Untuk menghindari probabilitas bernilai nol (*zero probability problem*) ketika kata uji belum pernah muncul pada korpus kelas tertentu saat fase pelatihan, diterapkan Laplace Smoothing dengan parameter $\alpha = 0.1$:

$$\hat{P}(w_i \mid C_k) = \frac{N_{ki} + \alpha}{N_k + \alpha |V|}$$
Di mana:
- $N_{ki}$ adalah total kemunculan kata $w_i$ pada kelas $C_k$.
- $N_k$ adalah total seluruh kata pada kelas $C_k$.
- $|V|$ adalah ukuran total kosakata ($1,095$).
- $\alpha = 0.1$ dipilih sebagai *Lidstone smoothing factor* untuk memberi toleransi adaptif pada korpus berukuran sedang.

---

## 5. Hasil Pengujian & Evaluasi Kinerja

Data uji dievaluasi menggunakan pembagian bertingkat (*stratified split 80:20*) sebanyak **$60$ sampel teks pengajuan uji**.

### 5.1. Matriks Evaluasi Klasifikasi

| Status Kelas | Precision | Recall | F1-Score | Jumlah Sampel Uji (Support) |
| :--- | :---: | :---: | :---: | :---: |
| **`APPROVED`** | **$1.0000$ (100.0%)** | **$0.9167$ (91.67%)** | **$0.9565$ (95.65%)** | 24 |
| **`REVISION`** | **$0.9130$ (91.30%)** | **$1.0000$ (100.0%)** | **$0.9545$ (95.45%)** | 21 |
| **`REJECTED`** | **$1.0000$ (100.0%)** | **$1.0000$ (100.0%)** | **$1.0000$ (100.0%)** | 15 |
| **Rata-rata Akurasi Total** | — | — | **$96.67\%$** | **Total = 60** |

### 5.2. Matriks Konfusi (Confusion Matrix)

Matriks konfusi pengujian menunjukkan distribusi prediksi model:

```
                  Prediksi APPROVED    Prediksi REVISION    Prediksi REJECTED
Aktual APPROVED          22                    2                    0
Aktual REVISION           0                   21                    0
Aktual REJECTED           0                    0                   15
```

#### Analisis Kesalahan Klasifikasi (Error Analysis):
1. **Keamanan Ekstrem pada Penolakan (`REJECTED`)**:
   - $15$ dari $15$ proposal berkualitas buruk atau dangkal berhasil ditolak sempurna ($100\%$ akurat). Tidak ada satupun proposal buruk yang lolos ke `APPROVED` atau `REVISION` (False Negative = 0).
2. **Karakteristik Transisi `APPROVED` $\rightarrow$ `REVISION`**:
   - Terdapat **2 sampel** yang berstatus aktual `APPROVED` namun diprediksi sebagai `REVISION` oleh model.
   - **Penyebab**: Sampel tersebut menggunakan kata-kata umum yang memiliki bobot TF-IDF beririsan dengan naskah revisi (misal frasa *"analisis sistem"* atau *"pengembangan modul"* tanpa menyebutkan algoritma lanjutan spesifik).
   - **Dampak Bisnis**: Kesalahan ini tergolong *benign* (tidak fatal), karena sistem hanya menyarankan perbaikan penjelasan alih-alih menolak proposal. Tidak ada proposal layak yang langsung ditolak (*zero rejection of good proposals*).

---

## 6. Implementasi & Integrasi Sistem (API Deployment)

Model disimpan dalam satu berkas pipeline terintegrasi `ml_api/saved_models/naive_bayes_pipeline.joblib`. 

FastAPI menyediakan endpoint `POST /predict/topic-quality`. Model tidak hanya mengembalikan label tunggal, melainkan distribusi probabilitas lengkap dan umpan balik otomatis (*constructive automated feedback*).

### 6.1. Contoh Request Input (Proposal Berkualitas Baik)
```json
{
  "title": "Implementasi Algoritma Machine Learning untuk Prediksi Kelulusan Mahasiswa Berdasarkan Data Akademik",
  "background": "Perkembangan teknologi AI memberikan dampak signifikan pada sektor pendidikan tinggi. Tingkat kelulusan tepat waktu menjadi salah satu indikator akreditasi perguruan tinggi.",
  "problem_formulation": "Bagaimana merancang model prediksi yang akurat untuk memprediksi kelulusan mahasiswa berdasarkan data aktivitas akademik?",
  "methodology": "Penelitian ini menggunakan metode CRISP-DM dengan algoritma Random Forest dan SVM, dievaluasi dengan confusion matrix dan 10-fold cross validation."
}
```

### 6.2. Contoh Response JSON
```json
{
  "success": true,
  "data": {
    "predicted_status": "APPROVED",
    "predicted_label": "Topik layak diterima",
    "probabilities": {
      "APPROVED": 0.8841,
      "REVISION": 0.1152,
      "REJECTED": 0.0007
    },
    "feedback": "Topik skripsi kamu sudah cukup lengkap dan memenuhi standar. Lanjutkan ke tahap berikutnya!",
    "model": "Naive Bayes (Multinomial)"
  }
}
```

### 6.3. Contoh Penanganan Masukan Rusak (Pre-Validation Gibberish)
Bila mahasiswa memasukkan judul `"asdfghjkl zxcvbnm"`:
```json
{
  "success": true,
  "data": {
    "predicted_status": "REJECTED",
    "predicted_label": "Topik ditolak",
    "probabilities": {
      "APPROVED": 0.0,
      "REVISION": 0.05,
      "REJECTED": 0.95
    },
    "feedback": "Input tidak valid: Judul tidak dapat dikenali. Gunakan kalimat yang bermakna.",
    "model": "Naive Bayes (Multinomial) — Pre-validation"
  }
}
```

---

## 7. Kesimpulan & Rekomendasi Pengembangan (Future Work)

### 7.1. Kesimpulan
Implementasi Multinomial Naive Bayes yang dikombinasikan dengan TF-IDF N-gram dan pra-validasi heuristik terbukti sangat efektif (**Akurasi 96.67%**) dalam memilah proposal skripsi. Sistem mampu mengamankan dosen dari pengajuan naskah sampah serta membimbing mahasiswa untuk melengkapi deskripsi metode sebelum proses review resmi dimulai.

### 7.2. Rencana Peningkatan (Next Iterations)
1. **Stemming & Lemmatisasi Bahasa Indonesia**: Integrasi pustaka Sastrawi untuk mereduksi variasi kata berimbuhan ke kata dasar.
2. **Pengecekan Plagiarisme Dini**: Menambahkan modul perbandingan Cosine Similarity terhadap korpus skripsi alumni yang telah tersimpan di Supabase database.
