import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/models/topic_model.dart';
import '../../../../core/models/user_role.dart';
import '../../../../core/utils/app_date_format.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class TopicListScreen extends ConsumerStatefulWidget {
  const TopicListScreen({super.key});

  @override
  ConsumerState<TopicListScreen> createState() => _TopicListScreenState();
}

class _TopicListScreenState extends ConsumerState<TopicListScreen> {
  List<TopicSubmission> _topics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    setState(() {
      _isLoading = true;
    });

    final auth = ref.read(authControllerProvider);
    final user = auth.userProfile;
    final service = ref.read(supabaseServiceProvider);

    try {
      List<TopicSubmission> list;
      if (user?.role == UserRole.mahasiswa) {
        list = await service.fetchTopics(studentId: user?.id);
      } else if (user?.role == UserRole.dosen) {
        list = await service.fetchTopics(lecturerId: user?.id);
      } else {
        list = await service.fetchTopics();
      }

      if (mounted) {
        setState(() {
          _topics = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final isStudent = auth.userProfile?.role == UserRole.mahasiswa;

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: Text(isStudent ? 'Topik Skripsi Saya' : 'Daftar Pengajuan Topik',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      floatingActionButton: isStudent
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_rounded, color: AppColors.white),
              label: const Text('Ajukan Topik Baru', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600)),
              onPressed: () async {
                await context.push('/student/topic');
                _loadTopics();
              },
            )
          : null,
      body: _isLoading
          ? const Padding(
              padding: EdgeInsets.all(16.0),
              child: LoadingShimmer(),
            )
          : RefreshIndicator(
              onRefresh: _loadTopics,
              color: AppColors.primary,
              child: _topics.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 60),
                        EmptyStateView(
                          title: 'Belum Ada Pengajuan Topik',
                          description: isStudent
                              ? 'Anda belum mengajukan judul/topik skripsi. Klik tombol di bawah untuk membuat pengajuan baru.'
                              : 'Belum ada mahasiswa yang mengajukan topik skripsi kepada Anda.',
                          icon: Icons.article_outlined,
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _topics.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = _topics[index];
                        return InkWell(
                          onTap: () async {
                            await context.push('/student/topic/detail/${item.id}');
                            _loadTopics();
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    StatusBadge.fromStatus(item.status.name.toUpperCase()),
                                    Text(
                                      AppDateFormat.formatMedium(item.createdAt),
                                      style: const TextStyle(fontSize: 11, color: AppColors.slate400),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  item.title,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.slate900),
                                ),
                                if (item.studentName != null && item.studentName!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Mahasiswa: ${item.studentName}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Text(
                                  item.description.isNotEmpty ? item.description : item.background,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, color: AppColors.slate600, height: 1.4),
                                ),
                                const Divider(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Buka Detail Evaluasi',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primary),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
