import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).userProfile;

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Halo, ${user?.fullName ?? "Mahasiswa"} 👋',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              'NIM: ${user?.identifierNumber ?? "-"}',
              style: const TextStyle(fontSize: 12, color: AppColors.slate500, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => context.push('/student/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => context.push('/student/profile'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Progress Banner Card
            AppCard(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Progress Skripsi',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '62.5%',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: 0.625,
                      minHeight: 8,
                      backgroundColor: AppColors.white.withOpacity(0.25),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Tahap Saat Ini:',
                        style: TextStyle(color: AppColors.primaryLight, fontSize: 12),
                      ),
                      Text(
                        'Analisis Data (Tahap 5/8)',
                        style: TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Status Topik Card
            AppCard(
              onTap: () => context.push('/student/topic'),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.description_outlined, color: AppColors.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Topik Skripsi',
                          style: TextStyle(fontSize: 12, color: AppColors.slate500),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Sistem Klasifikasi Citra...',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.slate900),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  StatusBadge.fromStatus('APPROVED'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Konsultasi Berikutnya Card
            AppCard(
              onTap: () => context.push('/student/consultation'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Konsultasi Berikutnya',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.slate800),
                      ),
                      StatusBadge.fromStatus('CONFIRMED'),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.slate400),
                      const SizedBox(width: 8),
                      const Text(
                        '28 September 2026',
                        style: TextStyle(fontSize: 13, color: AppColors.slate700, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.access_time_rounded, size: 16, color: AppColors.slate400),
                      const SizedBox(width: 6),
                      const Text(
                        '10:00 - 11:00 WIB',
                        style: TextStyle(fontSize: 13, color: AppColors.slate700, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Agenda: Evaluasi Algoritma dan Matriks Konfusi Bab 4',
                    style: TextStyle(fontSize: 12, color: AppColors.slate500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 4. Quick Actions
            const Text(
              'Akses Cepat',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.slate900),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ShortcutCard(
                    icon: Icons.note_add_outlined,
                    label: 'Pengajuan Topik',
                    onTap: () => context.push('/student/topic'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ShortcutCard(
                    icon: Icons.event_available_outlined,
                    label: 'Jadwal Konsultasi',
                    onTap: () => context.push('/student/consultation'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ShortcutCard(
                    icon: Icons.timeline_rounded,
                    label: 'Progress Skripsi',
                    onTap: () => context.push('/student/progress'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ShortcutCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.slate800),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
