# ANALISIS PROBLEM BISNIS DAN NILAI STRATEGIS PLATFORM SKRPSIFLOW
## Solusi Transformasi Digital & Sistem Cerdas Tata Kelola Bimbingan Tugas Akhir di Perguruan Tinggi

---

**Penyusun:** Tim Pengembang & Analis Domain SkripsiFlow  
**Format Dokumen:** Laporan Eksekutif & Analisis Problem Bisnis  
**Aplikasi:** SkripsiFlow (SaaS Bimbingan Skripsi Berbasis Cloud-Native & Machine Learning)  
**Institusi:** Program Studi / Departemen Sains Data & Teknologi Informasi  

---

## 1. RINGKASAN EKSEKUTIF (EXECUTIVE SUMMARY)

Penyusunan Tugas Akhir atau Skripsi merupakan fase kulminasi kurikulum jenjang sarjana (S1) yang memiliki dampak langsung terhadap angka kelulusan tepat waktu (*on-time graduation rate*), kepuasan mahasiswa, dan instrumen akreditasi program studi (BAN-PT / LAM-INFOKOM). Meskipun bernilai sangat strategis, tata kelola proses bimbingan di sebagian besar perguruan tinggi hingga saat ini masih menghadapi inefisiensi operasional akut akibat ketergantungan pada prosedur manual, komunikasi terfragmentasi di aplikasi pesan instan, dan minimnya transparansi pemantauan progres.

**SkripsiFlow** hadir sebagai platform perangkat lunak layanan (*Software as a Service / SaaS*) berbasis arsitektur *cloud-native* dan analitik prediktif (*Machine Learning*) yang secara spesifik dirancang untuk menyelesaikan titik-titik sumbatan (*bottlenecks*) dalam ekosistem bimbingan tugas akhir.

Dokumen ini menguraikan secara mendalam analisis ruang masalah (*problem space*), solusi fungsional dan kecerdasan buatan (*solution space*), serta dampak bisnis nyata (*business value proposition*) yang dihasilkan bagi mahasiswa, dosen pembimbing, dan pimpinan program studi.

---

## 2. LATAR BELAKANG & IDENTIFIKASI PROBLEM BISNIS

Berdasarkan analisis alur kerja konvensional di perguruan tinggi, terdapat 6 (enam) akar masalah bisnis utama yang diselesaikan oleh SkripsiFlow:

```
[PROBLEMATIKA BISNIS BIMBINGAN SKRIPSI KONVENSIONAL]
  │
  ├── 1. Inefisiensi & Siklus Pengajuan Topik yang Lambat
  ├── 2. Friksi Penjadwalan & Bentrok Waktu Konsultasi (Double-Booking)
  ├── 3. Hilangnya Jejak Audit & Lembar Kendali Kertas (Loss of Audit Trail)
  ├── 4. Fenomena "Kotak Hitam" (Black Box) bagi Pimpinan Program Studi
  ├── 5. Mismatch Topik dengan Kepakaran Dosen Pembimbing
  └── 6. Ketiadaan Sistem Peringatan Dini Keterlambatan Kelulusan
```

### 2.1. Inefisiensi dan Siklus Pengajuan Topik yang Lambat (*Repetitive Review Cycle*)
* **Permasalahan Lapangan:** Mahasiswa sering kali mengajukan ide penelitian atau judul secara manual, baik melalui formulir cetak maupun pesan chat pribadi. Banyak pengajuan memiliki judul terlalu dangkal, latar belakang tanpa dukungan data empiris, rumusan masalah tidak terukur, atau teks sembarangan (*keyboard smashing/spam*).
* **Dampak Bisnis:** Dosen pembimbing dan koordinator skripsi harus membaca proposal berkualitas rendah tersebut secara manual. Karena padatnya kesibukan dosen, umpan balik baru diberikan setelah 1 hingga 2 minggu hanya untuk memberi keputusan "Ditolak". Siklus berulang ini menghabiskan waktu mahasiswa hingga berminggu-minggu sebelum riset dimulai secara resmi.

### 2.2. Friksi Penjadwalan Konsultasi & Risiko Bentrok (*Scheduling Conflicts & Double-Booking*)
* **Permasalahan Lapangan:** Dosen memiliki beban Tri Dharma (mengajar, meneliti, mengabdi) serta agenda rapat yang padat. Mahasiswa tidak mengetahui kapan dosen memiliki slot waktu luang. Komunikasi penentuan jadwal bimbingan dilakukan melalui tawar-menawar panjang di WhatsApp.
* **Dampak Bisnis:** Kerap terjadi bentrok jadwal antarmahasiswa (*double-booking*), pembatalan sepihak di menit-menit terakhir tanpa slot pengganti, antrean mahasiswa yang menumpuk tidak teratur di lorong kampus, serta terganggunya ranah privasi dosen di luar jam kerja.

### 2.3. Hilangnya Jejak Riwayat Bimbingan (*Loss of Audit Trail & Paper-Based Issues*)
* **Permasalahan Lapangan:** Bukti pelaksanaan bimbingan dicatat pada buku kendali (*logbook*) fisik berbasis kertas dengan tanda tangan basah.
* **Dampak Bisnis:** Buku kendali rawan robek, rusak, atau hilang. Lebih jauh lagi, catatan perbaikan tulisan tangan sering kali sangat ringkas sehingga mahasiswa lupa poin-poin metodologis yang harus direvisi. Ketika mahasiswa bimbingan kembali berkonsultasi, dosen kerap lupa apa yang dibahas pada pertemuan minggu sebelumnya, memicu friksi dan inkonsistensi arahan revisi.

### 2.4. Fenomena "Kotak Hitam" bagi Pimpinan Program Studi (*The Black Box Problem*)
* **Permasalahan Lapangan:** Ketua Program Studi (Kaprodi) dan koordinator tugas akhir umumnya hanya memiliki data pada dua titik ekstrem: saat pendaftaran judul dan saat pendaftaran sidang akhir skripsi.
* **Dampak Bisnis:** Proses di antara kedua titik tersebut (penyusunan proposal, pengumpulan data, analisis hasil, penulisan naskah) menjadi "kotak hitam". Pihak pengelola prodi tidak memiliki visibilitas mengenai mahasiswa mana yang aktif dan mahasiswa mana yang mengalami kemacetan (*stuck*) di bab tertentu. Intervensi akademik terlambat dilakukan, berujung pada tingginya angka mahasiswa molor atau terancam *Drop Out* (DO).

### 2.5. Ketidaksesuaian (*Mismatch*) Topik dengan Kepakaran Dosen Pembimbing
* **Permasalahan Lapangan:** Alokasi dosen pembimbing ke mahasiswa sering kali dilakukan berdasarkan pemerataan kuota numerik semata atau intuisi manual koordinator tugas akhir.
* **Dampak Bisnis:** Terjadi ketidaksesuaian antara fokus penelitian mahasiswa dengan bidang keahlian (*expertise*) dosen pembimbing (contoh: mahasiswa meneliti topik Deep Learning Computer Vision namun dibimbing oleh dosen pakar Jaringan Komputer). Akibatnya, arahan metodologis menjadi kurang tajam, proses bimbingan terhambat, dan kualitas naskah ilmiah menurun.

### 2.6. Ketiadaan Sistem Peringatan Dini Keterlambatan (*No Early Warning System*)
* **Permasalahan Lapangan:** Tidak ada indikator kuantitatif berbasis data yang memproyeksikan sisa waktu penyelesaian skripsi seorang mahasiswa.
* **Dampak Bisnis:** Mahasiswa merasa masih memiliki banyak waktu hingga mendekati batas akhir semester (*student syndrome*). Tanpa adanya notifikasi risiko keterlambatan (*risk scoring*), pihak kampus kehilangan kesempatan untuk memberikan pendampingan khusus sebelum mahasiswa melewati masa studi reguler.

---

## 3. SOLUSI YANG DITAWARKAN SKRPSIFLOW (*THE SOLUTION SPACE*)

SkripsiFlow memformulasikan pemecahan masalah di atas ke dalam ekosistem digital terintegrasi yang mencakup **3 Pilar Bisnis Utama** dan diperkuat oleh **4 Model Machine Learning**:

### 3.1. Pilar 1: Siklus Pengajuan Topik Terstruktur & Berbasis AI
1. **Digital Submission Portal:** Mahasiswa menginput 4 komponen baku proposal: Judul, Latar Belakang, Rumusan Masalah, dan Metodologi.
2. **Pra-Evaluasi Cerdas (Multinomial Naive Bayes + Heuristics):**
   - Mendeteksi teks sampah (*gibberish / spam detector*) secara instan.
   - Memberikan rekomendasi kelayakan awal (*APPROVED*, *REVISION*, *REJECTED*) beserta saran perbaikan dalam hitungan detik sebelum proposal masuk ke antrean dosen.
3. **Kategorisasi Bidang & Matchmaking Dosen (Support Vector Machine / SVM):**
   - Secara otomatis mengklasifikasikan proposal ke dalam 7 bidang minat riset (AI/ML, Data Science, Web Dev, Mobile Dev, IoT, Cybersecurity, Game Dev) dengan akurasi tinggi.
   - Merekomendasikan daftar dosen pakar yang relevan dengan topik riset tersebut secara objektif.

### 3.2. Pilar 2: Penjadwalan Bimbingan Bebas Bentrok (*Anti-Conflict Scheduling*)
1. **Kalender Ketersediaan Mandiri:** Dosen menetapkan slot waktu bimbingan resmi (hari, jam, kapasitas, lokasi/link daring).
2. **Reservasi Transaksional Atomik:** Mahasiswa memilih slot yang tersedia secara mandiri. Sistem menerapkan penguncian transaksi di level database (*PostgreSQL row locking / transactions*) untuk menjamin **nol risiko bentrok (*zero double-booking*)**.
3. **Digital Logbook Permanen:** Setiap sesi konsultasi selesai, hasil catatan perbaikan diinput ke sistem, tersimpan dengan stempel waktu resmi (*timestamped*), dan menjadi rujukan wajib pada sesi berikutnya (*audit-ready*).

### 3.3. Pilar 3: Monitoring 8 Tahapan Terbobot & Prediksi Risiko Dini
1. **Standarisasi 8 Tahapan Roadmap Skripsi:**
   - Tahap 1: Pengajuan Topik (*Topic Submission*)
   - Tahap 2: Proposal Skripsi (*Proposal Preparation*)
   - Tahap 3: Seminar Proposal (*Sempro Presentation*)
   - Tahap 4: Revisi Proposal (*Proposal Revision*)
   - Tahap 5: Pengumpulan & Analisis Data (*Data Collection & Analysis*)
   - Tahap 6: Penulisan Naskah Skripsi (*Draft Writing*)
   - Tahap 7: Sidang Skripsi (*Final Defense*)
   - Tahap 8: Revisi Akhir & Yudisium (*Graduation*)
2. **Formula Progres Terbobot Kumulatif:** Kemajuan mahasiswa dihitung secara matematis dan transparan (0% - 100%) berdasarkan validasi dosen pembimbing pada setiap tonggak capaian (*milestone*).
3. **Analitik Prediktif & Early-Warning:**
   - **Linear Regression Model:** Mengestimasi sisa hari kerja nyata (*days to complete*) berdasarkan laju progres dan siklus revisi.
   - **Logistic Regression Model:** Mengklasifikasikan probabilitas kelulusan tepat waktu (*On-Time vs Delayed*) serta menerbitkan skor risiko (*Low, Medium, High Risk*) untuk deteksi dini intervensi prodi.

---

## 4. MATRIKS KOMPARASI: PENDEKATAN KONVENSIONAL VS SKRPSIFLOW

| Aspek Operasional | Pendekatan Konvensional | Pendekatan SkripsiFlow |
| :--- | :--- | :--- |
| **Media Pengajuan Judul** | Formulir kertas / Chat WhatsApp informal | Formulir digital terstandar dengan validasi berkas otomatis |
| **Penyaringan Kualitas Judul** | Dosen membaca proposal dangkal satu per satu | AI Naive Bayes menyaring proposal secara instan dalam hitungan detik |
| **Alokasi Dosen Pembimbing** | Penunjukan manual, rawan salah bidang keahlian | AI SVM memetakan bidang keahlian dan merekomendasikan dosen pakar |
| **Pengaturan Waktu Bimbingan** | Tawar-menawar chat, rawan bentrok jadwal | Kalender slot mandiri dengan *anti-conflict concurrency lock* |
| **Pencatatan Riwayat Revisi** | Buku bimbingan kertas (mudah hilang / rusak) | *Cloud Digital Logbook* permanen, rapi, dan mudah ditelusuri kembali |
| **Pemantauan Progres Mahasiswa** | *Black Box* (hanya diketahui saat daftar sidang) | Dashboard analitik real-time berbasis 8 tahapan terstruktur |
| **Deteksi Keterlambatan** | Reaktif (baru disadari saat batas semester habis) | Proaktif (Model Regresi memprediksi sisa hari & skor risiko) |
| **Keamanan & Privasi Data** | Tersebar di ponsel pribadi mahasiswa & dosen | Terpusat di Cloud dengan *Row Level Security (RLS)* berbasis peran |

---

## 5. ANALISIS NILAI TAMBAH DAN DAMPAK BISNIS (*VALUE PROPOSITION*)

Penerapan SkripsiFlow memberikan dampak strategis (*business impact*) yang terukur bagi ketiga aktor pemangku kepentingan:

### 5.1. Dampak bagi Mahasiswa (*Student Value*)
* **Mereduksi Kecemasan (*Thesis Anxiety*):** Mahasiswa memiliki panduan peta jalan (*roadmap*) yang jelas dari awal pengajuan hingga yudisium.
* **Efisiensi Waktu Signifikan:** Tidak ada lagi waktu terbuang untuk mengantre di depan ruang dosen atau menunggu balasan pesan jadwal bimbingan.
* **Kepastian Tindak Lanjut Revisi:** Seluruh arahan pembimbing tersimpan permanen di *logbook*, meminimalisir salah paham pada sesi bimbingan lanjutan.

### 5.2. Dampak bagi Dosen Pembimbing (*Supervisor Value*)
* **Manajemen Waktu Efisien:** Dosen memegang kendali penuh atas jam kerja bimbingan melalui pembukaan slot waktu, membatasi pesan konsultasi di luar jam kerja.
* **Kesiapan Sesi Konsultasi:** Dosen dapat membuka riwayat logbook pertemuan sebelumnya hanya dengan satu klik sebelum memulai sesi konsultasi.
* **Pengurangan Beban Kognitif:** Proposal awal yang masuk ke antrean sudah melalui penyaringan AI dan sesuai dengan bidang riset dosen.

### 5.3. Dampak bagi Program Studi dan Pimpinan Institusi (*Institutional Value*)
* **Meningkatkan Angka Kelulusan Tepat Waktu (*On-Time Graduation Rate*):** Mendukung pencapaian Indikator Kinerja Utama (IKU) Perguruan Tinggi jenjang sarjana.
* **Kesiapan Akreditasi (Audit-Ready Data):** Seluruh data rekam jejak bimbingan, durasi penyelesaian, dan frekuensi konsultasi tersimpan rapi untuk kebutuhan instrumen akreditasi LAM-INFOKOM atau BAN-PT tanpa perlu rekap manual berhari-hari.
* **Intervensi Akademik Presisi:** Dashboard admin memungkinkan Kaprodi menyaring secara instan mahasiswa yang berada pada kategori *High Risk Delayed* untuk segera diberikan bimbingan konseling atau fasilitasi khusus.

---

## 6. KESIMPULAN

Aplikasi **SkripsiFlow** bukan sekadar sistem informasi pencatatan administratif, melainkan sebuah **solusi rekayasa perangkat lunak dan sains data terpadu** yang mentransformasi ekosistem bimbingan skripsi menjadi terstruktur, transparan, dan akuntabel. 

Dengan memecahkan 6 titik sumbatan bisnis konvensional melalui 3 pilar operasional dan modul analitik prediktif, SkripsiFlow memberikan kepastian kelulusan bagi mahasiswa, efisiensi waktu kerja bagi dosen, serta peningkatan mutu tata kelola akademik bagi institusi perguruan tinggi.
