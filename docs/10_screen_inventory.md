# SkripsiFlow — Screen Inventory & UI Specifications

Dokumen ini memuat daftar lengkap layar aplikasi Flutter, komponen utama, serta penanganan *Empty State* dan *Error State*.

---

## 1. Daftar Layar (Screen Inventory)

### A. Layar Bersama (Shared Screens)
| Layar | Path File | Elemen Kunci |
| :--- | :--- | :--- |
| **Splash Screen** | `lib/features/auth/presentation/screens/splash_screen.dart` | Logo SkripsiFlow, animated progress bar, session & role auto-routing. |
| **Login Screen** | `lib/features/auth/presentation/screens/login_screen.dart` | Form Email & Password, Role indicator badge, tombol Masuk, link bantuan. |
| **Profile Screen** | `lib/features/profile/presentation/screens/profile_screen.dart` | Avatar user, Info NIM/NIDN, Nama, Prodi/Fakultas, Tombol Logout dengan dialog konfirmasi. |
| **Notification Center**| `lib/features/notifications/presentation/screens/notification_center_screen.dart` | List kartu notifikasi, status belum dibaca (badge titik biru), filter, tap-to-navigate. |

### B. Layar Mahasiswa (Student Screens)
| Layar | Path File | Elemen Kunci |
| :--- | :--- | :--- |
| **Dashboard Mahasiswa** | `lib/features/dashboard/presentation/screens/student_dashboard_screen.dart` | 1. Kartu Gauge Persentase Progress Skripsi<br>2. Status Pengajuan Topik Terkini (Badge)<br>3. Banner Jadwal Konsultasi Terdekat (Tanggal & Jam)<br>4. Tahapan Skripsi Saat Ini (misal: "Pengumpulan Data")<br>5. Quick Shortcuts (Ajukan Topik, Booking Konsultasi, Progress). |
| **Form Pengajuan Topik**| `lib/features/topic/presentation/screens/topic_form_screen.dart` | Form berurutan: Judul, Latar Belakang, Deskripsi, Rumusan Masalah, Tujuan, Metodologi, Dropdown Dosen, Upload PDF, Tombol "Simpan Draf" & "Submit". |
| **Detail Topik Mahasiswa**| `lib/features/topic/presentation/screens/topic_detail_screen.dart` | Status Badge besar (SUBMITTED/REVISION/APPROVED), Feedback & Catatan Dosen, Form revisi cepat jika diminta perbaikan. |
| **Booking Konsultasi** | `lib/features/consultation/presentation/screens/consultation_booking_screen.dart` | Dropdown Dosen, Kalender Pemilih Tanggal, Time Picker Slot (15-min step), Textarea Agenda Konsultasi, Error warning saat jam bentrok. |
| **Daftar & Riwayat Konsultasi**| `lib/features/consultation/presentation/screens/consultation_list_screen.dart` | Tab: "Mendatang" (Upcoming) & "Riwayat" (History), Status Chip, Card Konsultasi dengan catatan dosen pasca-pertemuan. |
| **Monitoring Progress Skripsi**| `lib/features/progress/presentation/screens/progress_timeline_screen.dart` | Timeline vertikal interaktif 8 tahapan, indikator ikon status (Check/Loading/Lock), Modal upload berkas draf per tahapan. |

### C. Layar Dosen Pembimbing (Lecturer Screens)
| Layar | Path File | Elemen Kunci |
| :--- | :--- | :--- |
| **Dashboard Dosen** | `lib/features/dashboard/presentation/screens/lecturer_dashboard_screen.dart` | 1. Ringkasan Counter: Mahasiswa Dibimbing, Pengajuan Menunggu Review, Konsultasi Hari Ini<br>2. List Jadwal Konsultasi Terdekat Hari Ini<br>3. Daftar Mahasiswa Bimbingan Aktif beserta % progres. |
| **Review Topik Mahasiswa**| `lib/features/topic/presentation/screens/lecturer_topic_review_screen.dart` | Tampilan lengkap draf pengajuan, viewer/link PDF, Action Bar: "Setujui", "Minta Revisi", "Tolak", Dialog input feedback. |
| **Kelola Jadwal Konsultasi**| `lib/features/consultation/presentation/screens/lecturer_consultation_screen.dart` | List permintaan booking masuk $\to$ Tombol "Terima (Confirm)" / "Tolak (Reject)", Tombol "Selesaikan & Beri Catatan". |
| **Detail Mahasiswa Bimbingan**| `lib/features/dashboard/presentation/screens/student_detail_view_for_lecturer.dart` | Profil mahasiswa, Topik yang disetujui, Riwayat konsultasi, Catatan bimbingan, Timeline progress 8 tahap mahasiswa. |

### D. Layar Admin (Admin Screens)
| Layar | Path File | Elemen Kunci |
| :--- | :--- | :--- |
| **Dashboard Admin** | `lib/features/admin/presentation/screens/admin_dashboard_screen.dart` | Statistik global (Total Mahasiswa, Total Dosen, Skripsi Berjalan, Total Konsultasi), Menu navigasi data master. |
| **Manajemen Pengguna** | `lib/features/admin/presentation/screens/admin_users_screen.dart` | Tabel/List Mahasiswa & Dosen, Filter Role, Search NIM/NIDN, Tambah/Edit/Hapus Akun. |
| **Monitoring Sistem Skripsi**| `lib/features/admin/presentation/screens/admin_theses_overview_screen.dart` | Filter berdasarkan fakultas/prodi, status pengajuan, rekapitulasi waktu penyelesaian skripsi. |

---

## 2. Spesifikasi Empty State & Error State

| Kondisi | Pesan & UI Empty State |
| :--- | :--- |
| **Mahasiswa belum memiliki topik** | Ikon dokumen kosong: *"Belum ada pengajuan topik skripsi. Buat draf pengajuan topik pertama Anda untuk memulai bimbingan."* + Tombol `[Ajukan Topik Sekarang]`. |
| **Belum ada jadwal konsultasi** | Ikon kalender: *"Belum ada jadwal konsultasi yang diajukan."* + Tombol `[Jadwalkan Konsultasi]`. |
| **Belum ada notifikasi** | Ikon lonceng tenang: *"Belum ada notifikasi baru saat ini."* |
| **Koneksi Terputus / Error Server** | Banner error kemerahan: *"Gagal memuat data dari server. Silakan periksa koneksi internet Anda."* + Tombol `[Coba Lagi (Retry)]`. |
