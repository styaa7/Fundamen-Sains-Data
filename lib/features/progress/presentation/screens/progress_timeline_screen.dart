import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/models/thesis_progress_model.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class ProgressTimelineScreen extends ConsumerStatefulWidget {
  final String? studentId;

  const ProgressTimelineScreen({super.key, this.studentId});

  @override
  ConsumerState<ProgressTimelineScreen> createState() => _ProgressTimelineScreenState();
}

class _ProgressTimelineScreenState extends ConsumerState<ProgressTimelineScreen> {
  bool _isLoading = true;
  Thesis? _thesis;

  static const List<String> _defaultStageNames = [
    'Pengajuan Topik',
    'Proposal Skripsi',
    'Seminar Proposal',
    'Pengumpulan Data',
    'Analisis Data',
    'Penyusunan Naskah',
    'Seminar Hasil',
    'Sidang Akhir',
  ];

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    setState(() => _isLoading = true);
    try {
      final user = ref.read(authControllerProvider).userProfile;
      final targetId = widget.studentId ?? user?.id ?? '';
      final service = ref.read(supabaseServiceProvider);

      final thesisData = await service.fetchStudentThesis(targetId);
      if (mounted) {
        setState(() {
          _thesis = thesisData;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.slate50,
        appBar: AppBar(
          title: const Text('Monitoring Progress Skripsi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
        body: const Padding(
          padding: EdgeInsets.all(16.0),
          child: LoadingShimmer(),
        ),
      );
    }

    final overallPct = _thesis?.overallProgressPercentage ?? 0.0;
    final currentStage = _thesis?.currentStageOrder ?? 1;

    // Build the stages list
    List<Map<String, dynamic>> stagesList = [];
    if (_thesis != null && _thesis!.stages.isNotEmpty) {
      stagesList = _thesis!.stages.map((st) {
        return {
          'order': st.stageOrder,
          'name': st.stageName,
          'status': st.status == StageStatus.completed
              ? 'COMPLETED'
              : (st.status == StageStatus.inProgress ? 'IN_PROGRESS' : 'NOT_STARTED'),
          'notes': st.studentNotes,
        };
      }).toList();
    } else {
      stagesList = List.generate(8, (i) {
        return {
          'order': i + 1,
          'name': _defaultStageNames[i],
          'status': 'NOT_STARTED',
          'notes': null,
        };
      });
    }

    final completedCount = stagesList.where((s) => s['status'] == 'COMPLETED').length;

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: const Text('Monitoring Progress Skripsi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadProgress,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Notice Banner
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Persetujuan Dosen: Tahap baru roadmap hanya akan dibuka setelah tahapan berjalan disetujui secara resmi oleh Dosen Pembimbing.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF1E40AF), height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),

              // Gauge Card
              AppCard(
                backgroundColor: AppColors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_thesis?.title != null) ...[
                      Text(
                        _thesis!.title,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.slate800),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Progres Kumulatif', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.slate900)),
                        Text('${overallPct.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (overallPct / 100.0).clamp(0.0, 1.0),
                        minHeight: 10,
                        backgroundColor: AppColors.slate100,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$completedCount dari 8 Tahap Selesai', style: const TextStyle(fontSize: 12, color: AppColors.slate500)),
                        Text(
                          overallPct >= 100.0 ? 'Skripsi Selesai' : 'Sedang Berjalan: Tahap $currentStage',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Timeline List
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: stagesList.length,
                itemBuilder: (context, index) {
                  final stage = stagesList[index];
                  final isLast = index == stagesList.length - 1;
                  final status = stage['status'] as String;

                  Color iconColor = AppColors.slate300;
                  IconData icon = Icons.radio_button_unchecked_rounded;

                  if (status == 'COMPLETED') {
                    iconColor = AppColors.success;
                    icon = Icons.check_circle_rounded;
                  } else if (status == 'IN_PROGRESS') {
                    iconColor = AppColors.primary;
                    icon = Icons.timelapse_rounded;
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Timeline Line & Icon
                      Column(
                        children: [
                          Icon(icon, size: 24, color: iconColor),
                          if (!isLast)
                            Container(
                              width: 2,
                              height: 60,
                              color: status == 'COMPLETED' ? AppColors.success.withOpacity(0.4) : AppColors.slate200,
                            ),
                        ],
                      ),
                      const SizedBox(width: 14),

                      // Content Card
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: AppCard(
                            onTap: () {
                              final notes = stage['notes'] as String?;
                              final msg = status == 'COMPLETED'
                                  ? 'Tahap ini telah disetujui Dosen Pembimbing.'
                                  : (status == 'IN_PROGRESS'
                                      ? 'Tahap ini sedang berjalan. Tunggu persetujuan Dosen untuk beralih ke tahap berikutnya.'
                                      : 'Tahap ini terkunci hingga tahap sebelumnya disetujui.');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppColors.primary,
                                  content: Text('$msg ${notes != null ? "\nCatatan: $notes" : ""}'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${stage['order']}. ${stage['name']}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: status == 'NOT_STARTED' ? AppColors.slate400 : AppColors.slate900,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        status == 'COMPLETED'
                                            ? 'Disetujui Dosen Pembimbing'
                                            : (status == 'IN_PROGRESS' ? 'Memerlukan Persetujuan Dosen' : 'Terkunci'),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: status == 'COMPLETED'
                                              ? AppColors.success
                                              : (status == 'IN_PROGRESS' ? AppColors.primary : AppColors.slate400),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                StatusBadge.fromStatus(status),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
