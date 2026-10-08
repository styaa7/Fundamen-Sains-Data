import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class LecturerDashboardScreen extends ConsumerWidget {
  const LecturerDashboardScreen({super.key});

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
              'Dr. ${user?.fullName ?? "Dosen Pembimbing"}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              'NIDN: ${user?.identifierNumber ?? "-"}',
              style: const TextStyle(fontSize: 12, color: AppColors.slate500, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => context.push('/lecturer/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => context.push('/lecturer/profile'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Metric Counters
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'Mahasiswa',
                    value: '8',
                    subValue: 'Kuota: 10',
                    icon: Icons.people_outline_rounded,
                    color: AppColors.primary,
                    onTap: () => context.push('/lecturer/students'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: 'Review Topik',
                    value: '3',
                    subValue: 'Menunggu',
                    icon: Icons.assignment_outlined,
                    color: AppColors.warning,
                    onTap: () => context.push('/lecturer/submissions'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: 'Konsultasi',
                    value: '2',
                    subValue: 'Jadwal',
                    icon: Icons.event_available_outlined,
                    color: AppColors.success,
                    onTap: () => context.push('/lecturer/consultations'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 2. Jadwal Konsultasi Hari Ini
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Konsultasi Hari Ini',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.slate900),
                ),
                TextButton(
                  onPressed: () => context.push('/lecturer/consultations'),
                  child: const Text('Lihat Semua', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AppCard(
              child: Column(
                children: [
                  _ConsultationItem(
                    name: 'Ahmad Fauzi (2021001)',
                    time: '10:00 - 11:00 WIB',
                    agenda: 'Evaluasi Model Machine Learning Bab 4',
                    status: 'CONFIRMED',
                    onAction: () {},
                  ),
                  const Divider(height: 24),
                  _ConsultationItem(
                    name: 'Siti Rahmawati (2021045)',
                    time: '13:30 - 14:30 WIB',
                    agenda: 'Diskusi Instrumen Kuesioner Bab 3',
                    status: 'REQUESTED',
                    onAction: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. Mahasiswa Bimbingan Aktif
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mahasiswa Aktif Bimbingan',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.slate900),
                ),
                TextButton(
                  onPressed: () => context.push('/lecturer/students'),
                  child: const Text('Lihat Detail', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _StudentProgressTile(
              name: 'Budi Santoso',
              nim: '2021012',
              stage: 'Seminar Hasil',
              progress: 0.875,
              onTap: () {},
            ),
            const SizedBox(height: 10),
            _StudentProgressTile(
              name: 'Dewi Lestari',
              nim: '2021088',
              stage: 'Pengumpulan Data',
              progress: 0.50,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subValue;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subValue,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.slate900),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.slate600),
          ),
          Text(
            subValue,
            style: const TextStyle(fontSize: 10, color: AppColors.slate400),
          ),
        ],
      ),
    );
  }
}

class _ConsultationItem extends StatelessWidget {
  final String name;
  final String time;
  final String agenda;
  final String status;
  final VoidCallback onAction;

  const _ConsultationItem({
    required this.name,
    required this.time,
    required this.agenda,
    required this.status,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.slate800),
            ),
            StatusBadge.fromStatus(status),
          ],
        ),
        const SizedBox(height: 4),
        Text(time, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(agenda, style: const TextStyle(fontSize: 12, color: AppColors.slate500)),
      ],
    );
  }
}

class _StudentProgressTile extends StatelessWidget {
  final String name;
  final String nim;
  final String stage;
  final double progress;
  final VoidCallback onTap;

  const _StudentProgressTile({
    required this.name,
    required this.nim,
    required this.stage,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.slate900),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text('NIM: $nim • Tahap: $stage', style: const TextStyle(fontSize: 11, color: AppColors.slate500)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.slate100,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
