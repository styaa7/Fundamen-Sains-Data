-- ==============================================================================
-- RESET OPERATIONAL DATA (PRESERVE USER ACCOUNTS & PROFILES)
-- ==============================================================================
-- Script ini menghapus semua data transaksi operasional:
-- - Permohonan ganti topik (topic_change_requests)
-- - Tahapan progres skripsi (thesis_progress)
-- - Data skripsi aktif (theses)
-- - Pengajuan judul & topik (topic_submissions)
-- - Catatan bimbingan (consultation_notes)
-- - Jadwal bimbingan (consultations)
-- - Notifikasi (notifications)
--
-- TETAP DIPERTAHANKAN:
-- - Akun login (auth.users)
-- - Data Profil (public.profiles)
-- - Data Mahasiswa (public.students)
-- - Data Dosen (public.lecturers)
-- ==============================================================================

BEGIN;

-- 1. Hapus data pergantian topik jika tabel ada
DO $$ BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'topic_change_requests') THEN
        DELETE FROM public.topic_change_requests;
    END IF;
END $$;

-- 2. Hapus tahapan progres skripsi
DELETE FROM public.thesis_progress;

-- 3. Hapus data skripsi
DELETE FROM public.theses;

-- 4. Hapus pengajuan topik skripsi
DELETE FROM public.topic_submissions;

-- 5. Hapus catatan dan jadwal konsultasi
DELETE FROM public.consultation_notes;
DELETE FROM public.consultations;

-- 6. Hapus notifikasi
DELETE FROM public.notifications;

COMMIT;

-- Verifikasi sisa data akun
SELECT 'Profiles remaining' as entity, COUNT(*) as count FROM public.profiles
UNION ALL
SELECT 'Students remaining', COUNT(*) FROM public.students
UNION ALL
SELECT 'Lecturers remaining', COUNT(*) FROM public.lecturers
UNION ALL
SELECT 'Topics remaining', COUNT(*) FROM public.topic_submissions
UNION ALL
SELECT 'Theses remaining', COUNT(*) FROM public.theses;
