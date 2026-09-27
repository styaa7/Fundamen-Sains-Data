# SkripsiFlow — API & Data Flow Lifecycle

Dokumen ini mendokumentasikan pola komunikasi data antara antarmuka Flutter, Supabase Client SDK, Supabase Edge Functions, dan Database PostgreSQL.

---

## 1. Siklus Alur Data (Data Flow Lifecycle)

```mermaid
flowchart TD
    A[User Trigger Aksi di Layar Flutter] --> B{Validasi Client-Side Form}
    B -- Gagal --> C[Tampilkan Pesan Error di Form]
    B -- Valid --> D{Jenis Operasi}
    
    D -- Operasi CRUD Standar ber-RLS --> E[Supabase Client SDK (PostgREST)]
    D -- Operasi Kompleks / Anti-Bentrok --> F[Invoke Supabase Edge Function]
    D -- Upload Dokumen PDF --> G[Supabase Storage SDK]
    
    E --> H[(PostgreSQL Database)]
    F --> H
    G --> I[(Storage Bucket: 'thesis-docs')]
    
    H -- RLS Menolak / Constraint Gagal --> J[Error Handler: Format pesan ramah pengguna]
    H -- Sukses --> K[Update Riverpod State]
    
    K --> L[UI Rebuild secara Reaktif]
    K --> M[Tampilkan SnackBar / Notifikasi Sukses]
    
    H -.->|Trigger Postgres Change| N[Supabase Realtime Stream]
    N -.->|Broadcast Event| O[Flutter Realtime Listener]
    O -.->|Auto Refresh| K
```

---

## 2. Saluran Komunikasi Data

### A. Direct Query (PostgREST API via Supabase Dart SDK)
Digunakan untuk operasi baca/tulis yang perizinannya sudah dijamin secara ketat oleh Row Level Security (RLS):
- Mengambil profil pengguna (`profiles`, `students`, `lecturers`).
- Mengambil daftar riwayat topik (`topic_submissions`).
- Mengambil daftar progress 8 tahapan (`thesis_progress`).
- Mengambil daftar notifikasi pengguna (`notifications`).

### B. Edge Functions (REST HTTPS via Supabase Functions)
Digunakan untuk transaksi kompleks yang memerlukan validasi multi-tabel atau pemrosesan aman:
- `POST /book-consultation`: Pengecekan overlap waktu atomik.
- `POST /process-topic-review`: Status transition dan pembuatan entitas skripsi & 8 tahapan secara transaksional.

### C. Supabase Realtime Engine
Digunakan untuk pembaruan instan tanpa perlu polling:
- Channel `public:notifications:user_id=eq.{auth.uid()}` $\to$ Memperbarui counter lonceng notifikasi secara langsung ketika dosen memberikan feedback atau konfirmasi bimbingan.
