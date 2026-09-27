# SkripsiFlow — Acceptance Criteria & Definition of Done (DoD)

Dokumen ini memuat daftar kriteria keberhasilan (*acceptance criteria*) untuk pengujian dan validasi rilis MVP SkripsiFlow.

---

## 1. Modul Autentikasi & Otorisasi Role

- [ ] **AC-AUTH-01**: Mahasiswa, Dosen, dan Admin dapat login menggunakan email dan password yang valid.
- [ ] **AC-AUTH-02**: Pengguna yang belum login otomatis diarahkan ke `/login` saat mengakses rute internal.
- [ ] **AC-AUTH-03**: Setelah login, pengguna diarahkan ke Dashboard sesuai role masing-masing (`/student`, `/lecturer`, `/admin`).
- [ ] **AC-AUTH-04**: Pengguna dengan role Mahasiswa ditolak saat mencoba mengakses rute Dosen atau Admin (begitu pula sebaliknya).
- [ ] **AC-AUTH-05**: Database RLS menggagalkan kueri data lintas user yang tidak berhak meskipun dipanggil langsung via client.

---

## 2. Fitur 1: Pengajuan & Review Topik Skripsi

- [ ] **AC-TOPIC-01**: Mahasiswa dapat menyimpan form pengajuan sebagai `DRAFT` dan membukanya kembali untuk diedit kapan saja.
- [ ] **AC-TOPIC-02**: Mahasiswa dapat mengunggah file PDF pendukung dan men-submit pengajuan (status berubah menjadi `SUBMITTED`).
- [ ] **AC-TOPIC-03**: Dosen pembimbing dapat melihat daftar pengajuan topik mahasiswa yang ditujukan kepadanya.
- [ ] **AC-TOPIC-04**: Dosen dapat meminta revisi (`REVISION`) dengan menyertakan catatan. Mahasiswa dapat melihat catatan dan mengirim ulang revisi.
- [ ] **AC-TOPIC-05**: Dosen dapat menolak pengajuan (`REJECTED`) dengan menyertakan alasan.
- [ ] **AC-TOPIC-06**: Dosen dapat menyetujui pengajuan (`APPROVED`). Sistem secara otomatis membuat entitas `theses` dan menginisialisasi 8 tahapan `thesis_progress` (Tahap 1 `COMPLETED`, Tahap 2 `IN_PROGRESS`).

---

## 3. Fitur 2: Jadwal Konsultasi (Anti-Bentrok) & Catatan Bimbingan

- [ ] **AC-CONSULT-01**: Mahasiswa dapat memilih dosen, tanggal, rentang waktu, dan mengisi agenda bimbingan.
- [ ] **AC-CONSULT-02**: Sistem (Edge Function) menolak pemesanan jadwal yang bertabrakan dengan jadwal dosen yang sudah berstatus `CONFIRMED` atau `REQUESTED` dengan pesan error yang jelas.
- [ ] **AC-CONSULT-03**: Permintaan konsultasi yang valid berhasil tersimpan dengan status `REQUESTED` dan memicu notifikasi ke Dosen.
- [ ] **AC-CONSULT-04**: Dosen dapat mengonfirmasi (`CONFIRMED`) atau menolak (`REJECTED`) jadwal konsultasi.
- [ ] **AC-CONSULT-05**: Mahasiswa dapat membatalkan (`CANCELLED`) jadwal yang masih berstatus `REQUESTED`.
- [ ] **AC-CONSULT-06**: Dosen dapat menyelesaikan konsultasi (`COMPLETED`) dan wajib mengisi catatan bimbingan, feedback, serta action items.
- [ ] **AC-CONSULT-07**: Mahasiswa dapat melihat riwayat lengkap seluruh sesi bimbingan beserta catatan dosen.

---

## 4. Fitur 3: Monitoring Progress Skripsi

- [ ] **AC-PROG-01**: Dashboard mahasiswa menampilkan persentase progres kumulatif (e.g. 12.5% setelah topik disetujui, hingga 100% pada sidang akhir).
- [ ] **AC-PROG-02**: Layar Progress menyajikan 8 tahapan skripsi dalam bentuk timeline visual yang clean dan mudah dibaca.
- [ ] **AC-PROG-03**: Mahasiswa dapat mengunggah draf berkas (PDF) dan catatan pada tahapan yang sedang aktif (`IN_PROGRESS`).
- [ ] **AC-PROG-04**: Dosen pembimbing dapat memantau progres dan mengunduh berkas tahapan mahasiswa bimbingannya.

---

## 5. UI/UX, Responsivitas & Kualitas Teknis

- [ ] **AC-TECH-01**: Tampilan aplikasi responsif pada layar Mobile (Smartphone), Tablet, dan Desktop/Web.
- [ ] **AC-TECH-02**: Setiap halaman memiliki penanganan *Loading State* (Shimmer/Spinner), *Empty State* (dengan pesan ramah), dan *Error State* (dengan tombol retry).
- [ ] **AC-TECH-03**: Tidak ada secret key / service role key yang tersimpan di dalam client Flutter.
- [ ] **AC-TECH-04**: Kode terstruktur secara modular mengikuti *Feature-First Clean Architecture* dan siap dikembangkan lebih lanjut.
