import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  Map<String, int> _stats = {
    'students': 0,
    'lecturers': 0,
    'topics': 0,
    'consultations': 0,
  };
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoadingStats = true);
    try {
      final res = await ref.read(supabaseServiceProvider).fetchAdminStats();
      if (mounted) {
        setState(() {
          _stats = res;
          _isLoadingStats = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
      body: RefreshIndicator(
        onRefresh: _loadStats,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                childAspectRatio: 2.0,
                children: [
                  _AdminStatCard(
                    title: 'Total Mahasiswa',
                    count: _isLoadingStats ? '...' : '${_stats['students']}',
                    icon: Icons.school_outlined,
                    color: AppColors.primary,
                  ),
                  _AdminStatCard(
                    title: 'Total Dosen',
                    count: _isLoadingStats ? '...' : '${_stats['lecturers']}',
                    icon: Icons.badge_outlined,
                    color: AppColors.accent,
                  ),
                  _AdminStatCard(
                    title: 'Topik Diajukan',
                    count: _isLoadingStats ? '...' : '${_stats['topics']}',
                    icon: Icons.assignment_outlined,
                    color: AppColors.warning,
                  ),
                  _AdminStatCard(
                    title: 'Sesi Konsultasi',
                    count: _isLoadingStats ? '...' : '${_stats['consultations']}',
                    icon: Icons.event_available_outlined,
                    color: AppColors.success,
                  ),
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
                      subtitle: const Text('Lihat data akun, ubah profil, atau kelola pengguna', style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () async {
                        await context.push('/admin/users');
                        _loadStats();
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.folder_copy_outlined, color: AppColors.accent),
                      title: const Text('Rekapitulasi Pengajuan Topik', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Review seluruh usulan topik mahasiswa & calon pembimbing', style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () async {
                        await context.push('/admin/topics');
                        _loadStats();
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.analytics_outlined, color: AppColors.success),
                      title: const Text('Monitoring Laju Kelulusan Skripsi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Laporan progress mahasiswa & 8 tahapan skripsi', style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () async {
                        await context.push('/admin/theses');
                        _loadStats();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.slate500, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, size: 18, color: color),
            ],
          ),
          Text(count, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.slate900)),
        ],
      ),
    );
  }
}
