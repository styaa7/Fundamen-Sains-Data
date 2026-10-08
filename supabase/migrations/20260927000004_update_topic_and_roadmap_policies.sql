-- ==============================================================================
-- UPDATE TOPIC VISIBILITY & THESIS ROADMAP POLICIES
-- ==============================================================================

-- 1. Topic Submissions: Drafts are STRICTLY student-only (student_id = auth.uid()).
-- Neither lecturers nor admins can view drafts.
-- Admins only see SUBMITTED, APPROVED, REVISION.
DROP POLICY IF EXISTS "View topic submissions policy" ON public.topic_submissions;
CREATE POLICY "View topic submissions policy"
ON public.topic_submissions FOR SELECT TO authenticated
USING (
  student_id = auth.uid() 
  OR (
    status != 'DRAFT' 
    AND (
      lecturer_id = auth.uid() 
      OR (public.is_admin() AND status IN ('SUBMITTED', 'APPROVED', 'REVISION'))
    )
  )
);

-- 2. Students update editable topic submissions (allow transition from DRAFT to SUBMITTED)
DROP POLICY IF EXISTS "Students update editable topic submissions" ON public.topic_submissions;
CREATE POLICY "Students update editable topic submissions"
ON public.topic_submissions FOR UPDATE TO authenticated
USING (
  student_id = auth.uid() 
  AND status IN ('DRAFT', 'REVISION')
)
WITH CHECK (
  student_id = auth.uid() 
  AND status IN ('DRAFT', 'SUBMITTED', 'REVISION')
);

-- 3. Students delete own draft topics
DROP POLICY IF EXISTS "Students delete own draft topic" ON public.topic_submissions;
CREATE POLICY "Students delete own draft topic"
ON public.topic_submissions FOR DELETE TO authenticated
USING (
  student_id = auth.uid() 
  AND status = 'DRAFT'
);

-- 4. Lecturers review assigned topics (Setujui, Revisi, Tolak)
DROP POLICY IF EXISTS "Lecturers review assigned topic" ON public.topic_submissions;
CREATE POLICY "Lecturers review assigned topic"
ON public.topic_submissions FOR UPDATE TO authenticated
USING (lecturer_id = auth.uid() OR public.is_admin())
WITH CHECK (lecturer_id = auth.uid() OR public.is_admin());

-- 5. Theses INSERT & UPDATE policies: Lecturers and Admins can create and update theses
DROP POLICY IF EXISTS "Lecturers and admins insert theses" ON public.theses;
CREATE POLICY "Lecturers and admins insert theses"
ON public.theses FOR INSERT TO authenticated
WITH CHECK (lecturer_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS "Lecturers and admins update theses" ON public.theses;
CREATE POLICY "Lecturers and admins update theses"
ON public.theses FOR UPDATE TO authenticated
USING (lecturer_id = auth.uid() OR public.is_admin());

-- 6. Thesis Progress INSERT & UPDATE policies: Lecturers and Admins can create and approve stages
DROP POLICY IF EXISTS "Lecturers and admins insert thesis progress" ON public.thesis_progress;
CREATE POLICY "Lecturers and admins insert thesis progress"
ON public.thesis_progress FOR INSERT TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.theses t
    WHERE t.id = thesis_progress.thesis_id
    AND (t.lecturer_id = auth.uid() OR public.is_admin())
  )
);

DROP POLICY IF EXISTS "Lecturers and admins update thesis progress" ON public.thesis_progress;
CREATE POLICY "Lecturers and admins update thesis progress"
ON public.thesis_progress FOR UPDATE TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.theses t
    WHERE t.id = thesis_progress.thesis_id
    AND (t.lecturer_id = auth.uid() OR public.is_admin())
  )
);

-- 7. Notifications Policies: Allow authenticated users (lecturers) to insert notifications for students
DROP POLICY IF EXISTS "Users own notifications policy" ON public.notifications;
DROP POLICY IF EXISTS "Users view own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users update own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Authenticated insert notifications" ON public.notifications;

CREATE POLICY "Users view own notifications"
ON public.notifications FOR SELECT TO authenticated
USING (user_id = auth.uid());

CREATE POLICY "Users update own notifications"
ON public.notifications FOR UPDATE TO authenticated
USING (user_id = auth.uid());

CREATE POLICY "Authenticated insert notifications"
ON public.notifications FOR INSERT TO authenticated
WITH CHECK (true);

-- 8. Initial Seed for Test Student Thesis & 8 Stages if not present
DO $$
DECLARE
    uid_student UUID := '11111111-1111-1111-1111-111111111111';
    uid_lecturer UUID := '22222222-2222-2222-2222-222222222222';
    topic_id UUID := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    thesis_id UUID := 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
BEGIN
    -- Ensure an approved topic exists for seed student
    IF NOT EXISTS (SELECT 1 FROM public.topic_submissions WHERE id = topic_id) THEN
        INSERT INTO public.topic_submissions (
            id, student_id, lecturer_id, title, background, description,
            problem_formulation, research_objective, methodology, status, reviewed_at
        ) VALUES (
            topic_id,
            uid_student,
            uid_lecturer,
            'Klasifikasi Citra Rontgen Paru-Paru Menggunakan Algoritma Convolutional Neural Network',
            'Penyakit paru-paru membutuhkan diagnosis cepat dan akurat melalui citra rontgen toraks.',
            'Pengembangan sistem deteksi kelainan paru berbasis deep learning.',
            'Bagaimana merancang arsitektur CNN optimal untuk dataset rontgen toraks berdimensi tinggi?',
            'Mengukur akurasi dan sensitivitas model CNN pada klasifikasi kelainan paru.',
            'Metodologi eksperimental dengan augmentasi data dan transfer learning.',
            'APPROVED',
            NOW()
        ) ON CONFLICT (id) DO NOTHING;
    END IF;

    -- Ensure thesis exists for seed student
    IF NOT EXISTS (SELECT 1 FROM public.theses WHERE id = thesis_id OR student_id = uid_student) THEN
        INSERT INTO public.theses (
            id, student_id, lecturer_id, topic_submission_id, title,
            current_stage_order, overall_progress_percentage
        ) VALUES (
            thesis_id,
            uid_student,
            uid_lecturer,
            topic_id,
            'Klasifikasi Citra Rontgen Paru-Paru Menggunakan Algoritma Convolutional Neural Network',
            2,
            25.0
        ) ON CONFLICT (id) DO NOTHING;

        -- Seed 8 Stages
        INSERT INTO public.thesis_progress (thesis_id, stage_order, stage_name, status, progress_percentage, student_notes)
        VALUES
            (thesis_id, 1, 'Pengajuan Topik', 'COMPLETED', 100.0, 'Topik disetujui oleh pembimbing.'),
            (thesis_id, 2, 'Proposal Skripsi', 'IN_PROGRESS', 50.0, 'Penyusunan naskah bab 1-3 sedang ditinjau dosen.'),
            (thesis_id, 3, 'Seminar Proposal', 'NOT_STARTED', 0.0, NULL),
            (thesis_id, 4, 'Pengumpulan Data', 'NOT_STARTED', 0.0, NULL),
            (thesis_id, 5, 'Analisis Data', 'NOT_STARTED', 0.0, NULL),
            (thesis_id, 6, 'Penyusunan Naskah', 'NOT_STARTED', 0.0, NULL),
            (thesis_id, 7, 'Seminar Hasil', 'NOT_STARTED', 0.0, NULL),
            (thesis_id, 8, 'Sidang Akhir', 'NOT_STARTED', 0.0, NULL)
        ON CONFLICT (thesis_id, stage_order) DO NOTHING;
    END IF;
END $$;
