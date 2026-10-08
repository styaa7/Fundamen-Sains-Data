import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/models/user_role.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authControllerProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

    if (success && mounted) {
      final role = ref.read(authControllerProvider).role;
      switch (role) {
        case UserRole.mahasiswa:
          context.go('/student/dashboard');
          break;
        case UserRole.dosen:
          context.go('/lecturer/dashboard');
          break;
        case UserRole.admin:
          context.go('/admin/dashboard');
          break;
        default:
          context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Icon
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          size: 32,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Selamat Datang di SkripsiFlow',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Masuk untuk mengelola bimbingan, jadwal konsultasi, dan progress skripsi.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.slate500,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),

                    if (authState.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.dangerLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, size: 18, color: AppColors.danger),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                authState.errorMessage!,
                                style: const TextStyle(fontSize: 12, color: AppColors.danger),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Quick Role Selector for Easy Testing
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.slate100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.touch_app_outlined, size: 16, color: AppColors.primary),
                              SizedBox(width: 6),
                              Text('Pilih Akun Demo (1-Tap):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.slate700)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ActionChip(
                                  label: const Text('👤 Mahasiswa', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                  backgroundColor: AppColors.white,
                                  onPressed: () {
                                    _emailController.text = 'mahasiswa@kampus.ac.id';
                                    _passwordController.text = 'password123';
                                    setState(() {});
                                  },
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: ActionChip(
                                  label: const Text('👨‍🏫 Dosen', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                  backgroundColor: AppColors.white,
                                  onPressed: () {
                                    _emailController.text = 'dosen@kampus.ac.id';
                                    _passwordController.text = 'password123';
                                    setState(() {});
                                  },
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: ActionChip(
                                  label: const Text('⚙️ Admin', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                  backgroundColor: AppColors.white,
                                  onPressed: () {
                                    _emailController.text = 'admin@kampus.ac.id';
                                    _passwordController.text = 'password123';
                                    setState(() {});
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    AppTextField(
                      label: 'Email Kampus',
                      hint: 'nama@universitas.ac.id',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20, color: AppColors.slate400),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Email wajib diisi';
                        if (!val.contains('@')) return 'Format email tidak valid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Kata Sandi',
                      hint: '••••••••',
                      controller: _passwordController,
                      obscureText: true,
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.slate400),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Kata sandi wajib diisi';
                        if (val.length < 6) return 'Minimal 6 karakter';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: 'Masuk ke Aplikasi',
                      onPressed: _handleLogin,
                      isLoading: authState.isLoading,
                      isFullWidth: true,
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        'Akses multi-role (Mahasiswa, Dosen, Admin) diverifikasi otomatis oleh sistem.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.slate400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
