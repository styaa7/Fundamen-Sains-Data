# SkripsiFlow — Dokumentasi Arsitektur & Spesifikasi Teknis

Selamat datang di repositori dokumentasi teknis **SkripsiFlow**, aplikasi SaaS Bimbingan Skripsi modern, minimalis, dan terstruktur untuk perguruan tinggi berbasis **Flutter** dan **Supabase**.

---

## 📑 Daftar Dokumen Arsitektur & Spesifikasi

Dokumen spesifikasi telah dipecah secara modular menjadi 14 bagian:

| No | Dokumen | Deskripsi |
| :---: | :--- | :--- |
| **01** | [Arsitektur Sistem](01_system_architecture.md) | High-level architecture, layer Flutter, Supabase & Edge Functions. |
| **02** | [User Flows & Sequence Diagrams](02_user_flows.md) | Alur interaksi pengguna untuk Pengajuan Topik, Booking Bebas Bentrok, dan Catatan Konsultasi. |
| **03** | [Database Schema & DDL](03_database_schema.md) | Skema DDL lengkap PostgreSQL (9 tabel, tipe data, enum, constraints, dan index). |
| **04** | [Entity Relationship Diagram (ERD)](04_erd.md) | Pemodelan relasi dan kardinalitas antar entitas basis data. |
| **05** | [Role & Permission Matrix](05_role_permission_matrix.md) | Matriks hak akses CRUD untuk Mahasiswa, Dosen Pembimbing, dan Admin. |
| **06** | [Status & State Transitions](06_state_transitions.md) | State machine siklus topik, konsultasi, serta formula 8 tahapan skripsi. |
| **07** | [Struktur Folder & Arsitektur Flutter](07_flutter_architecture.md) | Clean Feature-First structure, Riverpod state management, dan UI theming. |
| **08** | [Spesifikasi Supabase Edge Functions](08_edge_functions_spec.md) | Kontrak API untuk `book-consultation`, `process-topic-review`, dan `send-notification`. |
| **09** | [Row Level Security (RLS) Policies](09_rls_security_policies.md) | Kebijakan SQL RLS PostgreSQL untuk menjamin isolasi data multi-role. |
| **10** | [Screen Inventory & UI Specs](10_screen_inventory.md) | Daftar 13 layar Flutter, komponen, empty states, dan error states. |
| **11** | [Navigation & Routing Flow](11_navigation_routing.md) | Skema deklaratif GoRouter dengan Role Guarding dan Shell Routes. |
| **12** | [API & Data Flow Lifecycle](12_api_data_flow.md) | Siklus komunikasi data client-to-backend dan realtime listener. |
| **13** | [Validation Rules Specification](13_validation_rules.md) | Aturan validasi client-side (Flutter) dan database/server-side. |
| **14** | [Acceptance Criteria & Definition of Done](14_acceptance_criteria.md) | Checklist kriteria pengujian dan kesiapan rilis MVP. |

---

## 🚀 Tech Stack Ringkas
- **Frontend / Client**: Flutter 3.x (Dart 3.x)
- **Backend & Database**: Supabase (PostgreSQL 15+, Supabase Auth, Storage, Realtime)
- **Serverless Business Logic**: Supabase Edge Functions (Deno / TypeScript)
