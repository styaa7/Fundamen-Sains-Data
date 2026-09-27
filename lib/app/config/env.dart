class Env {
  // Ganti nilai berikut dengan kredensial project Supabase Anda
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ynkxbswunnviqprvuajy.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inlua3hic3d1bm52aXFwcnZ1YWp5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA0OTkwNzcsImV4cCI6MjEwNjA3NTA3N30.1GgrJTUNkK_fsN2x14EdCVIq6ZlV47EVuKY8Adr8xDo',
  );

  static const String appName = 'SkripsiFlow';
  static const String appTagline = 'SaaS Bimbingan Skripsi Terstruktur';
}
