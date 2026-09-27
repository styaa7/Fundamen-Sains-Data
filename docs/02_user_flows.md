# SkripsiFlow — User Flows & Sequence Diagrams

Dokumen ini memuat diagram alur interaksi pengguna (Mahasiswa, Dosen, Admin) pada ketiga pilar fitur inti.

---

## 1. Fitur 1: Pengajuan & Review Topik Skripsi

Alur dari pembuatan draf oleh mahasiswa hingga review (persetujuan, revisi, penolakan) oleh dosen pembimbing:

```mermaid
sequenceDiagram
    autonumber
    actor M as Mahasiswa
    participant F as Flutter App
    participant DB as PostgreSQL
    participant E as Edge Function (process-topic-review)
    actor D as Dosen

    M->>F: Buka Form Pengajuan Topik
    M->>F: Isi Judul, Latar Belakang, Deskripsi, Rumusan Masalah, Tujuan, Metodologi, & Dosen Tuju
    alt Simpan sebagai Draft
        M->>F: Klik "Simpan Draf"
        F->>DB: INSERT/UPDATE topic_submissions (status = 'DRAFT')
        DB-->>F: Draft tersimpan
    else Submit Pengajuan
        M->>F: Klik "Submit Pengajuan"
        F->>DB: INSERT/UPDATE topic_submissions (status = 'SUBMITTED')
        DB->>D: Realtime/Notifikasi pengajuan topik baru
    end

    D->>F: Dosen membuka daftar pengajuan mahasiswa
    D->>F: Pilih topik mahasiswa & pelajari detail
    F->>DB: UPDATE topic_submissions (status = 'UNDER_REVIEW')
    
    alt Dosen Minta Revisi
        D->>F: Input catatan revisi & klik "Minta Revisi"
        F->>E: POST /process-topic-review (action: 'REVISION', feedback)
        E->>DB: UPDATE topic_submissions (status='REVISION', revision_count+1)
        E->>DB: INSERT notification untuk Mahasiswa
        DB->>M: Notifikasi "Pengajuan topik perlu revisi"
        M->>F: Mahasiswa perbaiki data & klik "Submit Ulang"
        F->>DB: UPDATE topic_submissions (status = 'SUBMITTED')
    else Dosen Menolak Topik
        D->>F: Input alasan penolakan & klik "Tolak"
        F->>E: POST /process-topic-review (action: 'REJECTED', feedback)
        E->>DB: UPDATE topic_submissions (status = 'REJECTED')
        E->>DB: INSERT notification untuk Mahasiswa
        DB->>M: Notifikasi "Pengajuan topik ditolak"
    else Dosen Menyetujui Topik
        D->>F: Klik "Setujui Topik"
        F->>E: POST /process-topic-review (action: 'APPROVED', feedback)
        E->>DB: UPDATE topic_submissions (status = 'APPROVED')
        E->>DB: INSERT theses (student_id, lecturer_id, topic_id, progress=12.5%)
        E->>DB: INSERT 8 rows thesis_progress (Tahap 1=COMPLETED, Tahap 2=IN_PROGRESS)
        E->>DB: INSERT notification untuk Mahasiswa
        DB->>M: Notifikasi "Topik Skripsi Disetujui! Tahap Proposal Dimulai"
    end
```

---

## 2. Fitur 2: Pengajuan Jadwal Konsultasi (Anti-Bentrok)

Alur reservasi waktu konsultasi dengan validasi atomic bentrok jadwal di sisi server:

```mermaid
sequenceDiagram
    autonumber
    actor M as Mahasiswa
    participant F as Flutter App
    participant E as Edge Function (book-consultation)
    participant DB as PostgreSQL
    actor D as Dosen

    M->>F: Masuk menu "Konsultasi" -> Klik "Ajukan Konsultasi"
    M->>F: Pilih Dosen, Tanggal, Jam Mulai, Jam Selesai, & Agenda Konsultasi
    F->>E: POST /book-consultation {lecturer_id, start_time, end_time, agenda}
    
    Note over E,DB: Query pengecekan overlap jadwal dosen
    alt Jadwal Bentrok dengan Jadwal Dosen Lain
        E-->>F: HTTP 409 Conflict ("Dosen telah memiliki jadwal pada rentang jam tersebut")
        F-->>M: Tampilkan alert error bentrok & sarankan slot lain
    else Jadwal Tersedia
        E->>DB: INSERT consultations (status: 'REQUESTED')
        E->>DB: INSERT notifications untuk Dosen ("Permintaan Konsultasi Baru")
        E-->>F: HTTP 201 Created
        F-->>M: Tampilkan dialog sukses "Permintaan konsultasi berhasil dikirim"
    end

    D->>F: Dosen melihat permintaan konsultasi
    alt Dosen Menerima
        D->>F: Klik "Terima"
        F->>DB: UPDATE consultations (status = 'CONFIRMED')
        DB->>M: Notifikasi "Konsultasi Dikonfirmasi"
    else Dosen Menolak
        D->>F: Input alasan penolakan & klik "Tolak"
        F->>DB: UPDATE consultations (status = 'REJECTED', rejection_reason)
        DB->>M: Notifikasi "Permintaan Konsultasi Ditolak"
    end
```

---

## 3. Fitur 2 (Lanjutan) & Fitur 3: Pasca-Konsultasi & Update Progress Skripsi

```mermaid
sequenceDiagram
    autonumber
    actor D as Dosen
    participant F as Flutter App
    participant DB as PostgreSQL
    actor M as Mahasiswa

    Note over D,M: Konsultasi Berlangsung Selesai
    D->>F: Buka detail konsultasi berstatus CONFIRMED
    D->>F: Input Catatan Konsultasi, Feedback, Action Items/Tugas
    D->>F: Klik "Selesaikan Konsultasi"
    F->>DB: UPDATE consultations (status = 'COMPLETED')
    F->>DB: INSERT consultation_notes (notes, feedback, action_items)
    DB->>M: Notifikasi "Catatan konsultasi baru ditambahkan oleh Dosen"

    M->>F: Buka menu "Progress Skripsi"
    M->>F: Lihat 8 tahapan skripsi & progress bar
    M->>F: Buka tahapan aktif (misal: Tahap 2 - Proposal)
    M->>F: Unggah draf dokumen PDF / perbarui catatan progres
    F->>DB: UPDATE thesis_progress (notes, document_url, updated_at)
    DB->>D: Notifikasi "Mahasiswa memperbarui progres skripsi"
```
