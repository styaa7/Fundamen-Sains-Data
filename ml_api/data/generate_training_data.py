"""
Generate synthetic training data for SkripsiFlow ML models.
Data is modeled after the SkripsiFlow database schema to ensure realism.
"""

import pandas as pd
import numpy as np
import os
import json

np.random.seed(42)

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "data")
os.makedirs(OUTPUT_DIR, exist_ok=True)


# =============================================================================
# 1. DATA FOR LINEAR REGRESSION — Prediksi Waktu Penyelesaian Skripsi
# =============================================================================
def generate_completion_time_data(n=500):
    """
    Features:
      - current_stage_order (1-8)
      - overall_progress_percentage (0-100)
      - days_since_start (how many days since thesis started)
      - total_consultations (number of consultations done)
      - total_revisions (number of topic revisions)
      - avg_days_per_stage (average days spent per completed stage)
    Target:
      - days_to_complete (number of days until thesis is fully complete)
    """
    data = []
    for _ in range(n):
        current_stage = np.random.randint(1, 9)
        progress = np.clip(current_stage * 12.5 + np.random.normal(0, 5), 0, 100)
        days_since_start = int(current_stage * np.random.uniform(15, 45) + np.random.normal(0, 10))
        days_since_start = max(7, days_since_start)
        total_consultations = int(np.random.poisson(current_stage * 1.5))
        total_revisions = np.random.randint(0, 4)
        avg_days_per_stage = days_since_start / max(current_stage, 1)

        # Target: days to complete — inversely related to progress, 
        # positively related to avg_days_per_stage and revisions
        remaining_stages = 8 - current_stage
        base_days = remaining_stages * avg_days_per_stage
        revision_penalty = total_revisions * np.random.uniform(5, 15)
        consultation_bonus = total_consultations * np.random.uniform(-1, -0.3)
        noise = np.random.normal(0, 10)
        days_to_complete = max(0, base_days + revision_penalty + consultation_bonus + noise)

        data.append({
            "current_stage_order": current_stage,
            "overall_progress_percentage": round(progress, 2),
            "days_since_start": days_since_start,
            "total_consultations": total_consultations,
            "total_revisions": total_revisions,
            "avg_days_per_stage": round(avg_days_per_stage, 2),
            "days_to_complete": round(days_to_complete, 1),
        })

    df = pd.DataFrame(data)
    df.to_csv(os.path.join(OUTPUT_DIR, "completion_time_data.csv"), index=False)
    print(f"✅ Generated {n} samples → completion_time_data.csv")
    return df


# =============================================================================
# 2. DATA FOR LOGISTIC REGRESSION — Prediksi Kelulusan Tepat Waktu
# =============================================================================
def generate_ontime_prediction_data(n=500):
    """
    Features:
      - current_stage_order (1-8)
      - overall_progress_percentage (0-100)
      - days_since_start
      - consultation_frequency (consultations per month)
      - revision_count
      - stage_completion_rate (completed stages / expected stages by now)
    Target:
      - on_time (1 = tepat waktu, 0 = terlambat)
    """
    data = []
    for _ in range(n):
        current_stage = np.random.randint(1, 9)
        progress = np.clip(current_stage * 12.5 + np.random.normal(0, 8), 0, 100)
        days_since_start = int(np.random.uniform(30, 365))
        months_elapsed = max(1, days_since_start / 30)
        total_consultations = int(np.random.poisson(months_elapsed * 1.2))
        consultation_freq = total_consultations / months_elapsed
        revision_count = np.random.randint(0, 5)

        # Expected stage based on time elapsed (assume 6 months = 180 days for 8 stages)
        expected_stage = min(8, int(days_since_start / 22.5) + 1)
        stage_completion_rate = current_stage / max(expected_stage, 1)

        # Probability of on-time: high progress, high consultation, low revisions, high rate
        logit = (
            0.5 * (progress / 100)
            + 0.3 * min(consultation_freq, 3) / 3
            - 0.4 * (revision_count / 4)
            + 0.6 * min(stage_completion_rate, 1.5)
            - 0.3
            + np.random.normal(0, 0.15)
        )
        prob = 1 / (1 + np.exp(-logit * 5))
        on_time = 1 if prob > 0.5 else 0

        data.append({
            "current_stage_order": current_stage,
            "overall_progress_percentage": round(progress, 2),
            "days_since_start": days_since_start,
            "consultation_frequency": round(consultation_freq, 2),
            "revision_count": revision_count,
            "stage_completion_rate": round(stage_completion_rate, 2),
            "on_time": on_time,
        })

    df = pd.DataFrame(data)
    df.to_csv(os.path.join(OUTPUT_DIR, "ontime_prediction_data.csv"), index=False)
    print(f"✅ Generated {n} samples → ontime_prediction_data.csv")
    return df


# =============================================================================
# 3. DATA FOR NAIVE BAYES — Klasifikasi Kualitas Topik Skripsi
# =============================================================================
def generate_topic_quality_data(n=300):
    """
    Features: combined text of title + background + problem_formulation + methodology
    Target: status (APPROVED, REVISION, REJECTED)
    """
    # Template components for generating realistic Indonesian thesis proposals
    titles_approved = [
        "Implementasi Algoritma Machine Learning untuk Prediksi Kelulusan Mahasiswa Berdasarkan Data Akademik",
        "Perancangan Sistem Informasi Manajemen Perpustakaan Digital Berbasis Web dengan Framework Laravel",
        "Analisis Sentimen Media Sosial Twitter terhadap Kebijakan Pendidikan Menggunakan Natural Language Processing",
        "Pengembangan Aplikasi Mobile E-Commerce dengan Integrasi Payment Gateway dan Sistem Rekomendasi",
        "Penerapan Deep Learning untuk Deteksi Dini Penyakit Tanaman Padi Melalui Citra Daun",
        "Sistem Pendukung Keputusan Pemilihan Beasiswa dengan Metode AHP dan TOPSIS",
        "Rancang Bangun Sistem IoT untuk Monitoring Kualitas Air Sungai Secara Real-Time",
        "Optimasi Rute Distribusi Logistik Menggunakan Algoritma Genetika dan Ant Colony Optimization",
        "Pengembangan Platform E-Learning Adaptif dengan Personalized Learning Path Berbasis AI",
        "Analisis Performa Algoritma Clustering K-Means dan DBSCAN pada Data Segmentasi Pelanggan",
        "Implementasi Blockchain untuk Sistem Verifikasi Ijazah Digital pada Perguruan Tinggi",
        "Pengembangan Chatbot Layanan Akademik Menggunakan RASA Framework dan NLP Bahasa Indonesia",
        "Sistem Deteksi Plagiarisme Dokumen Akademik Menggunakan Algoritma Rabin-Karp dan Cosine Similarity",
        "Perancangan Data Warehouse dan Dashboard Business Intelligence untuk Analisis Penjualan Retail",
        "Implementasi Computer Vision untuk Sistem Absensi Otomatis Berbasis Pengenalan Wajah",
    ]

    titles_revision = [
        "Sistem informasi untuk sekolah berbasis website",
        "Aplikasi android untuk toko online sederhana",
        "Prediksi menggunakan machine learning di bidang kesehatan",
        "Analisis data penjualan dengan metode data mining",
        "Website e-commerce dengan PHP dan MySQL",
        "Aplikasi pengelolaan data berbasis mobile android",
        "Sistem monitoring berbasis IoT untuk pertanian",
        "Penerapan algoritma pada sistem rekomendasi produk",
        "Pengembangan game edukasi untuk anak sekolah dasar",
        "Sistem pakar diagnosa penyakit menggunakan forward chaining",
    ]

    titles_rejected = [
        "Membuat website",
        "Aplikasi android",
        "Belajar machine learning",
        "Sistem informasi",
        "Program komputer untuk tugas",
        "Analisis data",
        "Tentang IoT",
        "Menggunakan Python",
    ]

    backgrounds_good = [
        "Perkembangan teknologi informasi yang pesat memberikan dampak signifikan pada berbagai sektor. Berdasarkan data BPS tahun 2024, penetrasi internet di Indonesia mencapai 78.19%. Hal ini membuka peluang besar untuk pengembangan solusi digital yang inovatif. Penelitian sebelumnya oleh Ahmad et al. (2023) menunjukkan bahwa penerapan teknologi AI dapat meningkatkan efisiensi operasional hingga 40%. Namun, masih terdapat gap penelitian dalam konteks implementasi di lingkungan akademik Indonesia.",
        "Seiring dengan meningkatnya volume data yang dihasilkan setiap hari, kebutuhan akan sistem analitik yang cerdas semakin mendesak. Menurut laporan IDC (2024), volume data global diproyeksikan mencapai 175 zettabytes pada 2025. Penelitian terdahulu oleh Pratama dan Widodo (2023) telah mengeksplorasi teknik machine learning untuk analisis data berskala besar, namun belum membahas implementasi pada domain spesifik yang menjadi fokus penelitian ini.",
        "Transformasi digital di sektor pendidikan mengalami percepatan signifikan pasca pandemi COVID-19. UNESCO mencatat bahwa 91.3% populasi siswa di dunia terdampak penutupan sekolah. Kondisi ini mendorong adopsi teknologi pembelajaran daring secara masif. Beberapa penelitian terkait seperti yang dilakukan oleh Suryani (2023) dan Rahman et al. (2024) menunjukkan pentingnya pengembangan platform yang adaptif dan personal.",
    ]

    backgrounds_poor = [
        "Teknologi saat ini sudah berkembang pesat.",
        "Banyak masalah yang bisa diselesaikan dengan komputer.",
        "Internet sudah banyak digunakan oleh masyarakat.",
    ]

    methodologies_good = [
        "Penelitian ini menggunakan metode Research and Development (R&D) dengan model pengembangan ADDIE (Analysis, Design, Development, Implementation, Evaluation). Pengumpulan data dilakukan melalui observasi, wawancara mendalam, dan kuesioner kepada 150 responden. Analisis data kuantitatif menggunakan uji statistik deskriptif dan inferensial, sementara data kualitatif dianalisis dengan teknik Miles-Huberman. Validasi sistem dilakukan melalui pengujian black-box, white-box, dan user acceptance testing (UAT).",
        "Metode yang digunakan adalah CRISP-DM (Cross Industry Standard Process for Data Mining) yang terdiri dari 6 fase: Business Understanding, Data Understanding, Data Preparation, Modeling, Evaluation, dan Deployment. Dataset dikumpulkan dari sumber primer dan diolah menggunakan Python dengan library scikit-learn, pandas, dan TensorFlow. Evaluasi model menggunakan metrik accuracy, precision, recall, F1-score, dan confusion matrix. Cross-validation 10-fold diterapkan untuk memastikan generalisasi model.",
        "Penelitian mengadopsi metodologi Agile Scrum dengan sprint duration 2 minggu. Pengembangan sistem menggunakan arsitektur microservices dengan tech stack: Flutter untuk frontend, Node.js untuk backend API, dan PostgreSQL sebagai database. Testing dilakukan secara bertahap meliputi unit testing, integration testing, dan system testing. Deployment menggunakan CI/CD pipeline dengan Docker containerization.",
    ]

    methodologies_poor = [
        "Menggunakan metode kualitatif.",
        "Penelitian dilakukan dengan membuat program.",
        "Metode yang digunakan adalah waterfall.",
    ]

    problem_formulations_good = [
        "1) Bagaimana merancang arsitektur sistem yang scalable untuk menangani data skala besar? 2) Bagaimana implementasi algoritma machine learning dapat meningkatkan akurasi prediksi? 3) Bagaimana evaluasi performa sistem yang dikembangkan dibandingkan dengan metode konvensional?",
        "1) Bagaimana mengidentifikasi faktor-faktor dominan yang mempengaruhi variabel target? 2) Bagaimana membangun model klasifikasi yang optimal dengan tingkat akurasi di atas 85%? 3) Bagaimana mengimplementasikan model ke dalam aplikasi yang user-friendly?",
    ]

    problem_formulations_poor = [
        "Bagaimana membuat aplikasi?",
        "Bagaimana menggunakan teknologi ini?",
    ]

    data = []
    statuses = ["APPROVED", "REVISION", "REJECTED"]
    weights = [0.4, 0.35, 0.25]

    for _ in range(n):
        status = np.random.choice(statuses, p=weights)

        if status == "APPROVED":
            title = np.random.choice(titles_approved)
            background = np.random.choice(backgrounds_good)
            methodology = np.random.choice(methodologies_good)
            problem = np.random.choice(problem_formulations_good)
        elif status == "REVISION":
            title = np.random.choice(titles_revision)
            # Mix of good and poor
            background = np.random.choice(backgrounds_good + backgrounds_poor)
            methodology = np.random.choice(methodologies_poor + methodologies_good[:1])
            problem = np.random.choice(problem_formulations_good + problem_formulations_poor)
        else:  # REJECTED
            title = np.random.choice(titles_rejected)
            background = np.random.choice(backgrounds_poor)
            methodology = np.random.choice(methodologies_poor)
            problem = np.random.choice(problem_formulations_poor)

        # Combine all text fields
        combined_text = f"{title}. {background} {problem} {methodology}"

        data.append({
            "title": title,
            "background": background,
            "problem_formulation": problem,
            "methodology": methodology,
            "combined_text": combined_text,
            "status": status,
        })

    df = pd.DataFrame(data)
    df.to_csv(os.path.join(OUTPUT_DIR, "topic_quality_data.csv"), index=False)
    print(f"✅ Generated {n} samples → topic_quality_data.csv")
    return df


# =============================================================================
# 4. DATA FOR SVM — Kategorisasi Bidang Topik Skripsi
# =============================================================================
def generate_topic_category_data(n=400):
    """
    Features: combined text of title + description + methodology
    Target: category (AI/ML, IoT, Mobile Dev, Web Dev, Data Science, Cybersecurity, Game Dev)
    """
    categories = {
        "AI/ML": [
            "Implementasi Convolutional Neural Network untuk Klasifikasi Gambar Medis",
            "Prediksi Harga Saham Menggunakan Long Short-Term Memory Neural Network",
            "Sistem Rekomendasi Film Menggunakan Collaborative Filtering dan Content-Based Filtering",
            "Deteksi Objek Real-Time Menggunakan YOLO v5 untuk Sistem Keamanan",
            "Penerapan Reinforcement Learning untuk Optimasi Robot Navigasi Otonom",
            "Chatbot Cerdas untuk Layanan Pelanggan dengan Natural Language Understanding",
            "Klasifikasi Citra Satelit Menggunakan Transfer Learning dengan ResNet-50",
            "Pengenalan Suara Bahasa Indonesia Menggunakan Deep Neural Network",
            "Prediksi Churn Pelanggan Telekomunikasi dengan Ensemble Learning",
            "Sistem Penerjemah Bahasa Isyarat ke Teks Menggunakan Computer Vision dan LSTM",
        ],
        "IoT": [
            "Sistem Smart Home Otomatis Berbasis Arduino dan Protokol MQTT",
            "Monitoring Suhu dan Kelembaban Greenhouse dengan Sensor DHT22 dan ESP32",
            "Sistem Irigasi Cerdas Berbasis IoT untuk Lahan Pertanian",
            "Smart Parking System dengan Deteksi Ketersediaan Slot Menggunakan Ultrasonic Sensor",
            "Prototype Smart City Traffic Light Menggunakan Raspberry Pi dan Computer Vision",
            "Sistem Monitoring Kualitas Udara Real-Time dengan Sensor MQ Series dan Dashboard Web",
            "Wearable Device untuk Monitoring Kesehatan Pasien Jantung Berbasis IoT",
            "Sistem Keamanan Rumah Pintar dengan Face Recognition dan Notifikasi Mobile",
            "Smart Aquaculture Monitoring System Menggunakan LoRa dan Cloud Platform",
            "Penerapan Edge Computing pada Jaringan Sensor IoT untuk Smart Agriculture",
        ],
        "Mobile Dev": [
            "Pengembangan Aplikasi Mobile Health Tracking dengan Flutter dan Firebase",
            "Aplikasi Augmented Reality untuk Katalog Produk Furniture Berbasis Android",
            "Platform Mobile E-Wallet dengan Fitur QR Payment dan NFC",
            "Aplikasi Pembelajaran Bahasa Asing Gamified Berbasis React Native",
            "Pengembangan Aplikasi Ride-Sharing dengan Geolocation dan Real-Time Tracking",
            "Mobile App Manajemen Inventaris Gudang dengan Barcode Scanner Integration",
            "Aplikasi Social Media untuk Komunitas Lokal Berbasis Flutter",
            "Pengembangan Aplikasi Telemedicine dengan Video Call dan Chat Konsultasi",
            "Mobile Point of Sale Application dengan Offline-First Architecture",
            "Aplikasi Fitness Tracker dengan Integrasi Wearable Device dan Progress Analytics",
        ],
        "Web Dev": [
            "Pengembangan Portal Berita Online Responsif dengan Next.js dan Headless CMS",
            "Sistem Manajemen Proyek Kolaboratif Berbasis Web dengan Real-Time Collaboration",
            "Platform Crowdfunding untuk UMKM dengan Payment Gateway Integration",
            "Pengembangan Learning Management System Berbasis Laravel dan Vue.js",
            "Web Application untuk Manajemen Supply Chain dengan Microservices Architecture",
            "Platform Job Portal dengan Fitur Matching Algorithm Berbasis Web",
            "Sistem Reservasi Hotel Online dengan Dynamic Pricing Engine",
            "Pengembangan Content Management System Custom dengan React dan GraphQL",
            "Web-Based ERP System untuk Industri Manufaktur Kecil Menengah",
            "Progressive Web App untuk Delivery Service dengan Offline Capability",
        ],
        "Data Science": [
            "Analisis Sentimen Review Produk E-Commerce Menggunakan BERT dan TextBlob",
            "Eksplorasi dan Visualisasi Data COVID-19 Indonesia dengan Teknik Data Storytelling",
            "Pemodelan Prediktif Customer Lifetime Value Menggunakan Regresi dan Time Series",
            "Analisis Pola Konsumsi Energi Listrik dengan Teknik Clustering dan Association Rule",
            "Data Mining untuk Analisis Market Basket pada Data Transaksi Supermarket",
            "Pengembangan Dashboard Interaktif Business Intelligence dengan Tableau dan Python",
            "Analisis Jaringan Sosial untuk Identifikasi Influencer Menggunakan Graph Analytics",
            "Forecasting Demand Produk FMCG dengan Model ARIMA dan Prophet",
            "Text Mining pada Data Keluhan Pelanggan untuk Identifikasi Tren Masalah Layanan",
            "Analisis Geospasial Sebaran Fasilitas Kesehatan dan Aksesibilitas Masyarakat",
        ],
        "Cybersecurity": [
            "Implementasi Intrusion Detection System Menggunakan Machine Learning pada Jaringan Kampus",
            "Analisis Kerentanan Keamanan Aplikasi Web dengan Metode OWASP Top 10",
            "Sistem Deteksi Malware Android Menggunakan Static dan Dynamic Analysis",
            "Pengembangan Secure Authentication System dengan Multi-Factor Authentication dan Biometrik",
            "Implementasi Zero Trust Architecture pada Infrastruktur Cloud Enterprise",
            "Forensik Digital untuk Investigasi Insiden Keamanan Siber pada Server Linux",
            "Pengembangan Honeypot System untuk Analisis Pola Serangan Siber",
            "Enkripsi End-to-End pada Aplikasi Chat Menggunakan Protokol Signal",
            "Vulnerability Assessment dan Penetration Testing pada Infrastruktur Jaringan Perusahaan",
            "Sistem Deteksi Phishing URL Menggunakan Machine Learning dan Feature Engineering",
        ],
        "Game Dev": [
            "Pengembangan Serious Game Edukasi Matematika untuk Siswa SMP Berbasis Unity",
            "Perancangan Game RPG 2D dengan Procedural Content Generation",
            "Pengembangan Game Simulasi Manajemen Bisnis untuk Pembelajaran Entrepreneurship",
            "Implementasi AI NPC dengan Finite State Machine dan Behavior Tree pada Game 3D",
            "Pengembangan Multiplayer Online Game dengan Photon Networking dan Unity",
            "Game Berbasis Lokasi untuk Promosi Wisata Daerah dengan AR Foundation",
            "Perancangan Puzzle Game untuk Melatih Kemampuan Computational Thinking",
            "Pengembangan Virtual Reality Game untuk Terapi Rehabilitasi Pasien Stroke",
            "Infinite Runner Game dengan Adaptive Difficulty Menggunakan Fuzzy Logic",
            "Game Board Digital Multiplayer dengan Cross-Platform Compatibility",
        ],
    }

    descriptions = {
        "AI/ML": "Penelitian ini berfokus pada pengembangan model kecerdasan buatan dan machine learning untuk memecahkan permasalahan kompleks. Menggunakan framework TensorFlow dan PyTorch untuk training model dengan dataset yang telah dikurasi. Evaluasi model dilakukan menggunakan metrik standar seperti accuracy, precision, recall, dan F1-score.",
        "IoT": "Penelitian ini merancang dan mengimplementasikan sistem Internet of Things yang menghubungkan perangkat fisik melalui jaringan internet. Menggunakan mikrokontroler seperti Arduino dan ESP32 dengan berbagai sensor untuk pengumpulan data real-time. Komunikasi data menggunakan protokol MQTT dan HTTP ke cloud platform.",
        "Mobile Dev": "Penelitian ini mengembangkan aplikasi mobile yang berjalan di platform Android dan/atau iOS. Pengembangan menggunakan framework cross-platform seperti Flutter atau React Native untuk efisiensi development. Aplikasi terintegrasi dengan backend cloud dan menyediakan fitur yang responsif dan user-friendly.",
        "Web Dev": "Penelitian ini mengembangkan aplikasi web modern dengan arsitektur yang scalable dan maintainable. Menggunakan framework frontend seperti React, Vue.js, atau Next.js yang dipadukan dengan backend berbasis Node.js atau Laravel. Deployment menggunakan cloud hosting dengan CI/CD pipeline.",
        "Data Science": "Penelitian ini melakukan analisis data mendalam untuk mengekstrak insight dan pola tersembunyi dari dataset. Menggunakan teknik statistik, machine learning, dan visualisasi data dengan Python (pandas, matplotlib, scikit-learn). Hasil analisis disajikan dalam bentuk dashboard interaktif dan laporan komprehensif.",
        "Cybersecurity": "Penelitian ini berfokus pada aspek keamanan sistem informasi dan jaringan komputer. Menggunakan tools dan metodologi pengujian keamanan standar industri. Implementasi mencakup mekanisme proteksi, deteksi ancaman, dan respons insiden keamanan siber.",
        "Game Dev": "Penelitian ini mengembangkan game digital dengan memanfaatkan engine modern seperti Unity atau Unreal Engine. Pengembangan meliputi game design, programming gameplay mechanics, asset creation, dan testing. Game dirancang dengan memperhatikan aspek user experience dan gameplay balance.",
    }

    data = []
    category_list = list(categories.keys())

    for _ in range(n):
        category = np.random.choice(category_list)
        title = np.random.choice(categories[category])
        description = descriptions[category]
        combined_text = f"{title}. {description}"

        data.append({
            "title": title,
            "description": description,
            "combined_text": combined_text,
            "category": category,
        })

    df = pd.DataFrame(data)
    df.to_csv(os.path.join(OUTPUT_DIR, "topic_category_data.csv"), index=False)
    print(f"✅ Generated {n} samples → topic_category_data.csv")
    return df


# =============================================================================
# MAIN — Generate all datasets
# =============================================================================
if __name__ == "__main__":
    print("=" * 60)
    print("🔄 Generating Synthetic Training Data for SkripsiFlow ML")
    print("=" * 60)
    generate_completion_time_data()
    generate_ontime_prediction_data()
    generate_topic_quality_data()
    generate_topic_category_data()
    print("=" * 60)
    print("✅ All datasets generated successfully!")
    print(f"📁 Output directory: {os.path.abspath(OUTPUT_DIR)}")
