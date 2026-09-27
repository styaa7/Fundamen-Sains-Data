-- ==============================================================================
-- SKRIPSIFLOW SEED DUMMY USERS FOR TESTING (Mahasiswa, Dosen, Admin)
-- ==============================================================================
-- Password untuk semua akun default: password123

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

DO $$
DECLARE
    uid_student UUID := '11111111-1111-1111-1111-111111111111';
    uid_lecturer UUID := '22222222-2222-2222-2222-222222222222';
    uid_admin UUID := '33333333-3333-3333-3333-333333333333';
    hashed_pwd TEXT := crypt('password123', gen_salt('bf'));
BEGIN
    -- -------------------------------------------------------------------------
    -- 1. DOSEN TEST ACCOUNT
    -- -------------------------------------------------------------------------
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'dosen@kampus.ac.id') THEN
        INSERT INTO auth.users (
            id, instance_id, email, encrypted_password, email_confirmed_at,
            raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
            role, aud, confirmation_token, recovery_token, email_change_token_new, email_change
        ) VALUES (
            uid_lecturer,
            '00000000-0000-0000-0000-000000000000',
            'dosen@kampus.ac.id',
            hashed_pwd,
            NOW(),
            '{"provider":"email","providers":["email"]}',
            '{"full_name":"Dr. Ir. Hendra Wijaya, M.T."}',
            NOW(),
            NOW(),
            'authenticated',
            'authenticated',
            '', '', '', ''
        );

        INSERT INTO auth.identities (
            id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at
        ) VALUES (
            gen_random_uuid(),
            uid_lecturer,
            jsonb_build_object('sub', uid_lecturer::text, 'email', 'dosen@kampus.ac.id'),
            'email',
            uid_lecturer::text,
            NOW(),
            NOW(),
            NOW()
        );

        INSERT INTO public.profiles (id, role, full_name, identifier_number, email, phone_number)
        VALUES (uid_lecturer, 'dosen', 'Dr. Ir. Hendra Wijaya, M.T.', '198501152010121001', 'dosen@kampus.ac.id', '081298765432')
        ON CONFLICT (id) DO NOTHING;

        INSERT INTO public.lecturers (id, department, expertise_area, max_quota)
        VALUES (uid_lecturer, 'Teknik Informatika', ARRAY['Machine Learning', 'Computer Vision', 'Data Science'], 10)
        ON CONFLICT (id) DO NOTHING;
    END IF;

    -- -------------------------------------------------------------------------
    -- 2. ADMIN TEST ACCOUNT
    -- -------------------------------------------------------------------------
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'admin@kampus.ac.id') THEN
        INSERT INTO auth.users (
            id, instance_id, email, encrypted_password, email_confirmed_at,
            raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
            role, aud, confirmation_token, recovery_token, email_change_token_new, email_change
        ) VALUES (
            uid_admin,
            '00000000-0000-0000-0000-000000000000',
            'admin@kampus.ac.id',
            hashed_pwd,
            NOW(),
            '{"provider":"email","providers":["email"]}',
            '{"full_name":"Admin Bimbingan Skripsi"}',
            NOW(),
            NOW(),
            'authenticated',
            'authenticated',
            '', '', '', ''
        );

        INSERT INTO auth.identities (
            id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at
        ) VALUES (
            gen_random_uuid(),
            uid_admin,
            jsonb_build_object('sub', uid_admin::text, 'email', 'admin@kampus.ac.id'),
            'email',
            uid_admin::text,
            NOW(),
            NOW(),
            NOW()
        );

        INSERT INTO public.profiles (id, role, full_name, identifier_number, email)
        VALUES (uid_admin, 'admin', 'Administrator Skripsi', 'ADM001', 'admin@kampus.ac.id')
        ON CONFLICT (id) DO NOTHING;
    END IF;

    -- -------------------------------------------------------------------------
    -- 3. MAHASISWA TEST ACCOUNT
    -- -------------------------------------------------------------------------
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'mahasiswa@kampus.ac.id') THEN
        INSERT INTO auth.users (
            id, instance_id, email, encrypted_password, email_confirmed_at,
            raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
            role, aud, confirmation_token, recovery_token, email_change_token_new, email_change
        ) VALUES (
            uid_student,
            '00000000-0000-0000-0000-000000000000',
            'mahasiswa@kampus.ac.id',
            hashed_pwd,
            NOW(),
            '{"provider":"email","providers":["email"]}',
            '{"full_name":"Ahmad Fauzi"}',
            NOW(),
            NOW(),
            'authenticated',
            'authenticated',
            '', '', '', ''
        );

        INSERT INTO auth.identities (
            id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at
        ) VALUES (
            gen_random_uuid(),
            uid_student,
            jsonb_build_object('sub', uid_student::text, 'email', 'mahasiswa@kampus.ac.id'),
            'email',
            uid_student::text,
            NOW(),
            NOW(),
            NOW()
        );

        INSERT INTO public.profiles (id, role, full_name, identifier_number, email, phone_number)
        VALUES (uid_student, 'mahasiswa', 'Ahmad Fauzi', '2021001', 'mahasiswa@kampus.ac.id', '081234567890')
        ON CONFLICT (id) DO NOTHING;

        INSERT INTO public.students (id, faculty, study_program, academic_year, assigned_lecturer_id)
        VALUES (uid_student, 'Ilmu Komputer', 'Teknik Informatika', '2021/2022', uid_lecturer)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;
