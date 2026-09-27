# SkripsiFlow — Validation Rules Specification

Dokumen ini merinci aturan validasi (*validation rules*) yang diterapkan pada sisi **Frontend (Flutter)** dan **Backend (PostgreSQL & Edge Functions)** untuk menjaga integritas data.

---

## 1. Aturan Validasi Input (Form Validation)

| Form / Aksi | Field | Validasi Client-Side (Flutter) | Validasi Database / Server |
| :--- | :--- | :--- | :--- |
| **Login** | Email | Format email standar (`regex: ^[a-zA-Z0-9+_.-]+@[a-zA-Z0-9.-]+$`), tidak boleh kosong | Cek integritas pada `auth.users` |
| | Password | Minimal 6 karakter, tidak boleh kosong | Hashing bcrypt di Supabase Auth |
| **Pengajuan Topik** | Judul Skripsi | Wajib diisi, minimal 15 karakter, maksimal 255 karakter | `CHECK (char_length(title) >= 15)` |
| | Latar Belakang | Wajib diisi, minimal 50 karakter | `NOT NULL`, validasi non-empty |
| | Deskripsi / Topik | Wajib diisi, minimal 30 karakter | `NOT NULL` |
| | Rumusan Masalah | Wajib diisi, minimal 20 karakter | `NOT NULL` |
| | Tujuan Penelitian | Wajib diisi, minimal 20 karakter | `NOT NULL` |
| | Metodologi | Wajib diisi, minimal 30 karakter | `NOT NULL` |
| | Dosen Pembimbing | Wajib memilih 1 dosen dari dropdown aktif | `FOREIGN KEY REFERENCES profiles(id)` |
| | Berkas Pendukung | Opsional, format wajib `.pdf`, ukuran maks 10 MB | MIME Type `application/pdf`, max 10MB bucket rule |
| **Booking Konsultasi** | Tanggal & Jam Mulai | Wajib diisi, waktu tidak boleh di masa lalu (`>= NOW()`) | `scheduled_start >= NOW()` di Edge Function |
| | Jam Selesai | Wajib diisi, jam selesai > jam mulai, durasi 15-120 menit | `CHECK (scheduled_end > scheduled_start)` |
| | Agenda Konsultasi | Wajib diisi, minimal 10 karakter, maksimal 500 karakter | `NOT NULL` |
| | Slot Waktu | Pengecekan real-time di UI sebelum submit | Pengecekan Overlap di `book-consultation` Edge Function |
| **Catatan Konsultasi** | Catatan Pembimbing | Wajib diisi oleh Dosen sebelum menyelesaikan bimbingan, min 10 karakter | `NOT NULL` pada `consultation_notes.lecturer_notes` |
| | Feedback & Action Items | Opsional, maksimal 1000 karakter | `TEXT` |
| **Progress Skripsi** | Dokumen Tahapan | Opsional/Wajib per tahap, format `.pdf`, maks 15 MB | Supabase Storage MIME validation |
| | Catatan Mahasiswa | Opsional, maksimal 500 karakter | `TEXT` |

---

## 2. Pesan Error Standar (User-Friendly Error Messages)

- **Judul Terlalu Pendek**: *"Judul skripsi minimal 15 karakter agar mendeskripsikan topik dengan jelas."*
- **Slot Bentrok**: *"Jadwal bimbingan bertabrakan dengan agenda dosen yang sudah terkonfirmasi. Silakan pilih slot jam lain."*
- **Waktu di Masa Lalu**: *"Tanggal dan jam konsultasi tidak boleh berada di waktu yang sudah lewat."*
- **File Bukan PDF / Terlalu Besar**: *"Dokumen harus berformat PDF dengan ukuran maksimal 10 MB."*
- **Sesi Berakhir**: *"Sesi Anda telah berakhir. Silakan masuk kembali."*
