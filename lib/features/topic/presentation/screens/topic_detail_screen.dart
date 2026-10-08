import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/models/topic_model.dart';
import '../../../../core/models/user_role.dart';
import '../../../../core/utils/app_date_format.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class TopicDetailScreen extends ConsumerStatefulWidget {
  final String topicId;

  const TopicDetailScreen({super.key, required this.topicId});

  @override
  ConsumerState<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends ConsumerState<TopicDetailScreen> {
  TopicSubmission? _topic;
  bool _isLoadingTopic = true;
  bool _isActionLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTopicData();
  }

  Future<void> _loadTopicData() async {
    setState(() {
      _isLoadingTopic = true;
      _errorMessage = null;
    });

    final service = ref.read(supabaseServiceProvider);

    try {
      TopicSubmission? loadedTopic;
      if (widget.topicId.isNotEmpty && widget.topicId != 'demo-topic-id') {
        loadedTopic = await service.fetchTopicById(widget.topicId);
      }

      // If not found or demo-id, fetch the first available topic
      if (loadedTopic == null) {
        final list = await service.fetchTopics();
        if (list.isNotEmpty) {
          loadedTopic = list.first;
        }
      }

      if (mounted) {
        setState(() {
          _topic = loadedTopic;
          _isLoadingTopic = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoadingTopic = false;
        });
      }
    }
  }

  Future<void> _handleLecturerReview(String action) async {
    if (_topic == null) return;
    final feedbackController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Konfirmasi Review ($action)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Berikan catatan atau feedback untuk mahasiswa:'),
            const SizedBox(height: 12),
            TextField(
              controller: feedbackController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Tuliskan catatan evaluasi di sini...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Kirim Review'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isActionLoading = true);
      try {
        await ref.read(supabaseServiceProvider).reviewTopic(
              topicId: _topic!.id,
              action: action,
              feedback: feedbackController.text.trim(),
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(backgroundColor: AppColors.success, content: Text('Review $action berhasil disimpan')),
          );
          _loadTopicData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(backgroundColor: AppColors.danger, content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isActionLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).userProfile;
    final isLecturer = user?.role == UserRole.dosen;

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: const Text('Detail Pengajuan Topik', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      body: _isLoadingTopic
          ? const Padding(
              padding: EdgeInsets.all(16.0),
              child: LoadingShimmer(),
            )
          : _topic == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.description_outlined, size: 64, color: AppColors.slate300),
                        const SizedBox(height: 16),
                        const Text(
                          'Pengajuan Topik Tidak Ditemukan',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.slate800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage ?? 'Belum ada data pengajuan topik yang tersimpan.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, color: AppColors.slate500),
                        ),
                        const SizedBox(height: 20),
                        AppButton(
                          label: 'Kembali',
                          onPressed: () => context.pop(),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                StatusBadge.fromStatus(_topic!.status.name.toUpperCase()),
                                Text(AppDateFormat.formatDateTime(_topic!.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.slate400)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _topic!.title,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.slate900),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Oleh: ${_topic!.studentName ?? "Mahasiswa Bimbingan"}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Content Sections
                      _DetailSection(
                        title: 'Latar Belakang',
                        content: _topic!.background.isNotEmpty ? _topic!.background : '-',
                      ),
                      const SizedBox(height: 12),
                      _DetailSection(
                        title: 'Rumusan Masalah',
                        content: _topic!.problemFormulation.isNotEmpty ? _topic!.problemFormulation : '-',
                      ),
                      const SizedBox(height: 12),
                      _DetailSection(
                        title: 'Tujuan Penelitian',
                        content: _topic!.researchObjective.isNotEmpty ? _topic!.researchObjective : '-',
                      ),
                      const SizedBox(height: 12),
                      _DetailSection(
                        title: 'Rencana Metodologi',
                        content: _topic!.methodology.isNotEmpty ? _topic!.methodology : '-',
                      ),
                      const SizedBox(height: 16),

                      // Lecturer Feedback Section if available
                      if (_topic!.lecturerFeedback != null && _topic!.lecturerFeedback!.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.feedback_outlined, size: 18, color: AppColors.primary),
                                  SizedBox(width: 8),
                                  Text('Catatan / Catatan Revisi Dosen:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _topic!.lecturerFeedback!,
                                style: const TextStyle(fontSize: 13, color: AppColors.slate800, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Lecturer Action Bar
                      if (isLecturer && (_topic!.status == TopicStatus.submitted || _topic!.status == TopicStatus.underReview || _topic!.status == TopicStatus.draft)) ...[
                        const Text('Aksi Review Dosen', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.slate900)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                label: 'Setujui',
                                onPressed: () => _handleLecturerReview('APPROVED'),
                                type: ButtonType.primary,
                                isLoading: _isActionLoading,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: AppButton(
                                label: 'Revisi',
                                onPressed: () => _handleLecturerReview('REVISION'),
                                type: ButtonType.secondary,
                                isLoading: _isActionLoading,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: AppButton(
                                label: 'Tolak',
                                onPressed: () => _handleLecturerReview('REJECTED'),
                                type: ButtonType.danger,
                                isLoading: _isActionLoading,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final String content;

  const _DetailSection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.slate800)),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 13, color: AppColors.slate600, height: 1.5)),
        ],
      ),
    );
  }
}
