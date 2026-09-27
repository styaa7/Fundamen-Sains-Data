-- ==============================================================================
-- SKRIPSIFLOW ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================

-- 1. Helper Functions
CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS user_role AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid();
$$ LANGUAGE sql STABLE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean AS $$
  SELECT COALESCE((SELECT role = 'admin' FROM public.profiles WHERE id = auth.uid()), false);
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- 2. Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lecturers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.topic_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.theses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.thesis_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.consultations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.consultation_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- 3. PROFILES POLICIES
DROP POLICY IF EXISTS "Profiles viewable by authenticated users" ON public.profiles;
CREATE POLICY "Profiles viewable by authenticated users"
ON public.profiles FOR SELECT TO authenticated
USING (true);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile"
ON public.profiles FOR UPDATE TO authenticated
USING (auth.uid() = id);

DROP POLICY IF EXISTS "Admin full manage profiles" ON public.profiles;
CREATE POLICY "Admin full manage profiles"
ON public.profiles FOR ALL TO authenticated
USING (public.is_admin());

-- 4. STUDENTS & LECTURERS POLICIES
DROP POLICY IF EXISTS "View students policy" ON public.students;
CREATE POLICY "View students policy"
ON public.students FOR SELECT TO authenticated
USING (true);

DROP POLICY IF EXISTS "Students update own record" ON public.students;
CREATE POLICY "Students update own record"
ON public.students FOR UPDATE TO authenticated
USING (id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS "View lecturers policy" ON public.lecturers;
CREATE POLICY "View lecturers policy"
ON public.lecturers FOR SELECT TO authenticated
USING (true);

DROP POLICY IF EXISTS "Lecturers update own record" ON public.lecturers;
CREATE POLICY "Lecturers update own record"
ON public.lecturers FOR UPDATE TO authenticated
USING (id = auth.uid() OR public.is_admin());

-- 5. TOPIC SUBMISSIONS POLICIES
DROP POLICY IF EXISTS "View topic submissions policy" ON public.topic_submissions;
CREATE POLICY "View topic submissions policy"
ON public.topic_submissions FOR SELECT TO authenticated
USING (
  student_id = auth.uid() 
  OR lecturer_id = auth.uid() 
  OR public.is_admin()
);

DROP POLICY IF EXISTS "Students insert topic submissions" ON public.topic_submissions;
CREATE POLICY "Students insert topic submissions"
ON public.topic_submissions FOR INSERT TO authenticated
WITH CHECK (student_id = auth.uid());

DROP POLICY IF EXISTS "Students update editable topic submissions" ON public.topic_submissions;
CREATE POLICY "Students update editable topic submissions"
ON public.topic_submissions FOR UPDATE TO authenticated
USING (
  student_id = auth.uid() 
  AND status IN ('DRAFT', 'REVISION')
);

DROP POLICY IF EXISTS "Lecturers review assigned topic" ON public.topic_submissions;
CREATE POLICY "Lecturers review assigned topic"
ON public.topic_submissions FOR UPDATE TO authenticated
USING (lecturer_id = auth.uid() OR public.is_admin());

-- 6. THESES & PROGRESS POLICIES
DROP POLICY IF EXISTS "View theses policy" ON public.theses;
CREATE POLICY "View theses policy"
ON public.theses FOR SELECT TO authenticated
USING (
  student_id = auth.uid() 
  OR lecturer_id = auth.uid() 
  OR public.is_admin()
);

DROP POLICY IF EXISTS "View thesis progress policy" ON public.thesis_progress;
CREATE POLICY "View thesis progress policy"
ON public.thesis_progress FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.theses t
    WHERE t.id = thesis_progress.thesis_id
    AND (t.student_id = auth.uid() OR t.lecturer_id = auth.uid() OR public.is_admin())
  )
);

DROP POLICY IF EXISTS "Students update thesis progress" ON public.thesis_progress;
CREATE POLICY "Students update thesis progress"
ON public.thesis_progress FOR UPDATE TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.theses t
    WHERE t.id = thesis_progress.thesis_id AND t.student_id = auth.uid()
  )
);

-- 7. CONSULTATIONS & NOTES POLICIES
DROP POLICY IF EXISTS "View consultations policy" ON public.consultations;
CREATE POLICY "View consultations policy"
ON public.consultations FOR SELECT TO authenticated
USING (
  student_id = auth.uid() 
  OR lecturer_id = auth.uid() 
  OR public.is_admin()
);

DROP POLICY IF EXISTS "Students insert consultation" ON public.consultations;
CREATE POLICY "Students insert consultation"
ON public.consultations FOR INSERT TO authenticated
WITH CHECK (student_id = auth.uid());

DROP POLICY IF EXISTS "Update consultation status policy" ON public.consultations;
CREATE POLICY "Update consultation status policy"
ON public.consultations FOR UPDATE TO authenticated
USING (
  student_id = auth.uid() 
  OR lecturer_id = auth.uid()
  OR public.is_admin()
);

DROP POLICY IF EXISTS "View consultation notes policy" ON public.consultation_notes;
CREATE POLICY "View consultation notes policy"
ON public.consultation_notes FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.consultations c
    WHERE c.id = consultation_notes.consultation_id
    AND (c.student_id = auth.uid() OR c.lecturer_id = auth.uid() OR public.is_admin())
  )
);

DROP POLICY IF EXISTS "Lecturers insert consultation notes" ON public.consultation_notes;
CREATE POLICY "Lecturers insert consultation notes"
ON public.consultation_notes FOR INSERT TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.consultations c
    WHERE c.id = consultation_notes.consultation_id 
    AND (c.lecturer_id = auth.uid() OR public.is_admin())
  )
);

-- 8. NOTIFICATIONS POLICIES
DROP POLICY IF EXISTS "Users own notifications policy" ON public.notifications;
CREATE POLICY "Users own notifications policy"
ON public.notifications FOR ALL TO authenticated
USING (user_id = auth.uid());
