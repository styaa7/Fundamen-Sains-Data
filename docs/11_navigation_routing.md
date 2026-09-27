# SkripsiFlow — Navigation & Routing Flow

Aplikasi menggunakan **GoRouter** dengan pola *Declarative Routing*, *Nested Stateful Shell Routes* untuk Bottom Navigation, serta *Guards* berbasis token auth & role.

---

## 1. Peta Rute URL (Route Tree)

```
/ (Splash & Session Check)
│
├── /login (Unauthenticated)
│
├── /student (Mahasiswa Shell Route)
│   ├── /student/dashboard
│   ├── /student/topic
│   │   ├── /student/topic/new
│   │   └── /student/topic/detail/:id
│   ├── /student/consultation
│   │   ├── /student/consultation/book
│   │   └── /student/consultation/detail/:id
│   ├── /student/progress
│   ├── /student/notifications
│   └── /student/profile
│
├── /lecturer (Dosen Shell Route)
│   ├── /lecturer/dashboard
│   ├── /lecturer/submissions
│   │   └── /lecturer/submissions/review/:id
│   ├── /lecturer/consultations
│   │   └── /lecturer/consultations/detail/:id
│   ├── /lecturer/students
│   │   └── /lecturer/students/detail/:id
│   ├── /lecturer/notifications
│   └── /lecturer/profile
│
└── /admin (Admin Shell Route)
    ├── /admin/dashboard
    ├── /admin/users
    ├── /admin/theses
    └── /admin/settings
```

---

## 2. Navigasi Mobile (Bottom Navigation Tabs)

### Mahasiswa (4 Tab):
1. 🏠 **Dashboard** (`/student/dashboard`)
2. 📄 **Topik** (`/student/topic`)
3. 📅 **Konsultasi** (`/student/consultation`)
4. 📈 **Progress** (`/student/progress`)

### Dosen (4 Tab):
1. 🏠 **Dashboard** (`/lecturer/dashboard`)
2. 📥 **Pengajuan** (`/lecturer/submissions`)
3. 📅 **Konsultasi** (`/lecturer/consultations`)
4. 👥 **Mahasiswa** (`/lecturer/students`)

### Admin (3 Tab / Sidebar):
1. 📊 **Dashboard** (`/admin/dashboard`)
2. 👥 **Pengguna** (`/admin/users`)
3. 📚 **Skripsi** (`/admin/theses`)

---

## 3. Logika Route Guard (Auth & Role Redirection)

```dart
String? routeGuard(BuildContext context, GoRouterState state) {
  final authState = ref.read(authControllerProvider);
  final isLoggingIn = state.matchedLocation == '/login';
  final isSplash = state.matchedLocation == '/';

  // 1. Jika belum login dan tidak di splash/login -> arahkan ke login
  if (!authState.isAuthenticated) {
    return (isLoggingIn || isSplash) ? null : '/login';
  }

  // 2. Jika sudah login dan membuka login/splash -> arahkan ke dashboard sesuai role
  if (isLoggingIn || isSplash) {
    switch (authState.role) {
      case UserRole.mahasiswa:
        return '/student/dashboard';
      case UserRole.dosen:
        return '/lecturer/dashboard';
      case UserRole.admin:
        return '/admin/dashboard';
    }
  }

  // 3. Cegah akses lintas role (Cross-role access prevention)
  final location = state.matchedLocation;
  if (location.startsWith('/student') && authState.role != UserRole.mahasiswa) {
    return '/login';
  }
  if (location.startsWith('/lecturer') && authState.role != UserRole.dosen) {
    return '/login';
  }
  if (location.startsWith('/admin') && authState.role != UserRole.admin) {
    return '/login';
  }

  return null; // Izin diberikan
}
```
