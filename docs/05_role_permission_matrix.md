# SkripsiFlow — Role & Permission Matrix

Dokumen ini mendefinisikan batas kewenangan (*Authorization Matrix*) untuk masing-masing role pengguna (**Mahasiswa**, **Dosen**, **Admin**) di seluruh entitas data dan aksi sistem.

---

## 1. Matriks Akses Tabel & Operasi (CRUD)

| Entitas / Tabel | Operasi | Mahasiswa | Dosen Pembimbing | Admin |
| :--- | :--- | :--- | :--- | :--- |
| **`profiles`** | `SELECT` | Milik sendiri & Dosen pembimbing | Milik sendiri & Mahasiswa bimbingan | Semua Pengguna |
| | `INSERT` | Saat registrasi/Auth | Saat registrasi/Auth | Bisa Create Akun |
| | `UPDATE` | Milik sendiri (Nama, Phone, Avatar) | Milik sendiri (Nama, Phone, Avatar) | Semua Pengguna |
| | `DELETE` | ❌ Tidak diizinkan | ❌ Tidak diizinkan | ✔️ Diizinkan |
| **`topic_submissions`** | `SELECT` | Milik sendiri | Milik mahasiswa yang dibimbing | Semua Pengajuan |
| | `INSERT` | ✔️ Ajukan Topik / Draf | ❌ Tidak diizinkan | ❌ Tidak diizinkan |
| | `UPDATE` | Jika status `DRAFT` atau `REVISION` | Status `UNDER_REVIEW`, `APPROVED`, `REVISION`, `REJECTED` | Status override jika diperlukan |
| | `DELETE` | Jika status masih `DRAFT` | ❌ Tidak diizinkan | ✔️ Diizinkan |
| **`theses`** | `SELECT` | Skripsi miliknya | Skripsi mahasiswa bimbingannya | Semua Skripsi |
| | `INSERT` | ❌ (Otomatis via Edge Function saat topik disetujui) | ❌ (Otomatis via Edge Function) | Manual admin jika diperlukan |
| | `UPDATE` | ❌ (Hanya field read-only untuk mahasiswa) | ✔️ Update status kelulusan/tahap | ✔️ Diizinkan |
| | `DELETE` | ❌ Tidak diizinkan | ❌ Tidak diizinkan | ✔️ Diizinkan |
| **`thesis_progress`** | `SELECT` | Progress miliknya | Progress mahasiswa bimbingan | Semua Progress |
| | `INSERT` | ❌ (Otomatis 8 tahapan ter-seed) | ❌ | ❌ |
| | `UPDATE` | Isi catatan & unggah dokumen tahapan aktif | Berikan paraf/feedback tahapan | ✔️ Diizinkan |
| | `DELETE` | ❌ | ❌ | ❌ |
| **`consultations`** | `SELECT` | Konsultasi miliknya | Konsultasi mahasiswa bimbingannya | Semua Jadwal |
| | `INSERT` | ✔️ Booking konsultasi | ❌ | ✔️ Penjadwalan khusus |
| | `UPDATE` | Cancel permintaan (jika status `REQUESTED`) | `CONFIRMED`, `REJECTED`, `COMPLETED` | Reschedule / Cancel |
| | `DELETE` | ❌ (Soft delete / status CANCELLED) | ❌ | ✔️ Diizinkan |
| **`consultation_notes`** | `SELECT` | Lihat catatan konsultasi miliknya | Lihat & kelola catatan konsultasinya | Semua Catatan |
| | `INSERT` | ❌ | ✔️ Buat catatan setelah konsultasi | ✔️ Diizinkan |
| | `UPDATE` | ❌ | ✔️ Edit catatan bimbingannya | ✔️ Diizinkan |
| | `DELETE` | ❌ | ❌ | ✔️ Diizinkan |
| **`notifications`** | `SELECT` | Notifikasi miliknya | Notifikasi miliknya | Notifikasi miliknya |
| | `UPDATE` | Tandai sudah dibaca (`is_read = true`) | Tandai sudah dibaca (`is_read = true`) | Tandai sudah dibaca |

---

## 2. Kebijakan Keamanan Tambahan

1. **Role Enforcement**: Penentuan role disimpan dalam tabel `profiles.role` dan tidak boleh diubah oleh pengguna non-admin.
2. **Double Shield**: Validasi hak akses dilakukan di layer antarmuka (Route Guard Flutter) dan **wajib di-enforce di layer database (Supabase PostgreSQL RLS)**.
3. **Storage Access**: File dokumen hanya dapat diunduh oleh Mahasiswa pemilik, Dosen yang bersangkutan, dan Admin.
