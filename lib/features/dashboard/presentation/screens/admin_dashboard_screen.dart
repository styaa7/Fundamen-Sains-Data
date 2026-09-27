import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).userProfile;

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Panel Administrator', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text(user?.email ?? 'admin@kampus.ac.id', style: const TextStyle(fontSize: 12, color: AppColors.slate500)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistik Sistem Skripsi',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.slate900),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: const [
                _AdminStatCard(title: 'Total Mahasiswa', count: '142', icon: Icons.school_outlined, color: AppColors.primary),
                _AdminStatCard(title: 'Total Dosen', count: '28', icon: Icons.badge_outlined, color: AppColors.accent),
                _AdminStatCard(title: 'Topik Diajukan', count: '35', icon: Icons.assignment_outlined, color: AppColors.warning),
                _AdminStatCard(title: 'Sesi Konsultasi', count: '312', icon: Icons.event_available_outlined, color: AppColors.success),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Manajemen Master Data',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.slate900),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.people_alt_outlined, color: AppColors.primary),
                    title: const Text('Kelola Data Mahasiswa & Dosen', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Tambah akun baru, assign pembimbing, & update profil', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.folder_copy_outlined, color: AppColors.accent),
                    title: const Text('Rekapitulasi Pengajuan Topik', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Review status topik per program studi & fakultas', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.analytics_outlined, color: AppColors.success),
                    title: const Text('Monitoring Laju Kelulusan Skripsi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Laporan waktu rata-rata penyelesaian 8 tahapan', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color color;

  const _AdminStatCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: AppColors.slate500, fontWeight: FontWeight.w500)),
              Icon(icon, size: 20, color: color),
            ],
          ),
          Text(count, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.slate900)),
        ],
      ),
    );
  }
}
