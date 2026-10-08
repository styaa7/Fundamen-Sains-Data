import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/app.dart';
import 'app/config/env.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi data format tanggal bahasa Indonesia
  await initializeDateFormatting('id_ID', null);

  // Inisialisasi Supabase SDK
  try {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );
  } catch (e) {
    debugPrint('Supabase initialization warning (demo mode if config empty): $e');
  }

  runApp(
    const ProviderScope(
      child: SkripsiFlowApp(),
    ),
  );
}
