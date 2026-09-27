-- ==============================================================================
-- SKRIPSIFLOW DATABASE INITIALIZATION MIGRATION
-- ==============================================================================

-- 1. Enable required PostgreSQL extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "btree_gist";

-- 2. Custom Enum Types
DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('mahasiswa', 'dosen', 'admin');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE topic_status AS ENUM (
        'DRAFT',
        'SUBMITTED',
        'UNDER_REVIEW',
        'REVISION',
        'APPROVED',
        'REJECTED'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE consultation_status AS ENUM (
        'REQUESTED',
        'CONFIRMED',
        'REJECTED',
        'COMPLETED',
        'CANCELLED'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE stage_status AS ENUM (
        'NOT_STARTED',
        'IN_PROGRESS',
        'COMPLETED'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 3. Table: PROFILES
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    role user_role NOT NULL DEFAULT 'mahasiswa',
    full_name VARCHAR(150) NOT NULL,
    identifier_number VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(150) NOT NULL UNIQUE,
    phone_number VARCHAR(20),
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. Table: STUDENTS
CREATE TABLE IF NOT EXISTS public.students (
    id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    faculty VARCHAR(100) NOT NULL,
    study_program VARCHAR(100) NOT NULL,
    academic_year VARCHAR(10) NOT NULL,
    assigned_lecturer_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. Table: LECTURERS
CREATE TABLE IF NOT EXISTS public.lecturers (
    id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    department VARCHAR(100) NOT NULL,
    expertise_area TEXT[],
    max_quota INT NOT NULL DEFAULT 10,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 6. Table: TOPIC_SUBMISSIONS
CREATE TABLE IF NOT EXISTS public.topic_submissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    lecturer_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    title VARCHAR(255) NOT NULL,
    background TEXT NOT NULL,
    description TEXT NOT NULL,
    problem_formulation TEXT NOT NULL,
    research_objective TEXT NOT NULL,
    methodology TEXT NOT NULL,
    supporting_document_url TEXT,
    status topic_status NOT NULL DEFAULT 'DRAFT',
    revision_count INT NOT NULL DEFAULT 0,
    lecturer_feedback TEXT,
    reviewed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT min_title_length CHECK (char_length(title) >= 15)
);

-- 7. Table: THESES
CREATE TABLE IF NOT EXISTS public.theses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
    lecturer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    topic_submission_id UUID NOT NULL UNIQUE REFERENCES public.topic_submissions(id) ON DELETE RESTRICT,
    title VARCHAR(255) NOT NULL,
    current_stage_order INT NOT NULL DEFAULT 1,
    overall_progress_percentage NUMERIC(5,2) NOT NULL DEFAULT 12.50,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT valid_progress_range CHECK (overall_progress_percentage BETWEEN 0 AND 100)
);

-- 8. Table: THESIS_PROGRESS
CREATE TABLE IF NOT EXISTS public.thesis_progress (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    thesis_id UUID NOT NULL REFERENCES public.theses(id) ON DELETE CASCADE,
    stage_order INT NOT NULL,
    stage_name VARCHAR(100) NOT NULL,
    status stage_status NOT NULL DEFAULT 'NOT_STARTED',
    progress_percentage NUMERIC(5,2) NOT NULL DEFAULT 0.00,
    start_date DATE,
    target_date DATE,
    completed_date DATE,
    student_notes TEXT,
    document_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT unique_thesis_stage UNIQUE(thesis_id, stage_order)
);

-- 9. Table: CONSULTATIONS
CREATE TABLE IF NOT EXISTS public.consultations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    lecturer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    scheduled_start TIMESTAMPTZ NOT NULL,
    scheduled_end TIMESTAMPTZ NOT NULL,
    agenda TEXT NOT NULL,
    status consultation_status NOT NULL DEFAULT 'REQUESTED',
    rejection_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT valid_consultation_time CHECK (scheduled_end > scheduled_start)
);

-- 10. Table: CONSULTATION_NOTES
CREATE TABLE IF NOT EXISTS public.consultation_notes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    consultation_id UUID NOT NULL UNIQUE REFERENCES public.consultations(id) ON DELETE CASCADE,
    lecturer_notes TEXT NOT NULL,
    feedback TEXT,
    action_items TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 11. Table: NOTIFICATIONS
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) NOT NULL,
    reference_id UUID,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 12. Indexes for Query Performance
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_students_assigned_lecturer ON public.students(assigned_lecturer_id);
CREATE INDEX IF NOT EXISTS idx_topic_submissions_student ON public.topic_submissions(student_id);
CREATE INDEX IF NOT EXISTS idx_topic_submissions_lecturer ON public.topic_submissions(lecturer_id);
CREATE INDEX IF NOT EXISTS idx_topic_submissions_status ON public.topic_submissions(status);
CREATE INDEX IF NOT EXISTS idx_consultations_lecturer_schedule ON public.consultations(lecturer_id, scheduled_start, scheduled_end);
CREATE INDEX IF NOT EXISTS idx_consultations_student ON public.consultations(student_id);
CREATE INDEX IF NOT EXISTS idx_consultations_status ON public.consultations(status);
CREATE INDEX IF NOT EXISTS idx_theses_student ON public.theses(student_id);
CREATE INDEX IF NOT EXISTS idx_theses_lecturer ON public.theses(lecturer_id);
CREATE INDEX IF NOT EXISTS idx_thesis_progress_thesis ON public.thesis_progress(thesis_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON public.notifications(user_id, is_read);
