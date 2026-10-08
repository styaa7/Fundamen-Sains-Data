import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/models/topic_model.dart';
import '../../../../core/models/topic_change_request_model.dart';
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
  TopicChangeRequest? _activeChangeRequest;
  bool _hasApprovedTopic = false;
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
      TopicChangeRequest? changeReq;
      bool hasApproved = false;

      if (user?.role == UserRole.mahasiswa) {
        list = await service.fetchTopics(studentId: user?.id);
        if (user != null) {
          changeReq = await service.fetchActiveTopicChangeRequest(user.id);
          hasApproved = await service.hasApprovedTopic(user.id) ||
              list.any((t) => t.status == TopicStatus.approved);
        }
      } else if (user?.role == UserRole.dosen) {
        list = await service.fetchTopics(lecturerId: user?.id);
        list = list.where((t) => t.status != TopicStatus.draft).toList();
      } else {
        list = await service.fetchTopics(allowedStatuses: ['SUBMITTED', 'APPROVED', 'REVISION']);
        list = list.where((t) => t.status != TopicStatus.draft).toList();
      }

      if (mounted) {
        setState(() {
          _topics = list;
          _activeChangeRequest = changeReq;
          _hasApprovedTopic = hasApproved;
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

  void _showRequestTopicChangeModal([TopicSubmission? approvedTopic]) {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    TopicSubmission? targetTopic = approvedTopic;
    if (targetTopic == null) {
      final matching = _topics.where((t) => t.status == TopicStatus.approved);
      if (matching.isNotEmpty) {
        targetTopic = matching.first;
      } else if (_topics.isNotEmpty) {
        targetTopic = _topics.first;
      }
    }

    final targetTitle = targetTopic?.title ?? 'Topik Skripsi Saat Ini';
    final lecturerName = targetTopic?.lecturerName ?? 'Dosen Pembimbing';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.slate300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.warningLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.swap_horiz_rounded, color: AppColors.warning, size: 22),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Permohonan Pergantian Topik',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.slate900),
                            ),
                            Text(
                              'Ajukan permohonan ke dosen untuk ganti judul skripsi',
                              style: TextStyle(fontSize: 11, color: AppColors.slate500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.slate50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Topik Skripsi Saat Ini (Disetujui):',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.slate500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          targetTitle,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.slate900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Dosen Pembimbing: $lecturerName',
                          style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Alasan Mengapa Ganti Topik *',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.slate800),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: reasonController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Jelaskan secara rinci alasan dan kendala mengapa Anda ingin mengganti topik skripsi ini (minimal 15 karakter)...',
                      hintStyle: const TextStyle(fontSize: 12, color: AppColors.slate400),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Alasan ganti topik wajib diisi';
                      }
                      if (val.trim().length < 15) {
                        return 'Alasan harus diisi minimal 15 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 14, color: AppColors.slate500),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Jika disetujui dosen, fitur pengajuan topik baru akan aktif kembali.',
                          style: TextStyle(fontSize: 11, color: AppColors.slate500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                        child: const Text('Batal', style: TextStyle(color: AppColors.slate500)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (formKey.currentState?.validate() ?? false) {
                                  setModalState(() => isSubmitting = true);
                                  try {
                                    final auth = ref.read(authControllerProvider);
                                    final user = auth.userProfile;
                                    final service = ref.read(supabaseServiceProvider);

                                    await service.submitTopicChangeRequest(
                                      studentId: user?.id ?? '',
                                      lecturerId: targetTopic?.lecturerId ?? '',
                                      reason: reasonController.text.trim(),
                                      currentTopicId: targetTopic?.id,
                                    );

                                    if (context.mounted) {
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Row(
                                            children: [
                                              Icon(Icons.check_circle_rounded, color: AppColors.white, size: 18),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: Text('Permohonan pergantian topik berhasil dikirim ke dosen!'),
                                              ),
                                            ],
                                          ),
                                          backgroundColor: AppColors.success,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      );
                                      _loadTopics();
                                    }
                                  } catch (e) {
                                    setModalState(() => isSubmitting = false);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Gagal mengirim permohonan: $e'),
                                          backgroundColor: AppColors.danger,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                        icon: isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.send_rounded, size: 16),
                        label: Text(isSubmitting ? 'Mengirim...' : 'Kirim Permohonan'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
          ? (_hasApprovedTopic
              ? (_activeChangeRequest != null && _activeChangeRequest!.isPending
                  ? FloatingActionButton.extended(
                      backgroundColor: AppColors.slate400,
                      icon: const Icon(Icons.lock_outline_rounded, color: AppColors.white),
                      label: const Text('Menunggu Review Dosen', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600)),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Permohonan pergantian topik Anda sedang ditinjau oleh dosen pembimbing.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    )
                  : FloatingActionButton.extended(
                      backgroundColor: AppColors.warning,
                      icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.white),
                      label: const Text('Ganti Topik Skripsi', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600)),
                      onPressed: () => _showRequestTopicChangeModal(),
                    ))
              : FloatingActionButton.extended(
                  backgroundColor: AppColors.primary,
                  icon: const Icon(Icons.add_rounded, color: AppColors.white),
                  label: const Text('Ajukan Topik Baru', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600)),
                  onPressed: () async {
                    await context.push('/student/topic/new');
                    _loadTopics();
                  },
                ))
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
                          actionLabel: isStudent && !_hasApprovedTopic ? 'Ajukan Topik Sekarang' : null,
                          onAction: isStudent && !_hasApprovedTopic
                              ? () async {
                                  await context.push('/student/topic/new');
                                  _loadTopics();
                                }
                              : null,
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (isStudent && _hasApprovedTopic) ...[
                          if (_activeChangeRequest != null && _activeChangeRequest!.isPending) ...[
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.warningLight.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.hourglass_top_rounded, color: AppColors.warning, size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        'Permohonan Ganti Topik Sedang Ditinjau',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.warning),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Alasan: "${_activeChangeRequest!.reason}"',
                                    style: const TextStyle(fontSize: 12, color: AppColors.slate700, fontStyle: FontStyle.italic),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Pengajuan topik baru dinonaktifkan sementara hingga permohonan disetujui dosen.',
                                    style: TextStyle(fontSize: 11, color: AppColors.slate500),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.verified_rounded, color: AppColors.primary, size: 24),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Topik Skripsi Telah Disetujui',
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                                        ),
                                        const SizedBox(height: 2),
                                        const Text(
                                          'Pengajuan topik baru dinonaktifkan. Anda dapat mengajukan pergantian topik jika diperlukan.',
                                          style: TextStyle(fontSize: 11, color: AppColors.slate600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.warning,
                                      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                                    ),
                                    onPressed: () => _showRequestTopicChangeModal(),
                                    child: const Text('Ganti Topik'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                        ..._topics.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
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
                                if (isStudent && (item.status == TopicStatus.draft || item.status == TopicStatus.revision)) ...[
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: item.status == TopicStatus.revision ? AppColors.warning : AppColors.primary,
                                        foregroundColor: AppColors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                      ),
                                      onPressed: () async {
                                        await context.push('/student/topic/edit/${item.id}', extra: item);
                                        _loadTopics();
                                      },
                                      icon: const Icon(Icons.edit_note_rounded, size: 16),
                                      label: Text(
                                        item.status == TopicStatus.revision ? 'Revisi & Ajukan Ulang' : 'Lanjutkan & Ajukan Draf',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ),
                                ],
                                const Divider(height: 20),
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Buka Detail Evaluasi',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                                    Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primary),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 80),
                  ],
                ),
        ),
    );
  }
}
