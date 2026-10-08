import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/models/consultation_model.dart';
import '../../../../core/models/thesis_progress_model.dart';
import '../../../../core/models/topic_model.dart';
import '../../../../core/models/topic_change_request_model.dart';
import '../../../../core/utils/app_date_format.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class StudentDashboardScreen extends ConsumerStatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  ConsumerState<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends ConsumerState<StudentDashboardScreen> {
  TopicSubmission? _latestTopic;
  Thesis? _studentThesis;
  TopicChangeRequest? _activeChangeRequest;
  List<Consultation> _consultations = [];
  bool _hasApprovedTopic = false;
  double _overallProgress = 0.0;
  int _currentStageOrder = 1;
  bool _isLoadingTopic = true;

  @override
  void initState() {
    super.initState();
    _loadLatestTopic();
  }

  Future<void> _loadLatestTopic() async {
    final auth = ref.read(authControllerProvider);
    final user = auth.userProfile;
    final service = ref.read(supabaseServiceProvider);

    try {
      final topics = await service.fetchTopics(studentId: user?.id);
      Thesis? thesis;
      TopicChangeRequest? changeRequest;
      List<Consultation> consults = [];
      if (user?.id != null) {
        thesis = await service.fetchStudentThesis(user!.id);
        changeRequest = await service.fetchActiveTopicChangeRequest(user.id);
        consults = await service.fetchConsultations(studentId: user.id);
      }

      final hasApproved = topics.any((t) => t.status == TopicStatus.approved) || (thesis != null);

      if (mounted) {
        setState(() {
          _studentThesis = thesis;
          _activeChangeRequest = changeRequest;
          _hasApprovedTopic = hasApproved;
          _latestTopic = topics.isNotEmpty ? topics.first : null;
          _consultations = consults;
          _isLoadingTopic = false;
          _syncStageWithThesisAndTopic();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingTopic = false;
        });
      }
    }
  }

  void _syncStageWithThesisAndTopic() {
    if (_studentThesis != null) {
      _overallProgress = _studentThesis!.overallProgressPercentage;
      _currentStageOrder = _studentThesis!.currentStageOrder;
      for (final st in _studentThesis!.stages) {
        if (st.stageOrder >= 1 && st.stageOrder <= _stages.length) {
          final idx = st.stageOrder - 1;
          switch (st.status) {
            case StageStatus.completed:
              _stages[idx]['status'] = 'COMPLETED';
              _stages[idx]['desc'] = st.studentNotes ?? 'Tahap ini telah disetujui Dosen Pembimbing.';
              break;
            case StageStatus.inProgress:
              _stages[idx]['status'] = 'IN_PROGRESS';
              _stages[idx]['desc'] = st.studentNotes ?? 'Sedang pengerjaan. Menunggu persetujuan dosen untuk lanjut.';
              break;
            case StageStatus.notStarted:
              _stages[idx]['status'] = 'NOT_STARTED';
              _stages[idx]['desc'] = 'Tahap terkunci hingga tahap sebelumnya disetujui dosen.';
              break;
          }
        }
      }
      _selectedStageIndex = (_currentStageOrder - 1).clamp(0, _stages.length - 1);
    } else if (_latestTopic != null) {
      switch (_latestTopic!.status) {
        case TopicStatus.approved:
          _overallProgress = 12.5;
          _currentStageOrder = 2;
          _stages[0]['status'] = 'COMPLETED';
          _stages[0]['desc'] = 'Topik disetujui Dosen Pembimbing.';
          _stages[1]['status'] = 'IN_PROGRESS';
          _stages[1]['desc'] = 'Penyusunan proposal skripsi. Memerlukan persetujuan dosen untuk lanjut ke Sempro.';
          for (int i = 2; i < _stages.length; i++) {
            _stages[i]['status'] = 'NOT_STARTED';
            _stages[i]['desc'] = 'Terkunci hingga tahap sebelumnya disetujui.';
          }
          _selectedStageIndex = 1;
          break;
        case TopicStatus.submitted:
        case TopicStatus.underReview:
        case TopicStatus.revision:
          _overallProgress = 0.0;
          _currentStageOrder = 1;
          _stages[0]['status'] = 'IN_PROGRESS';
          _stages[0]['desc'] = 'Pengajuan topik sedang dalam proses review dosen.';
          for (int i = 1; i < _stages.length; i++) {
            _stages[i]['status'] = 'NOT_STARTED';
            _stages[i]['desc'] = 'Terkunci hingga usulan topik disetujui.';
          }
          _selectedStageIndex = 0;
          break;
        case TopicStatus.draft:
        case TopicStatus.rejected:
        case TopicStatus.cancelled:
          _overallProgress = 0.0;
          _currentStageOrder = 1;
          _stages[0]['status'] = 'NOT_STARTED';
          _stages[0]['desc'] = _latestTopic!.status == TopicStatus.draft
              ? 'Draf topik tersimpan, silakan kirim pengajuan.'
              : (_latestTopic!.status == TopicStatus.cancelled
                  ? 'Topik sebelumnya dibatalkan / diganti. Silakan ajukan topik baru.'
                  : 'Topik ditolak, silakan ajukan topik baru.');
          for (int i = 1; i < _stages.length; i++) {
            _stages[i]['status'] = 'NOT_STARTED';
            _stages[i]['desc'] = 'Terkunci hingga usulan topik disetujui.';
          }
          _selectedStageIndex = 0;
          break;
      }
    } else {
      _overallProgress = 0.0;
      _currentStageOrder = 1;
      for (int i = 0; i < _stages.length; i++) {
        _stages[i]['status'] = 'NOT_STARTED';
        _stages[i]['desc'] = i == 0 ? 'Belum ada pengajuan usulan topik.' : 'Terkunci hingga topik disetujui.';
      }
      _selectedStageIndex = 0;
    }
  }

  // Interactive To-Do items state (stored in session)
  final List<Map<String, dynamic>> _todoItems = [];

  // Daily tips
  final List<String> _tips = [
    '💡 Catat poin revisi secara spesifik dalam 24 jam setelah bimbingan agar konteks tetap segar.',
    '🎯 Simpan backup naskah skripsi secara berkala di cloud dan local storage.',
    '⚡ Buat daftar pertanyaan spesifik sebelum sesi bimbingan agar konsultasi lebih terarah dan efisien.',
    '📚 Pastikan referensi jurnal utama berumur kurang dari 5 tahun terakhir untuk memperkuat bab 2.',
  ];
  int _currentTipIndex = 0;

  // Selected stage preview in hero card
  int _selectedStageIndex = 0; // 0-indexed (Tahap 1)

  final List<Map<String, dynamic>> _stages = [
    {'order': 1, 'name': 'Pengajuan Topik', 'status': 'NOT_STARTED', 'desc': 'Belum ada pengajuan usulan topik.'},
    {'order': 2, 'name': 'Proposal Skripsi', 'status': 'NOT_STARTED', 'desc': 'Terkunci hingga usulan topik disetujui.'},
    {'order': 3, 'name': 'Seminar Proposal', 'status': 'NOT_STARTED', 'desc': 'Terkunci hingga proposal disetujui.'},
    {'order': 4, 'name': 'Pengumpulan Data', 'status': 'NOT_STARTED', 'desc': 'Terkunci hingga seminar proposal lulus.'},
    {'order': 5, 'name': 'Analisis Data', 'status': 'NOT_STARTED', 'desc': 'Terkunci hingga pengumpulan data selesai.'},
    {'order': 6, 'name': 'Penyusunan Naskah', 'status': 'NOT_STARTED', 'desc': 'Terkunci hingga analisis data selesai.'},
    {'order': 7, 'name': 'Seminar Hasil', 'status': 'NOT_STARTED', 'desc': 'Terkunci hingga naskah skripsi disetujui.'},
    {'order': 8, 'name': 'Sidang Akhir', 'status': 'NOT_STARTED', 'desc': 'Terkunci hingga seminar hasil selesai.'},
  ];

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi ☀️';
    if (hour < 15) return 'Selamat Siang 🌤️';
    if (hour < 18) return 'Selamat Sore 🌇';
    return 'Selamat Malam 🌙';
  }

  void _showRequestTopicChangeModal() {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    final currentTitle = _latestTopic?.title ?? _studentThesis?.title ?? 'Topik Skripsi Saat Ini';
    final lecturerName = _latestTopic?.lecturerName ?? 'Dosen Pembimbing';

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
                              'Ajukan permohonan ke dosen untuk ganti judul',
                              style: TextStyle(fontSize: 11, color: AppColors.slate500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Current Topic Info Card
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
                          currentTitle,
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
                      hintText: 'Jelaskan secara rinci alasan dan kendala mengapa Anda ingin mengganti topik skripsi ini (misal: keterbatasan data, perubahan metodologi, dll)...',
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
                          'Setelah disetujui dosen, fitur pengajuan topik baru akan aktif kembali.',
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

                                    final lecturerId = _latestTopic?.lecturerId ??
                                        _studentThesis?.lecturerId ??
                                        '';

                                    await service.submitTopicChangeRequest(
                                      studentId: user?.id ?? '',
                                      lecturerId: lecturerId,
                                      reason: reasonController.text.trim(),
                                      thesisId: _studentThesis?.id,
                                      currentTopicId: _latestTopic?.id,
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
                                      _loadLatestTopic();
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

  void _showAddTodoDialog() {
    final textController = TextEditingController();
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
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
              const Row(
                children: [
                  Icon(Icons.add_task_rounded, color: AppColors.primary, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Tambah Catatan / Target Skripsi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.slate900),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Judul Tugas / Rencana',
                  hintText: 'Misal: Revisi analisis Bab 4.2',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  labelText: 'Catatan Tambahan (Opsional)',
                  hintText: 'Misal: Konfirmasi ke Pak Budi hari Senin',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
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
                    onPressed: () {
                      if (textController.text.trim().isNotEmpty) {
                        setState(() {
                          _todoItems.insert(0, {
                            'id': DateTime.now().millisecondsSinceEpoch.toString(),
                            'title': textController.text.trim(),
                            'subtitle': noteController.text.trim().isNotEmpty
                                ? noteController.text.trim()
                                : 'Target pribadi mahasiswa',
                            'isCompleted': false,
                            'priority': 'Tinggi',
                          });
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.check_circle_rounded, color: AppColors.white, size: 18),
                                SizedBox(width: 8),
                                Text('Target baru berhasil ditambahkan! 🚀'),
                              ],
                            ),
                            backgroundColor: AppColors.primary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Simpan Target'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStageDetailModal(Map<String, dynamic> stage) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
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
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '#${stage['order']}',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stage['name'],
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.slate900),
                      ),
                      Text(
                        'Tahapan ${stage['order']} dari 8 Skripsi',
                        style: const TextStyle(fontSize: 12, color: AppColors.slate500),
                      ),
                    ],
                  ),
                ),
                StatusBadge.fromStatus(stage['status']),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.slate50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      stage['desc'] ?? '-',
                      style: const TextStyle(fontSize: 13, color: AppColors.slate700, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user_outlined, size: 16, color: AppColors.primary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Persetujuan Dosen: Roadmap hanya dapat dilanjutkan setelah diverifikasi & disetujui oleh Dosen Pembimbing Anda.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF1E40AF), height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/student/progress');
                },
                icon: const Icon(Icons.timeline_rounded, size: 18),
                label: const Text('Buka Monitoring Roadmap Lengkap', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.lightImpact();
    await Future.wait([
      _loadLatestTopic(),
      Future.delayed(const Duration(milliseconds: 700)),
    ]);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.sync_rounded, color: AppColors.white, size: 18),
              SizedBox(width: 8),
              Text('Data dashboard berhasil diperbarui! ✨'),
            ],
          ),
          backgroundColor: AppColors.slate800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).userProfile;
    final completedCount = _todoItems.where((i) => i['isCompleted'] == true).length;
    final totalCount = _todoItems.length;

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        titleSpacing: 16,
        elevation: 0,
        backgroundColor: AppColors.white,
        title: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    (user?.fullName.isNotEmpty ?? false) ? user!.fullName[0].toUpperCase() : 'M',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -1,
                  right: -1,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(),
                    style: const TextStyle(fontSize: 12, color: AppColors.slate500, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    user?.fullName ?? "Mahasiswa Skripsi",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Notification bell with interactive badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: 'Pusat Notifikasi',
                icon: const Icon(Icons.notifications_outlined, color: AppColors.slate700),
                onPressed: () => context.push('/student/notifications'),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: const Center(
                    child: Text(
                      '2',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            tooltip: 'Profil Saya',
            icon: const Icon(Icons.person_outline_rounded, color: AppColors.slate700),
            onPressed: () => context.push('/student/profile'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HERO PROGRESS CARD (Gradient, Interactive Milestone Selector)
              _buildHeroProgressCard()
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.08, end: 0, duration: 400.ms, curve: Curves.easeOutQuad),

              const SizedBox(height: 16),

              // 2. KEY STATS PILLS ROW
              _buildStatsRow()
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 400.ms)
                  .slideY(begin: 0.08, end: 0, duration: 400.ms),

              const SizedBox(height: 20),

              // 3. QUICK ACTIONS GRID
              _buildSectionHeader(
                title: 'Akses Cepat',
              ),
              const SizedBox(height: 12),
              _buildQuickActionsGrid()
                  .animate()
                  .fadeIn(delay: 150.ms, duration: 400.ms),

              const SizedBox(height: 20),

              // 4. UPCOMING CONSULTATION CARD (With Direct Actions)
              _buildSectionHeader(
                title: 'Bimbingan Terdekat',
                actionText: 'Lihat Semua',
                onActionTap: () => context.push('/student/consultation'),
              ),
              const SizedBox(height: 10),
              _buildUpcomingConsultationCard()
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 400.ms)
                  .slideY(begin: 0.05, end: 0),

              const SizedBox(height: 20),

              // 5. INTERACTIVE THESIS TO-DO & ACTION ITEMS
              _buildSectionHeader(
                title: 'Target & Catatan Skripsi',
                subtitle: '$completedCount dari $totalCount selesai',
                actionText: '+ Tambah',
                onActionTap: _showAddTodoDialog,
              ),
              const SizedBox(height: 10),
              _buildInteractiveTodoList()
                  .animate()
                  .fadeIn(delay: 250.ms, duration: 400.ms),

              const SizedBox(height: 20),

              // 6. TOPIK SKRIPSI CARD
              _buildSectionHeader(
                title: _hasApprovedTopic
                    ? 'Topik Skripsi Aktif (Disetujui)'
                    : (_latestTopic == null ? 'Pengajuan Topik Skripsi' : 'Topik Skripsi'),
                actionText: _hasApprovedTopic ? 'Semua Topik' : (_latestTopic == null ? '+ Ajukan Baru' : 'Semua Topik'),
                onActionTap: () async {
                  if (_hasApprovedTopic) {
                    await context.push('/student/topic');
                  } else if (_latestTopic == null) {
                    await context.push('/student/topic/new');
                  } else {
                    await context.push('/student/topic');
                  }
                  _loadLatestTopic();
                },
              ),
              const SizedBox(height: 10),
              _buildThesisTopicCard()
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 400.ms),

              const SizedBox(height: 20),

              // 7. SMART TIPS CAROUSEL / ROTATOR
              _buildSmartTipCard()
                  .animate()
                  .fadeIn(delay: 350.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== WIDGET BUILDERS =====================

  Widget _buildSectionHeader({
    required String title,
    String? subtitle,
    String? actionText,
    VoidCallback? onActionTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.slate900,
                letterSpacing: -0.2,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.slate200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.slate700),
                ),
              ),
            ],
          ],
        ),
        if (actionText != null && onActionTap != null)
          InkWell(
            onTap: onActionTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                actionText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // 1. HERO PROGRESS CARD
  Widget _buildHeroProgressCard() {
    final activeStage = _stages[_selectedStageIndex];

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4338CA), Color(0xFF6366F1), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(79, 70, 229, 0.28),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background ambient circles
          Positioned(
            right: -25,
            top: -25,
            child: Container(
              width: 140,
              height: 140,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color.fromRGBO(255, 255, 255, 0.08),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color.fromRGBO(255, 255, 255, 0.05),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(255, 255, 255, 0.18),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.rocket_launch_rounded, color: AppColors.white, size: 16),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Roadmap Skripsi Anda',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(255, 255, 255, 0.22),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt_rounded, color: Color(0xFFFDE047), size: 14),
                          const SizedBox(width: 2),
                          Text(
                            '${_overallProgress.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Linear progress bar with glow
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 10,
                    color: const Color.fromRGBO(255, 255, 255, 0.2),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (_overallProgress / 100.0).clamp(0.01, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF38BDF8), Color(0xFFFACC15)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Interactive 8-stages dots selector
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tahapan Pengerjaan (Tap untuk info):',
                          style: TextStyle(color: Color.fromRGBO(255, 255, 255, 0.8), fontSize: 11),
                        ),
                        Text(
                          _overallProgress >= 100.0 ? 'Selesai (8 dari 8)' : 'Tahap $_currentStageOrder dari 8',
                          style: const TextStyle(color: AppColors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(_stages.length, (idx) {
                        final st = _stages[idx];
                        final isDone = st['status'] == 'COMPLETED';
                        final isInProgress = st['status'] == 'IN_PROGRESS';
                        final isSelected = _selectedStageIndex == idx;

                        Color dotColor;
                        if (isDone) {
                          dotColor = const Color(0xFF34D399); // Emerald
                        } else if (isInProgress) {
                          dotColor = const Color(0xFFFBBF24); // Amber
                        } else {
                          dotColor = const Color.fromRGBO(255, 255, 255, 0.3);
                        }

                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedStageIndex = idx);
                            _showStageDetailModal(st);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: isSelected ? 30 : 26,
                            height: isSelected ? 30 : 26,
                            decoration: BoxDecoration(
                              color: isSelected ? dotColor : dotColor.withValues(alpha: 0.8),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? AppColors.white : Colors.transparent,
                                width: isSelected ? 2.5 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: dotColor.withValues(alpha: 0.6),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: isDone
                                  ? const Icon(Icons.check, size: 14, color: Color(0xFF064E3B))
                                  : Text(
                                      '${idx + 1}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: isInProgress ? const Color(0xFF78350F) : AppColors.white,
                                      ),
                                    ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Selected stage chip & Target defense
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(0, 0, 0, 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.flag_rounded, size: 16, color: Color(0xFFFDE047)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Aktif: ${activeStage['name']} (#${activeStage['order']})',
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () => context.push('/student/progress'),
                        borderRadius: BorderRadius.circular(6),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          child: Row(
                            children: [
                              Text(
                                'Roadmap',
                                style: TextStyle(
                                  color: Color(0xFF93C5FD),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF93C5FD), size: 10),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. STATS PILLS ROW
  Widget _buildStatsRow() {
    final consultationCount = _consultations.length;
    final revisionCount = _latestTopic?.revisionCount ?? 0;
    final stageText = _studentThesis != null
        ? 'Tahap $_currentStageOrder/8'
        : (_hasApprovedTopic
            ? 'Tahap 2/8'
            : (_latestTopic != null ? 'Tahap 1/8' : 'Tahap 0/8'));

    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            label: 'Konsultasi',
            value: '$consultationCount Sesi',
            icon: Icons.event_available_rounded,
            color: AppColors.primary,
            onTap: () => context.push('/student/consultation'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricTile(
            label: 'Revisi Selesai',
            value: '$revisionCount Catatan',
            icon: Icons.task_alt_rounded,
            color: AppColors.success,
            onTap: () => context.push('/student/consultation'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricTile(
            label: 'Progres Skripsi',
            value: stageText,
            icon: Icons.flag_outlined,
            color: AppColors.accent,
            onTap: () => context.push('/student/progress'),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.slate400),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.slate900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.slate500, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // 3. QUICK ACTIONS ROW (Compact 4-Column Dock)
  Widget _buildQuickActionsGrid() {
    final actions = [
      {
        'title': 'Pengajuan Topik',
        'shortTitle': 'Topik',
        'icon': Icons.description_outlined,
        'color': const Color(0xFF4F46E5),
        'bg': const Color(0xFFEEF2FF),
        'route': (_hasApprovedTopic || _latestTopic != null) ? '/student/topic' : '/student/topic/new',
      },
      {
        'title': 'Jadwal Bimbingan',
        'shortTitle': 'Jadwal',
        'icon': Icons.calendar_month_rounded,
        'color': const Color(0xFF0284C7),
        'bg': const Color(0xFFF0F9FF),
        'route': '/student/consultation',
      },
      {
        'title': 'Booking Konsul',
        'shortTitle': 'Booking',
        'icon': Icons.add_circle_outline_rounded,
        'color': const Color(0xFF7C3AED),
        'bg': const Color(0xFFF5F3FF),
        'route': '/student/consultation/book',
      },
      {
        'title': 'Roadmap Progres',
        'shortTitle': 'Roadmap',
        'icon': Icons.timeline_rounded,
        'color': const Color(0xFFD97706),
        'bg': const Color(0xFFFFFBEB),
        'route': '/student/progress',
      },
    ];

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: actions.map((a) {
          return Expanded(
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                context.push(a['route'] as String);
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: a['bg'] as Color,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: (a['color'] as Color).withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(a['icon'] as IconData, color: a['color'] as Color, size: 22),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      a['shortTitle'] as String,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate800,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // 4. UPCOMING CONSULTATION CARD
  Widget _buildUpcomingConsultationCard() {
    final upcomingList = _consultations.where((c) =>
        c.status == ConsultationStatus.confirmed ||
        c.status == ConsultationStatus.requested).toList();

    if (upcomingList.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.slate100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.event_busy_rounded, color: AppColors.slate400, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Belum Ada Jadwal Bimbingan',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.slate800),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Jadwalkan sesi bimbingan dengan dosen pembimbing Anda.',
                        style: TextStyle(fontSize: 11, color: AppColors.slate500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: () => context.push('/student/consultation/book'),
                icon: const Icon(Icons.calendar_month_rounded, size: 16),
                label: const Text('Jadwalkan Bimbingan Baru', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      );
    }

    final upcoming = upcomingList.first;
    final dateStr = AppDateFormat.formatFull(upcoming.scheduledStart);
    final timeStr = '${AppDateFormat.formatTime(upcoming.scheduledStart)} - ${AppDateFormat.formatTime(upcoming.scheduledEnd)} WIB';
    final lecturerName = upcoming.lecturerName?.isNotEmpty == true ? upcoming.lecturerName! : 'Dosen Pembimbing';

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lecturerName,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.slate900),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Dosen Pembimbing Utama',
                      style: TextStyle(fontSize: 11, color: AppColors.slate500),
                    ),
                  ],
                ),
              ),
              StatusBadge.fromStatus(upcoming.status.name),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.slate50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        dateStr,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.slate800),
                      ),
                    ),
                    const Icon(Icons.access_time_rounded, size: 14, color: AppColors.slate400),
                    const SizedBox(width: 6),
                    Text(
                      timeStr,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.slate800),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.article_outlined, size: 14, color: AppColors.slate500),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Agenda: ${upcoming.agenda.isNotEmpty ? upcoming.agenda : 'Konsultasi Bimbingan'}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.slate700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Interactive Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.slate700,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () => context.push('/student/consultation'),
                  icon: const Icon(Icons.calendar_today_rounded, size: 15),
                  label: const Text('Detail Jadwal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () => context.push('/student/consultation'),
                  icon: const Icon(Icons.notes_rounded, size: 15),
                  label: const Text('Lihat Riwayat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 5. INTERACTIVE THESIS TO-DO & ACTION ITEMS
  Widget _buildInteractiveTodoList() {
    if (_todoItems.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.slate100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.checklist_rtl_rounded, size: 28, color: AppColors.slate400),
            ),
            const SizedBox(height: 10),
            const Text(
              'Belum Ada Target Catatan Skripsi',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.slate800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Buat target mandiri seperti rencana revisi bab atau pengumpulan data.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.slate500),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _showAddTodoDialog,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text(
                      'Tambah Rencana / Target Baru',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          ..._todoItems.map((item) {
            final isDone = item['isCompleted'] as bool;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: isDone ? AppColors.slate50 : AppColors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDone ? AppColors.slate200 : AppColors.border,
                ),
              ),
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                leading: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      item['isCompleted'] = !isDone;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isDone ? AppColors.success : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDone ? AppColors.success : AppColors.slate400,
                        width: 2,
                      ),
                    ),
                    child: isDone
                        ? const Icon(Icons.check, size: 16, color: AppColors.white)
                        : null,
                  ),
                ),
                title: Text(
                  item['title'],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDone ? AppColors.slate400 : AppColors.slate900,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: Text(
                  item['subtitle'],
                  style: TextStyle(
                    fontSize: 11,
                    color: isDone ? AppColors.slate400 : AppColors.slate500,
                  ),
                ),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18, color: AppColors.slate400),
                  onSelected: (val) {
                    if (val == 'delete') {
                      setState(() {
                        _todoItems.removeWhere((i) => i['id'] == item['id']);
                      });
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                          SizedBox(width: 8),
                          Text('Hapus Target', style: TextStyle(fontSize: 12, color: AppColors.danger)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
          InkWell(
            onTap: _showAddTodoDialog,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text(
                    'Tambah Rencana / Target Baru',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 6. THESIS TOPIC CARD
  Widget _buildThesisTopicCard() {
    if (_isLoadingTopic) {
      return const AppCard(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
            SizedBox(width: 12),
            Text('Memeriksa status pengajuan topik skripsi...', style: TextStyle(fontSize: 12, color: AppColors.slate500)),
          ],
        ),
      );
    }

    if (_latestTopic == null) {
      return AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.post_add_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Belum Ada Pengajuan Topik',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.slate900),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Mulai ajukan usulan judul dan topik skripsi Anda untuk ditinjau oleh calon dosen pembimbing.',
                        style: TextStyle(fontSize: 11, color: AppColors.slate500, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () async {
                      await context.push('/student/topic/new');
                      _loadLatestTopic();
                    },
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Ajukan Topik Sekarang', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.slate700,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  ),
                  onPressed: () async {
                    await context.push('/student/topic');
                    _loadLatestTopic();
                  },
                  child: const Text('Daftar Topik', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final topic = _latestTopic!;
    return AppCard(
      onTap: () async {
        await context.push('/student/topic/detail/${topic.id}');
        _loadLatestTopic();
      },
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_stories_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.lecturerName != null ? 'Pembimbing: ${topic.lecturerName}' : 'Calon Pembimbing Ditentukan',
                      style: const TextStyle(fontSize: 11, color: AppColors.slate500, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      topic.title,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.slate900, height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge.fromStatus(topic.status.name.toUpperCase()),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Status: ${topic.status.label}',
                style: const TextStyle(fontSize: 11, color: AppColors.slate500, fontWeight: FontWeight.w500),
              ),
              const Row(
                children: [
                  Text(
                    'Detail Pengajuan',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.primary),
                ],
              ),
            ],
          ),
          if (topic.status == TopicStatus.draft || topic.status == TopicStatus.revision) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: topic.status == TopicStatus.revision ? AppColors.warning : AppColors.primary,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: () async {
                  await context.push('/student/topic/edit/${topic.id}', extra: topic);
                  _loadLatestTopic();
                },
                icon: const Icon(Icons.edit_note_rounded, size: 16),
                label: Text(
                  topic.status == TopicStatus.revision ? 'Revisi & Ajukan Ulang Topik' : 'Lanjutkan & Ajukan Draf',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ] else if (topic.status == TopicStatus.approved) ...[
            const SizedBox(height: 12),
            if (_activeChangeRequest != null && _activeChangeRequest!.isPending) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warningLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.hourglass_top_rounded, size: 16, color: AppColors.warning),
                        SizedBox(width: 6),
                        Text(
                          'Permohonan Ganti Topik Sedang Ditinjau',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.warning),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Alasan: "${_activeChangeRequest!.reason}"',
                      style: const TextStyle(fontSize: 11, color: AppColors.slate700, fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Pengajuan judul baru dinonaktifkan sementara hingga permohonan disetujui dosen pembimbing.',
                      style: TextStyle(fontSize: 10.5, color: AppColors.slate500),
                    ),
                  ],
                ),
              ),
            ] else if (_activeChangeRequest != null && _activeChangeRequest!.isRejected) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.dangerLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.cancel_outlined, size: 16, color: AppColors.danger),
                        SizedBox(width: 6),
                        Text(
                          'Permohonan Ganti Topik Ditolak Dosen',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.danger),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Catatan dosen: "${_activeChangeRequest!.lecturerResponse ?? '-'}"',
                      style: const TextStyle(fontSize: 11, color: AppColors.slate700),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.warning,
                          side: const BorderSide(color: AppColors.warning),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onPressed: _showRequestTopicChangeModal,
                        icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                        label: const Text('Ajukan Pergantian Topik Lagi', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
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
                    const Row(
                      children: [
                        Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.slate500),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Pengajuan topik baru dinonaktifkan karena judul telah disetujui.',
                            style: TextStyle(fontSize: 11, color: AppColors.slate600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onPressed: _showRequestTopicChangeModal,
                        icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                        label: const Text('Ajukan Pergantian Topik ke Dosen', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // 7. SMART TIPS ROTATOR
  Widget _buildSmartTipCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFFFEF3C7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lightbulb_rounded, color: Color(0xFFD97706), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tips Bimbingan Sukses',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                    ),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _currentTipIndex = (_currentTipIndex + 1) % _tips.length;
                        });
                      },
                      child: const Row(
                        children: [
                          Text(
                            'Ganti Tip',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFD97706)),
                          ),
                          SizedBox(width: 2),
                          Icon(Icons.refresh_rounded, size: 12, color: Color(0xFFD97706)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _tips[_currentTipIndex],
                    key: ValueKey<int>(_currentTipIndex),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF78350F), height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
