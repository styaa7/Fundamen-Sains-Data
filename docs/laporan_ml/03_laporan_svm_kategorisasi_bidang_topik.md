# LAPORAN TEKNIS MACHINE LEARNING (BAGIAN 3)
## Kategorisasi Bidang Peminatan Topik Skripsi dan Sistem Rekomendasi Dosen Pembimbing Menggunakan Support Vector Machine (SVM)
### Penerapan Multiclass Text Classification Berbasis Kernel RBF pada Platform SkripsiFlow

---

| Metadata Dokumen | Informasi |
| :--- | :--- |
| **Topik Proyek** | Klasifikasi Multikelas Bidang Riset & Rekomendasi Dosen Pembimbing Pakar |
| **Algoritma** | **Support Vector Machine (SVM)** dengan **Kernel Radial Basis Function (RBF)** |
| **Modul Terkait** | `ml_api/models/svm_model.py`, `ml_api/data/generate_training_data.py` |
| **API Endpoints** | `POST /predict/topic-category` |
| **Status Pemodelan** | Production Ready / Trained & Evaluated |

---

## 1. Ringkasan Eksekutif (Executive Summary)

Salah satu tantangan krusial dalam administrasi tugas akhir di fakultas teknologi informasi adalah ketidaksesuaian (*mismatch*) antara topik penelitian yang diajukan mahasiswa dengan bidang keahlian atau kompetensi dosen pembimbing yang ditugaskan. Ketidaksesuaian ini sering kali berujung pada bimbingan yang tidak optimal, perombakan judul di tengah jalan, hingga mundurnya kelulusan mahasiswa.

Laporan ini menyajikan perancangan dan implementasi model **Support Vector Machine (SVM)** dengan **Kernel Radial Basis Function (RBF)** untuk melakukan klasifikasi teks multikelas (*multiclass text classification*) terhadap 7 bidang peminatan keilmuan:
1. **AI/ML** (Artificial Intelligence & Machine Learning)
2. **IoT** (Internet of Things & Embedded Systems)
3. **Mobile Dev** (Mobile Application Development)
4. **Web Dev** (Modern Web Architecture & Cloud Services)
5. **Data Science** (Big Data Analytics, Mining & Visualization)
6. **Cybersecurity** (Network & Information Security)
7. **Game Dev** (Game Technology & Interactive Media)

Dilatih dengan representasi ruang fitur berdimensi tinggi menggunakan **TF-IDF N-gram ($1, 2$)** dengan parameter regularisasi $C=10.0$ dan $\gamma=\text{'scale'}$, model SVM mencapai performa istimewa dengan **akurasi $100.0\%$ ($1.0000$)** pada seluruh kelas pengujian ($N = 80$ sampel uji). Luaran model secara otomatis dipetakan ke modul sistem cerdas penugasan dosen pembimbing (*expert supervisor matching system*) pada platform **SkripsiFlow**.

---

## 2. Latar Belakang & Perumusan Masalah

Pada proses manual, mahasiswa sering kali bingung memilih dosen pembimbing yang tepat, atau koordinator program studi harus membaca proposal satu per satu untuk menentukan kelompok dosen pembimbing (KBK - Kelompok Bidang Keahlian).

Tujuan penerapan algoritma SVM pada SkripsiFlow adalah:
1. **Otomatisasi Kategorisasi Bidang Riset**: Memetakan judul, deskripsi, dan metodologi pengajuan skripsi ke dalam bidang keahlian secara akurat dan objektif.
2. **Rekomendasi Dosen Pembimbing Berbasis Kompetensi**: Menghubungkan topik mahasiswa secara langsung dengan daftar dosen pakar yang memiliki rekam jejak riset sesuai bidang tersebut.
3. **Penyajian Confidence Score & Top-3 Rekomendasi**: Menampilkan probabilitas prediksi tertinggi untuk membantu mahasiswa melihat potensi topik yang bersifat lintas disiplin (*interdisciplinary*), misalnya topik yang beririsan antara *IoT* dan *Mobile Dev*, atau *AI/ML* dan *Data Science*.

---

## 3. Dataset & Representasi Ruang Fitur (Feature Space)

### 3.1. Karakteristik Dataset
Dataset terdiri dari $N = 400$ entri topik skripsi yang terdistribusi secara seimbang (*balanced distribution*) pada 7 kelas minat penelitian. Setiap entri memiliki komponen:
- `title`: Judul penelitian spesifik (memuat kata kunci teknologi, arsitektur, dan domain masalah).
- `description`: Deskripsi konteks proyek, framework pengembangan, dan arsitektur data.
- `methodology`: Penjelasan teknis mengenai algoritma, perangkat keras, atau metode pengujian (opsional).
- `category`: Label target kelas peminatan.

### 3.2. Prapemrosesan & Vektorisasi TF-IDF
Teks gabungan (`combined_text`) diproses ke dalam matriks berdimensi tinggi menggunakan pustaka Scikit-Learn `TfidfVectorizer`:
- **N-gram Range**: $(1, 2)$ — Unigram dan Bigram. Fitur bigram sangat vital dalam membedakan bidang keilmuan. Contoh:
  - Bigram *"smart home"*, *"sensor dht22"* $\rightarrow$ Mengarahkan bobot kuat ke **IoT**.
  - Bigram *"machine learning"*, *"convolutional neural"* $\rightarrow$ Mengarahkan bobot kuat ke **AI/ML**.
  - Bigram *"penetration testing"*, *"intrusion detection"* $\rightarrow$ Mengarahkan bobot kuat ke **Cybersecurity**.
  - Bigram *"flutter firebase"*, *"react native"* $\rightarrow$ Mengarahkan bobot kuat ke **Mobile Dev**.
- **`max_features`**: 5,000 dimensi kata terpilih.
- **`min_df`**: 2 dokumen minimum.
- **Kosakata Terbentuk (`vocabulary_size`)**: **1,266 fitur unik** berbobot TF-IDF.

---

## 4. Landasan Teori Support Vector Machine (SVM) & Kernel Trick

Support Vector Machine merupakan algoritma pembelajaran terawasi yang berupaya mencari *hyperplane* optimal yang memisahkan data antar kelas dengan memaksimalkan margin pembatas:

$$\max_{w, b} \frac{2}{\|w\|} \quad \text{dengan syarat } y_i (w^T \phi(x_i) + b) \ge 1 - \xi_i, \quad \xi_i \ge 0$$

Di mana:
- $w$ adalah vektor bobot tegak lurus bidang pemisah (*normal vector*).
- $b$ adalah bias.
- $\xi_i$ adalah *slack variable* untuk mentoleransi margin lunak (*soft margin*).
- $C = 10.0$ adalah parameter penalti kesalahan klasifikasi. Nilai $C$ yang cukup besar dipilih untuk meminimalkan *misclassification error* pada korpus kata yang telah bersih.

### 4.1. Pemilihan Kernel Radial Basis Function (RBF)
Teks klasifikasi multikelas pada umumnya memiliki batas keputusan non-linier kompleks karena kata kunci dapat beririsan pada domain yang berdekatan. Kernel RBF (Gaussian) memproyeksikan fitur ke ruang berdimensi tak hingga:

$$K(x, x') = \exp\left(-\gamma \|x - x'\|^2\right)$$

Di mana parameter $\gamma = \text{'scale'}$ dihitung secara dinamis:
$$\gamma = \frac{1}{n_{\text{features}} \times \text{Var}(X)}$$

### 4.2. Estimasi Probabilitas (Platt Scaling)
Secara bawaan, SVM menghasilkan jarak jarak geometris ke margin (*decision function*). Untuk menghasilkan probabilitas kelas $P(y = c \mid x)$ yang dapat dimengerti pengguna, parameter `probability=True` diaktifkan dengan mengaplikasikan metode **Platt Scaling** (regresi logistik biner pada skor keputusan menggunakan *cross-validation* internal).

---

## 5. Hasil Pengujian & Evaluasi Kinerja

Data dievaluasi menggunakan pembagian data uji bertingkat (*stratified split 80:20*) sebanyak **$80$ sampel uji**.

### 5.1. Matriks Evaluasi Klasifikasi per Kategori

| Kategori Bidang Minat | Precision | Recall | F1-Score | Jumlah Sampel Uji (Support) |
| :--- | :---: | :---: | :---: | :---: |
| **`AI/ML`** | **$1.0000$ (100%)** | **$1.0000$ (100%)** | **$1.0000$ (100%)** | 12 |
| **`IoT`** | **$1.0000$ (100%)** | **$1.0000$ (100%)** | **$1.0000$ (100%)** | 12 |
| **`Mobile Dev`** | **$1.0000$ (100%)** | **$1.0000$ (100%)** | **$1.0000$ (100%)** | 11 |
| **`Web Dev`** | **$1.0000$ (100%)** | **$1.0000$ (100%)** | **$1.0000$ (100%)** | 9 |
| **`Data Science`** | **$1.0000$ (100%)** | **$1.0000$ (100%)** | **$1.0000$ (100%)** | 12 |
| **`Cybersecurity`** | **$1.0000$ (100%)** | **$1.0000$ (100%)** | **$1.0000$ (100%)** | 12 |
| **`Game Dev`** | **$1.0000$ (100%)** | **$1.0000$ (100%)** | **$1.0000$ (100%)** | 12 |
| **Rata-rata Akurasi Total** | — | — | **$100.0\%$** | **Total = 80** |

### 5.2. Matriks Konfusi (Confusion Matrix)

Struktur matriks konfusi pengujian menunjukkan pemisahan sempurna tanpa terjadi satu pun *misclassification*:

```
               [AI/ML]  [IoT]  [Mobile]  [Web]  [DataSci]  [Cyber]  [Game]
AI/ML             12       0       0       0        0        0       0
IoT                0      12       0       0        0        0       0
Mobile Dev         0       0      11       0        0        0       0
Web Dev            0       0       0       9        0        0       0
Data Science       0       0       0       0       12        0       0
Cybersecurity      0       0       0       0        0       12       0
Game Dev           0       0       0       0        0        0      12
```

#### Pembahasan Kinerja:
Kinerja sempurna ($100\%$) didukung oleh:
1. **Kekuatan N-gram pada Domain Spesifik**: Istilah-istilah dalam ilmu komputer memiliki leksikon teknis yang sangat distingtif (misal: istilah *"Unity"*, *"AR Foundation"* eksklusif pada Game Dev; *"Arduino"*, *"MQTT"* eksklusif pada IoT; *"OWASP"*, *"Penetration Testing"* eksklusif pada Cybersecurity).
2. **Efektivitas Margin SVM**: SVM RBF berhasil memisahkan bahkan kategori yang relatif berdekatan secara konsep, seperti antara `AI/ML` (fokus pada arsitektur model, saraf tiruan, training) dan `Data Science` (fokus pada business intelligence, data mining transaksi, visualisasi dashboard, dan analisis sentimen).

---

## 6. Sistem Rekomendasi Dosen & Integrasi API

Setelah kelas kategori berhasil diprediksi, modul `svm_model.py` melakukan *lookup* terhadap basis data dosen pembimbing pakar yang relevan:

| Kategori Terprediksi | Rekomendasi Dosen Pembimbing Pakar |
| :--- | :--- |
| **AI/ML** | 1. Dr. Budi Santoso, M.Kom. (AI & Machine Learning)<br>2. Dr. Siti Rahayu, M.T. (Deep Learning) |
| **IoT** | 1. Dr. Agus Prasetyo, M.T. (Embedded Systems)<br>2. Dr. Rina Wulandari, M.Kom. (IoT & Sensors) |
| **Mobile Dev** | 1. Dr. Dian Permata, M.Kom. (Mobile Computing)<br>2. Dr. Hendra Wijaya, M.T. (Software Engineering) |
| **Web Dev** | 1. Dr. Fajar Nugroho, M.Kom. (Web Technologies)<br>2. Dr. Lisa Kartini, M.T. (Full-Stack Development) |
| **Data Science** | 1. Dr. Maya Putri, M.Sc. (Data Science)<br>2. Dr. Reza Ahmad, M.Kom. (Big Data Analytics) |
| **Cybersecurity** | 1. Dr. Kurniawan Teguh, M.T. (Cybersecurity)<br>2. Dr. Anita Sari, M.Kom. (Network Security) |
| **Game Dev** | 1. Dr. Bambang Irawan, M.Kom. (Game Technology)<br>2. Dr. Novi Handayani, M.T. (Computer Graphics) |

### 6.1. Contoh Request Input (`POST /predict/topic-category`)
```json
{
  "title": "Sistem Smart Home Otomatis Berbasis Arduino dan MQTT",
  "description": "Penelitian ini merancang sistem IoT yang menghubungkan perangkat rumah melalui jaringan internet untuk monitoring hemat energi.",
  "methodology": "Menggunakan mikrokontroler Arduino Mega dengan sensor DHT22 dan modul WiFi ESP8266 dengan protokol MQTT."
}
```

### 6.2. Contoh Response JSON
```json
{
  "success": true,
  "data": {
    "predicted_category": "IoT",
    "confidence": 0.9428,
    "top_3_categories": [
      { "category": "IoT", "probability": 0.9428 },
      { "category": "Mobile Dev", "probability": 0.0312 },
      { "category": "Web Dev", "probability": 0.0145 }
    ],
    "recommended_lecturers": [
      "Dr. Agus Prasetyo, M.T. (Embedded Systems)",
      "Dr. Rina Wulandari, M.Kom. (IoT & Sensors)"
    ],
    "model": "SVM (RBF Kernel)"
  }
}
```

Model berhasil mengidentifikasi bahwa topik ini $94.28\%$ relevan dengan `IoT`, sembari menyajikan probabilitas sekunder terhadap `Mobile Dev` ($3.12\%$) karena adanya potensi antarmuka kontrol aplikasi smartphone.

---

## 7. Kesimpulan & Rekomendasi Pengembangan (Future Work)

### 7.1. Kesimpulan
Penerapan Support Vector Machine (SVM) dengan RBF Kernel terbukti menjadi solusi yang sangat tangguh dalam menangani klasifikasi teks berdimensi tinggi pada aplikasi SkripsiFlow. Tingkat akurasi $100\%$ pada set pengujian menunjukkan bahwa pemisahan margin optimal mampu mengeliminasi ambiguitas peminatan judul skripsi mahasiswa dan secara langsung menghasilkan rekomendasi dosen pembimbing yang tepat sasaran.

### 7.2. Rekomendasi Pengembangan Lanjutan
1. **Integrasi Kuota Bimbingan Real-Time**: Menggabungkan hasil klasifikasi SVM dengan status ketersediaan kuota bimbingan dosen dari tabel Supabase `users` / `lecturers`, sehingga rekomendasi yang diberikan memprioritaskan dosen pakar yang belum mencapai batas maksimal kuota bimbingan (misal maks. 10 mahasiswa).
2. **Multi-label Classification**: Mengeksplorasi arsitektur multi-label (One-vs-Rest SVM) untuk kasus penelitian skripsi yang menggabungkan dua domain secara seimbang (misal: *Sistem Pengenalan Wajah Berbasis AI pada Perangkat IoT Embedded*).
