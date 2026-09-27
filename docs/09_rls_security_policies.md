# SkripsiFlow — Row Level Security (RLS) Policies

Dokumen ini berisi implementasi lengkap kebijakan keamanan **Row Level Security (RLS)** pada PostgreSQL Supabase untuk memastikan isolasi data multi-role.

---

## 1. Helper Functions

```sql
-- Mendapatkan role user aktif dari sesi auth
CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS user_role AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid();
$$ LANGUAGE sql STABLE;

-- Mengecek apakah user aktif adalah admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean AS $$
  SELECT (role = 'admin') FROM public.profiles WHERE id = auth.uid();
$$ LANGUAGE sql STABLE;
```

---

## 2. RLS Per Tabel

### A. Tabel `profiles`
```sql
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Semua authenticated user bisa melihat profile (untuk mencari dosen/nama mahasiswa)
CREATE POLICY "Profiles viewable by authenticated users"
ON public.profiles FOR SELECT TO authenticated
USING (true);

-- User hanya bisa update profil miliknya sendiri
CREATE POLICY "Users can update own profile"
ON public.profiles FOR UPDATE TO authenticated
USING (auth.uid() = id);

-- Admin bisa update profil siapa saja
CREATE POLICY "Admin full manage profiles"
ON public.profiles FOR ALL TO authenticated
USING (public.is_admin());
```

### B. Tabel `topic_submissions`
```sql
ALTER TABLE public.topic_submissions ENABLE ROW LEVEL SECURITY;

-- Mahasiswa bisa melihat pengajuannya sendiri, Dosen melihat mahasiswa bimbingan, Admin melihat semua
CREATE POLICY "View topic submissions policy"
ON public.topic_submissions FOR SELECT TO authenticated
USING (
  student_id = auth.uid() 
  OR lecturer_id = auth.uid() 
  OR public.is_admin()
);

-- Mahasiswa dapat membuat draf / submit pengajuan
CREATE POLICY "Students insert topic submissions"
ON public.topic_submissions FOR INSERT TO authenticated
WITH CHECK (student_id = auth.uid());

-- Mahasiswa dapat mengedit pengajuan HANYA jika berstatus DRAFT atau REVISION
CREATE POLICY "Students update editable topic submissions"
ON public.topic_submissions FOR UPDATE TO authenticated
USING (
  student_id = auth.uid() 
  AND status IN ('DRAFT', 'REVISION')
);

-- Dosen pembimbing dapat mengupdate status review
CREATE POLICY "Lecturers review assigned topic"
ON public.topic_submissions FOR UPDATE TO authenticated
USING (lecturer_id = auth.uid());
```

### C. Tabel `theses` & `thesis_progress`
```sql
ALTER TABLE public.theses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.thesis_progress ENABLE ROW LEVEL SECURITY;

-- View Theses
CREATE POLICY "View theses policy"
ON public.theses FOR SELECT TO authenticated
USING (
  student_id = auth.uid() 
  OR lecturer_id = auth.uid() 
  OR public.is_admin()
);

-- View Thesis Progress
CREATE POLICY "View thesis progress policy"
ON public.thesis_progress FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.theses t
    WHERE t.id = thesis_progress.thesis_id
    AND (t.student_id = auth.uid() OR t.lecturer_id = auth.uid() OR public.is_admin())
  )
);

-- Mahasiswa dapat memperbarui catatan dan dokumen tahapan skripsinya
CREATE POLICY "Students update thesis progress"
ON public.thesis_progress FOR UPDATE TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.theses t
    WHERE t.id = thesis_progress.thesis_id AND t.student_id = auth.uid()
  )
);
```

### D. Tabel `consultations` & `consultation_notes`
```sql
ALTER TABLE public.consultations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.consultation_notes ENABLE ROW LEVEL SECURITY;

-- View Consultations
CREATE POLICY "View consultations policy"
ON public.consultations FOR SELECT TO authenticated
USING (
  student_id = auth.uid() 
  OR lecturer_id = auth.uid() 
  OR public.is_admin()
);

-- Mahasiswa request konsultasi
CREATE POLICY "Students insert consultation"
ON public.consultations FOR INSERT TO authenticated
WITH CHECK (student_id = auth.uid());

-- Mahasiswa dan dosen dapat memperbarui status konsultasi terkait
CREATE POLICY "Update consultation status policy"
ON public.consultations FOR UPDATE TO authenticated
USING (
  student_id = auth.uid() 
  OR lecturer_id = auth.uid()
);

-- View Consultation Notes
CREATE POLICY "View consultation notes policy"
ON public.consultation_notes FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.consultations c
    WHERE c.id = consultation_notes.consultation_id
    AND (c.student_id = auth.uid() OR c.lecturer_id = auth.uid() OR public.is_admin())
  )
);

-- Dosen membuat catatan bimbingan
CREATE POLICY "Lecturers insert consultation notes"
ON public.consultation_notes FOR INSERT TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.consultations c
    WHERE c.id = consultation_notes.consultation_id AND c.lecturer_id = auth.uid()
  )
);
```

### E. Tabel `notifications`
```sql
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- User hanya dapat melihat dan mengupdate notifikasi miliknya sendiri
CREATE POLICY "Users own notifications policy"
ON public.notifications FOR ALL TO authenticated
USING (user_id = auth.uid());
```
