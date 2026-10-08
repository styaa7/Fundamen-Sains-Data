import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class LecturerStudentDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> thesis;

  const LecturerStudentDetailScreen({super.key, required this.thesis});

  @override
  ConsumerState<LecturerStudentDetailScreen> createState() => _LecturerStudentDetailScreenState();
}

class _LecturerStudentDetailScreenState extends ConsumerState<LecturerStudentDetailScreen>
    with SingleTickerProviderStateMixin {
  late Map<String, dynamic> _currentThesis;
  late TabController _tabController;

  static const List<String> _stageNames = [
    'Pengajuan Topik',
    'Proposal Skripsi',
    'Seminar Proposal',
    'Pengumpulan Data',
    'Analisis Data',
    'Penyusunan Naskah',
    'Seminar Hasil',
    'Sidang Akhir',
  ];

  static const List<String> _stageDescriptions = [
    'Pengajuan usulan judul, rumusan masalah, dan tujuan penelitian.',
    'Penyusunan naskah proposal skripsi Bab 1 hingga Bab 3.',
    'Pemaparan proposal penelitian di depan dosen penguji dan pembimbing.',
    'Pengumpulan sampel data, survei lapangan, atau dataset eksperimen.',
    'Pengolahan data, pelatihan model, dan evaluasi hasil analisis.',
    'Penulisan naskah lengkap Bab 4 Hasil dan Bab 5 Kesimpulan.',
    'Presentasi hasil capaian penelitian skripsi yang telah diuji.',
    'Ujian pendadaran akhir skripsi dan yudisium kelulusan sarjana.',
  ];

  @override
  void initState() {
    super.initState();
    _currentThesis = Map<String, dynamic>.from(widget.thesis);
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshThesisData() async {
    try {
      final user = ref.read(authControllerProvider).userProfile;
      final service = ref.read(supabaseServiceProvider);
      final list = await service.fetchLecturerTheses(user?.id ?? '');
      final updated = list.firstWhere(
        (t) => t['id'] == _currentThesis['id'],
        orElse: () => _currentThesis,
      );
      if (mounted) {
        setState(() {
          _currentThesis = updated;
        });
      }
    } catch (_) {}
  }

  Future<void> _showApproveStageDialog() async {
    final currentStage = _currentThesis['current_stage_order'] as int? ?? 1;
    final isFinalStage = currentStage >= 8;
    final currentStageName =
        _stageNames.length >= currentStage ? _stageNames[currentStage - 1] : 'Tahap $currentStage';
    final nextStageName = !isFinalStage && _stageNames.length >= currentStage + 1
        ? _stageNames[currentStage]
        : 'Selesai / Lulus';

    final student = _currentThesis['student_profile'];
    final studentName = student?['full_name'] ?? 'Mahasiswa';
    final studentNim = student?['identifier_number'] ?? '-';
    final notesController = TextEditingController();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.verified_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Setujui Lanjut Tahap',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Verifikasi penyelesaian tahap untuk mahasiswa:',
                  style: TextStyle(fontSize: 12, color: AppColors.slate600),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.slate50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentName,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.slate900),
                      ),
                      Text(
                        'NIM: $studentNim',
                        style: const TextStyle(fontSize: 11, color: AppColors.slate500),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _currentThesis['title'] ?? 'Skripsi',
                        style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.slate700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Stage transition card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Menyelesaikan: $currentStageName',
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF166534)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.arrow_forward_rounded, color: AppColors.primary, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              isFinalStage ? 'Status: Lulus / Sidang Selesai 🎓' : 'Membuka: $nextStageName',
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Catatan Evaluasi / Arahan Pembimbing (Opsional):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.slate700)),
                const SizedBox(height: 6),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Contoh: Naskah Bab 3 disetujui, silakan lanjut persiapan Sempro...',
                    hintStyle: const TextStyle(fontSize: 12, color: AppColors.slate400),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: AppColors.slate500)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      setDialogState(() => isSubmitting = true);
                      try {
                        final service = ref.read(supabaseServiceProvider);
                        await service.approveAndAdvanceThesisStage(
                          thesisId: _currentThesis['id'],
                          studentId: _currentThesis['student_id'],
                          currentStageOrder: currentStage,
                          lecturerNotes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
                        );

                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.slate800,
                              content: Text(
                                isFinalStage
                                    ? 'Seluruh tahapan skripsi telah disetujui! Mahasiswa dinyatakan selesai. 🎓'
                                    : 'Tahap $currentStage disetujui. Mahasiswa telah masuk ke $nextStageName! 🚀',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          _refreshThesisData();
                        }
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.danger,
                              content: Text('Gagal menyetujui tahap: $e'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                    )
                  : const Text('Konfirmasi & Lanjutkan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final student = _currentThesis['student_profile'];
    final studentName = student?['full_name'] ?? 'Mahasiswa';
    final studentNim = student?['identifier_number'] ?? '-';
    final currentStage = _currentThesis['current_stage_order'] as int? ?? 1;
    final progress = ((_currentThesis['overall_progress_percentage'] as num?)?.toDouble() ?? 0.0) / 100.0;
    final isCompletedAll = currentStage >= 8 && progress >= 1.0;

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              studentName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              'NIM: $studentNim • Monitoring Skripsi',
              style: const TextStyle(fontSize: 11.5, color: AppColors.slate500, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.slate500,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          tabs: const [
            Tab(icon: Icon(Icons.route_outlined, size: 20), text: 'Roadmap & Progres'),
            Tab(icon: Icon(Icons.description_outlined, size: 20), text: 'Topik Skripsi'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshThesisData,
        color: AppColors.primary,
        child: TabBarView(
          controller: _tabController,
          children: [
            // TAB 1: ROADMAP & PROGRES SKRIPSI
            _buildRoadmapTab(progress, currentStage, isCompletedAll),

            // TAB 2: TOPIK SKRIPSI LENGKAP
            _buildTopicDetailTab(),
          ],
        ),
      ),
      bottomNavigationBar: !isCompletedAll
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      offset: const Offset(0, -3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.slate700,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => context.push('/lecturer/consultations'),
                        icon: const Icon(Icons.calendar_month_outlined, size: 16),
                        label: const Text('Jadwal Konsultasi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _showApproveStageDialog,
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 17),
                        label: Text(
                          'Setujui Tahap $currentStage & Lanjut',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  // WIDGET: TAB ROADMAP
  Widget _buildRoadmapTab(double progress, int currentStage, bool isCompletedAll) {
    final stages = (_currentThesis['thesis_progress'] as List<dynamic>?) ?? [];
    stages.sort((a, b) => (a['stage_order'] as int).compareTo(b['stage_order'] as int));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Overall Progress Hero Card
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isCompletedAll ? AppColors.successLight : AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCompletedAll ? Icons.school_rounded : Icons.trending_up_rounded,
                          color: isCompletedAll ? AppColors.success : AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Status Progres Skripsi',
                            style: TextStyle(fontSize: 11, color: AppColors.slate500, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            isCompletedAll ? 'Lulus / Selesai' : 'Tahap $currentStage dari 8 Berjalan',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.slate900),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isCompletedAll ? AppColors.success : AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppColors.slate100,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompletedAll ? AppColors.success : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        const Row(
          children: [
            Icon(Icons.timeline_rounded, size: 18, color: AppColors.primary),
            SizedBox(width: 6),
            Text(
              '8 Tahapan Roadmap Skripsi',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.slate900),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 8 Stages Timeline
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 8,
          itemBuilder: (context, index) {
            final stageOrder = index + 1;
            final stageName = _stageNames[index];
            final stageDesc = _stageDescriptions[index];

            // Match with DB stage
            final dbStage = stages.firstWhere(
              (s) => (s['stage_order'] as int) == stageOrder,
              orElse: () => null,
            );

            final statusStr = (dbStage?['status'] as String?)?.toUpperCase() ??
                (stageOrder < currentStage ? 'COMPLETED' : (stageOrder == currentStage ? 'IN_PROGRESS' : 'NOT_STARTED'));

            final isCompleted = statusStr == 'COMPLETED';
            final isInProgress = statusStr == 'IN_PROGRESS';
            final isLocked = statusStr == 'NOT_STARTED';

            final studentNotes = dbStage?['student_notes'] as String?;
            final completedDate = dbStage?['completed_date'] as String?;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline Node & Line
                  Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? AppColors.success
                              : (isInProgress ? AppColors.primary : AppColors.slate200),
                          shape: BoxShape.circle,
                          boxShadow: isInProgress
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Icon(
                            isCompleted
                                ? Icons.check_rounded
                                : (isInProgress ? Icons.hourglass_top_rounded : Icons.lock_outline_rounded),
                            size: 16,
                            color: isLocked ? AppColors.slate400 : AppColors.white,
                          ),
                        ),
                      ),
                      if (stageOrder < 8)
                        Container(
                          width: 2,
                          height: 48,
                          color: isCompleted ? AppColors.success : AppColors.slate200,
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),

                  // Stage Content Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isInProgress
                            ? AppColors.primaryLight.withValues(alpha: 0.25)
                            : (isCompleted ? AppColors.white : AppColors.slate50),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isInProgress
                              ? AppColors.primary
                              : (isCompleted ? AppColors.border : AppColors.slate200),
                          width: isInProgress ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Tahap $stageOrder • $stageName',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isLocked ? AppColors.slate500 : AppColors.slate900,
                                ),
                              ),
                              StatusBadge.fromStatus(statusStr),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            stageDesc,
                            style: const TextStyle(fontSize: 11, color: AppColors.slate500),
                          ),
                          if (completedDate != null && completedDate.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.event_available_rounded, size: 12, color: AppColors.success),
                                const SizedBox(width: 4),
                                Text(
                                  'Selesai pada: $completedDate',
                                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.success),
                                ),
                              ],
                            ),
                          ],
                          if (studentNotes != null && studentNotes.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.sticky_note_2_outlined, size: 13, color: AppColors.slate500),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      studentNotes,
                                      style: const TextStyle(fontSize: 11, color: AppColors.slate700, fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // WIDGET: TAB TOPIK SKRIPSI
  Widget _buildTopicDetailTab() {
    final topic = _currentThesis['topic'] as Map<String, dynamic>?;
    final title = _currentThesis['title'] as String? ?? '-';
    final background = topic?['background'] as String? ?? '-';
    final problem = topic?['problem_formulation'] as String? ?? '-';
    final objective = topic?['research_objective'] as String? ?? '-';
    final methodology = topic?['methodology'] as String? ?? '-';
    final fieldOfStudy = topic?['field_of_study'] as String? ?? 'Sains Data & Kecerdasan Buatan';
    final feedback = topic?['lecturer_feedback'] as String?;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Topic Title Card
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      fieldOfStudy,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ),
                  StatusBadge.fromStatus('APPROVED'),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.slate900, height: 1.3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Catatan Dosen Pembimbing (Jika ada)
        if (feedback != null && feedback.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.comment_outlined, size: 16, color: Color(0xFF166534)),
                    SizedBox(width: 6),
                    Text(
                      'Catatan / Feedback Persetujuan Pembimbing',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF166534)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  feedback,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF14532D)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Latar Belakang
        _buildSectionCard('Latar Belakang Masalah', background, Icons.history_edu_rounded),
        const SizedBox(height: 12),

        // Rumusan Masalah
        _buildSectionCard('Rumusan Masalah', problem, Icons.help_outline_rounded),
        const SizedBox(height: 12),

        // Tujuan Penelitian
        _buildSectionCard('Tujuan Penelitian', objective, Icons.flag_outlined),
        const SizedBox(height: 12),

        // Metodologi Penelitian
        _buildSectionCard('Metodologi Penelitian', methodology, Icons.biotech_rounded),
      ],
    );
  }

  Widget _buildSectionCard(String title, String content, IconData icon) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.slate900),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 12, color: AppColors.slate700, height: 1.45),
          ),
        ],
      ),
    );
  }
}
