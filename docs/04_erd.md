# SkripsiFlow — Entity Relationship Diagram (ERD)

Dokumen ini memodelkan struktur hubungan antar entitas di database **SkripsiFlow**.

---

## 1. ERD Diagram (Mermaid)

```mermaid
erDiagram
    PROFILES ||--o| STUDENTS : "is a student profile"
    PROFILES ||--o| LECTURERS : "is a lecturer profile"
    STUDENTS }o--o| LECTURERS : "guided by (assigned_lecturer_id)"

    PROFILES ||--o{ TOPIC_SUBMISSIONS : "submits (student_id)"
    PROFILES ||--o{ TOPIC_SUBMISSIONS : "assigned to review (lecturer_id)"

    STUDENTS ||--o| THESES : "owns approved thesis"
    LECTURERS ||--o{ THESES : "supervises"
    TOPIC_SUBMISSIONS ||--|| THESES : "promoted to"

    THESES ||--|{ THESIS_PROGRESS : "has 8 stages"

    PROFILES ||--o{ CONSULTATIONS : "requests consultation (student_id)"
    PROFILES ||--o{ CONSULTATIONS : "hosts consultation (lecturer_id)"
    CONSULTATIONS ||--o| CONSULTATION_NOTES : "yields notes"

    PROFILES ||--o{ NOTIFICATIONS : "receives alerts"

    PROFILES {
        uuid id PK
        enum role
        string full_name
        string identifier_number
        string email
        string phone_number
        string avatar_url
    }

    STUDENTS {
        uuid id PK,FK
        string faculty
        string study_program
        string academic_year
        uuid assigned_lecturer_id FK
    }

    LECTURERS {
        uuid id PK,FK
        string department
        string_array expertise_area
        int max_quota
    }

    TOPIC_SUBMISSIONS {
        uuid id PK
        uuid student_id FK
        uuid lecturer_id FK
        string title
        text background
        text description
        text problem_formulation
        text research_objective
        text methodology
        string supporting_document_url
        enum status
        int revision_count
        text lecturer_feedback
        timestamptz reviewed_at
    }

    THESES {
        uuid id PK
        uuid student_id FK
        uuid lecturer_id FK
        uuid topic_submission_id FK
        string title
        int current_stage_order
        numeric overall_progress_percentage
    }

    THESIS_PROGRESS {
        uuid id PK
        uuid thesis_id FK
        int stage_order
        string stage_name
        enum status
        numeric progress_percentage
        date start_date
        date target_date
        date completed_date
        text student_notes
        string document_url
    }

    CONSULTATIONS {
        uuid id PK
        uuid student_id FK
        uuid lecturer_id FK
        timestamptz scheduled_start
        timestamptz scheduled_end
        text agenda
        enum status
        text rejection_reason
    }

    CONSULTATION_NOTES {
        uuid id PK
        uuid consultation_id FK
        text lecturer_notes
        text feedback
        text action_items
    }

    NOTIFICATIONS {
        uuid id PK
        uuid user_id FK
        string title
        text message
        string type
        uuid reference_id
        boolean is_read
    }
```

---

## 2. Deskripsi Kardinalitas Relasi

1. **`profiles` $\rightarrow$ `students` / `lecturers` (1 : 0..1)**:
   - Setiap baris profile yang memiliki `role = 'mahasiswa'` memiliki tepat 1 entri pada `students`.
   - Setiap baris profile yang memiliki `role = 'dosen'` memiliki tepat 1 entri pada `lecturers`.

2. **`students` $\rightarrow$ `lecturers` (N : 0..1)**:
   - Banyak mahasiswa dapat memiliki satu dosen pembimbing utama yang ditugaskan (`assigned_lecturer_id`).

3. **`students` $\rightarrow$ `topic_submissions` (1 : N)**:
   - Seorang mahasiswa dapat membuat beberapa riwayat pengajuan draf/topik, namun hanya 1 topik aktif yang dapat disetujui.

4. **`topic_submissions` $\rightarrow$ `theses` (1 : 1)**:
   - Topik yang disetujui (`status = 'APPROVED'`) menjadi basis pembentukan 1 record skripsi aktif.

5. **`theses` $\rightarrow$ `thesis_progress` (1 : 8)**:
   - Satu entitas skripsi selalu memiliki 8 record tahapan bimbingan berurutan (`stage_order = 1 s/d 8`).

6. **`consultations` $\rightarrow$ `consultation_notes` (1 : 0..1)**:
   - Konsultasi yang selesai dilaksanakan (`status = 'COMPLETED'`) menghasilkan 1 catatan konsultasi resmi dari dosen pembimbing.
