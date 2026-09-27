# SkripsiFlow — Flutter Architecture & Folder Structure

Dokumen ini menjelaskan struktur arsitektur frontend Flutter berbasis **Feature-First Clean Architecture**, pola manajemen state, serta pedoman UI/UX.

---

## 1. Struktur Direktori Proyek

```
lib/
├── app/
│   ├── app.dart                   # Root MaterialApp, theme, global providers
│   ├── config/
│   │   ├── env.dart               # Environment variables (Supabase URL, Anon Key)
│   │   └── supabase_config.dart   # Inisialisasi Supabase Client
│   ├── router/
│   │   ├── app_router.dart        # GoRouter configuration & route definitions
│   │   └── route_guards.dart      # Auth & Role-based redirection logic
│   └── theme/
│       ├── app_colors.dart        # Indigo primary, Slate neutral, Emerald success, Rose error
│       ├── app_typography.dart    # Google Fonts Inter, headings, body text
│       └── app_theme.dart         # Light & Dark theme data
├── core/
│   ├── constants/
│   │   ├── app_constants.dart     # String constants, asset paths
│   │   └── stage_constants.dart   # Daftar 8 tahapan skripsi & bobot
│   ├── error/
│   │   ├── exceptions.dart        # Custom app exceptions
│   │   └── failures.dart          # Domain failure representations
│   ├── network/
│   │   └── supabase_service.dart  # Supabase client wrapper & helper methods
│   ├── utils/
│   │   ├── date_formatter.dart    # Format tanggal Indonesia (e.g. 28 September 2026)
│   │   ├── file_helper.dart       # File picker & validator PDF
│   │   └── validators.dart        # Form input validators
│   └── widgets/                   # Reusable atomic UI components
│       ├── app_button.dart        # Primary, secondary, outline, danger buttons
│       ├── app_text_field.dart    # Form input field with validation
│       ├── app_card.dart          # Standard modern rounded elevation card
│       ├── status_badge.dart      # Status chip (APPROVED, DRAFT, dll)
│       ├── empty_state_view.dart  # Clean empty placeholder with illustration
│       ├── error_state_view.dart  # Error retry view
│       ├── loading_shimmer.dart   # Shimmer effect skeleton loading
│       └── responsive_layout.dart # Breakpoint detector (Mobile/Tablet/Desktop)
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/auth_remote_datasource.dart
│   │   │   └── repositories/auth_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── models/user_profile.dart
│   │   │   └── repositories/auth_repository.dart
│   │   └── presentation/
│   │       ├── controllers/auth_controller.dart
│   │       └── screens/login_screen.dart
│   ├── dashboard/
│   │   └── presentation/
│   │       ├── screens/student_dashboard_screen.dart
│   │       ├── screens/lecturer_dashboard_screen.dart
│   │       ├── screens/admin_dashboard_screen.dart
│   │       └── widgets/progress_summary_card.dart
│   ├── topic/
│   │   ├── data/ (datasource, repository)
│   │   ├── domain/ (topic_submission model)
│   │   └── presentation/
│   │       ├── screens/topic_form_screen.dart
│   │       ├── screens/topic_detail_screen.dart
│   │       └── widgets/topic_review_dialog.dart
│   ├── consultation/
│   │   ├── data/ (datasource, repository)
│   │   ├── domain/ (consultation & notes models)
│   │   └── presentation/
│   │       ├── screens/consultation_booking_screen.dart
│   │       ├── screens/consultation_list_screen.dart
│   │       └── screens/consultation_detail_screen.dart
│   ├── progress/
│   │   ├── data/ (datasource, repository)
│   │   ├── domain/ (thesis_progress model)
│   │   └── presentation/
│   │       ├── screens/progress_timeline_screen.dart
│   │       └── widgets/stage_item_tile.dart
│   ├── notifications/
│   │   ├── data/ (datasource, repository)
│   │   └── presentation/
│   │       ├── controllers/notification_controller.dart
│   │       └── screens/notification_center_screen.dart
│   └── profile/
│       └── presentation/screens/profile_screen.dart
└── main.dart                      # App entry point
```

---

## 2. Pola Arsitektur State Management

- **Pola**: Controller / StateNotifier (Riverpod).
- **Alur Data**:
  1. `UI / Widget` mendengarkan state dari `StateNotifierProvider`.
  2. `Controller` memanggil `Repository`.
  3. `Repository` berinteraksi dengan `SupabaseService` atau `RemoteDataSource`.
  4. Response dipetakan ke Immutable Domain Models (`freezed` / Dart classes).
  5. UI memperbarui tampilannya secara reaktif (*reactive rebuilds*).

---

## 3. Strategi Desain Responsif & Tema

- **Palet Warna Utama**:
  - *Primary*: Deep Indigo (`#4F46E5`)
  - *Accent*: Violet (`#7C3AED`)
  - *Neutral Dark*: Slate 900 (`#0F172A`)
  - *Neutral Light*: Slate 50 (`#F8FAFC`)
  - *Success*: Emerald 600 (`#059669`)
  - *Warning*: Amber 500 (`#F59E0B`)
  - *Danger*: Rose 600 (`#E11D48`)
- **Typography**: Google Fonts Inter / Plus Jakarta Sans.
- **Breakpoints**:
  - Compact (Mobile): `< 600dp` $\to$ Bottom Navigation Bar.
  - Medium (Tablet): `600dp - 1024dp` $\to$ Navigation Rail.
  - Expanded (Desktop): `> 1024dp` $\to$ Persistent Sidebar Navigation.
