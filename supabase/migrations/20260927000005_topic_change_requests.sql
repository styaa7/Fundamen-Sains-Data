-- ==============================================================================
-- TOPIC CHANGE REQUEST MIGRATION & RLS POLICIES
-- ==============================================================================

-- 1. Add CANCELLED enum value to topic_status if not present
DO $$ BEGIN
    ALTER TYPE topic_status ADD VALUE IF NOT EXISTS 'CANCELLED';
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 2. Table: TOPIC_CHANGE_REQUESTS
CREATE TABLE IF NOT EXISTS public.topic_change_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    lecturer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    thesis_id UUID REFERENCES public.theses(id) ON DELETE SET NULL,
    current_topic_id UUID REFERENCES public.topic_submissions(id) ON DELETE SET NULL,
    reason TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING', -- 'PENDING', 'APPROVED', 'REJECTED'
    lecturer_response TEXT,
    requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    responded_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Enable RLS
ALTER TABLE public.topic_change_requests ENABLE ROW LEVEL SECURITY;

-- 4. Policies for topic_change_requests
DROP POLICY IF EXISTS "View topic change requests" ON public.topic_change_requests;
CREATE POLICY "View topic change requests"
ON public.topic_change_requests FOR SELECT TO authenticated
USING (
    student_id = auth.uid() 
    OR lecturer_id = auth.uid() 
    OR public.is_admin()
);

DROP POLICY IF EXISTS "Students insert topic change requests" ON public.topic_change_requests;
CREATE POLICY "Students insert topic change requests"
ON public.topic_change_requests FOR INSERT TO authenticated
WITH CHECK (student_id = auth.uid());

DROP POLICY IF EXISTS "Lecturers update topic change requests" ON public.topic_change_requests;
CREATE POLICY "Lecturers update topic change requests"
ON public.topic_change_requests FOR UPDATE TO authenticated
USING (lecturer_id = auth.uid() OR public.is_admin())
WITH CHECK (lecturer_id = auth.uid() OR public.is_admin());

-- 5. Delete thesis policy: Lecturers and admins can delete theses upon topic change
DROP POLICY IF EXISTS "Lecturers and admins delete theses" ON public.theses;
CREATE POLICY "Lecturers and admins delete theses"
ON public.theses FOR DELETE TO authenticated
USING (lecturer_id = auth.uid() OR public.is_admin());
