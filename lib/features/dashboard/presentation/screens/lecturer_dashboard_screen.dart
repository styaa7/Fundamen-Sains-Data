import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/models/consultation_model.dart';
import '../../../../core/models/topic_model.dart';
import '../../../../core/models/topic_change_request_model.dart';
import '../../../../core/utils/app_date_format.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class LecturerDashboardScreen extends ConsumerStatefulWidget {
  const LecturerDashboardScreen({super.key});

  @override
  ConsumerState<LecturerDashboardScreen> createState() => _LecturerDashboardScreenState();
}

class _LecturerDashboardScreenState extends ConsumerState<LecturerDashboardScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _theses = [];
  List<Consultation> _consultations = [];
  List<TopicChangeRequest> _changeRequests = [];
  int _pendingTopicsCount = 0;

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

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final user = ref.read(authControllerProvider).userProfile;
      final service = ref.read(supabaseServiceProvider);

      final thesesList = await service.fetchLecturerTheses(user?.id ?? '');
      final consultList = await service.fetchConsultations(lecturerId: user?.id);
      final topicsList = await service.fetchTopics(lecturerId: user?.id);
      final changeReqList = await service.fetchLecturerTopicChangeRequests(user?.id ?? '');

      final pendingTopics = topicsList.where((t) => t.status == TopicStatus.submitted || t.status == TopicStatus.underReview).length;

      if (mounted) {
        setState(() {
          _theses = thesesList;
          _consultations = consultList;
          _changeRequests = changeReqList;
          _pendingTopicsCount = pendingTopics;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showApproveTopicChangeDialog(TopicChangeRequest req) async {
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
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Setujui Pergantian Topik',
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
                  'Konfirmasi persetujuan pergantian topik untuk mahasiswa:',
                  style: TextStyle(fontSize: 12, color: AppColors.slate600),
                ),
                const SizedBox(height: 8),
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
                        req.studentName ?? 'Mahasiswa',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.slate900),
                      ),
                      Text(
                        'NIM: ${req.studentNim ?? "-"}',
                        style: const TextStyle(fontSize: 11, color: AppColors.slate500),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Topik Lama: ${req.currentTopicTitle ?? "-"}',
                        style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.slate700),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.warningLight.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Alasan Ganti Topik:', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.warning)),
                            const SizedBox(height: 2),
                            Text(
                              req.reason,
                              style: const TextStyle(fontSize: 11.5, color: AppColors.slate800),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '⚠️ Catatan Penting:',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.warning),
                ),
                const Text(
                  'Dengan menyetujui permohonan ini, topik lama dan data skripsi saat ini akan di-reset, dan mahasiswa akan dapat mengajukan usulan topik baru kembali.',
                  style: TextStyle(fontSize: 11, color: AppColors.slate600),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Catatan / Arahan Dosen (Opsional)',
                    hintText: 'Misal: Silakan ajukan topik baru terkait NLP',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                backgroundColor: AppColors.success,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      setDialogState(() => isSubmitting = true);
                      try {
                        final service = ref.read(supabaseServiceProvider);
                        await service.approveTopicChangeRequest(
                          req,
                          notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
                        );
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.success,
                              content: Text('Pergantian topik disetujui! Mahasiswa ${req.studentName} kini dapat mengajukan topik baru.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          _loadDashboardData();
                        }
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.danger,
                              content: Text('Gagal menyetujui: $e'),
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
                  : const Text('Ya, Setujui Ganti Topik'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRejectTopicChangeDialog(TopicChangeRequest req) async {
    final reasonController = TextEditingController();
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
                  color: AppColors.dangerLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.cancel_outlined, color: AppColors.danger, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Tolak Pergantian Topik',
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
                Text(
                  'Tolak permohonan ganti topik dari ${req.studentName ?? "Mahasiswa"}:',
                  style: const TextStyle(fontSize: 12, color: AppColors.slate600),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Alasan Penolakan *',
                    hintText: 'Jelaskan mengapa mahasiswa harus melanjutkan topik saat ini...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                backgroundColor: AppColors.danger,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (reasonController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Alasan penolakan wajib diisi'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isSubmitting = true);
                      try {
                        final service = ref.read(supabaseServiceProvider);
                        await service.rejectTopicChangeRequest(
                          req,
                          reason: reasonController.text.trim(),
                        );
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: AppColors.slate800,
                              content: Text('Permohonan pergantian topik telah ditolak.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          _loadDashboardData();
                        }
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.danger,
                              content: Text('Gagal menolak: $e'),
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
                  : const Text('Tolak Permohonan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showApproveStageDialog(Map<String, dynamic> thesis) async {
    final currentStage = thesis['current_stage_order'] as int? ?? 1;
    final isFinalStage = currentStage >= 8;
    final currentStageName = _stageNames.length >= currentStage ? _stageNames[currentStage - 1] : 'Tahap $currentStage';
    final nextStageName = !isFinalStage && _stageNames.length >= currentStage + 1
        ? _stageNames[currentStage]
        : 'Selesai / Lulus';

    final studentName = thesis['student_profile']?['full_name'] ?? 'Mahasiswa';
    final studentNim = thesis['student_profile']?['identifier_number'] ?? '-';
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
                        thesis['title'] ?? 'Skripsi',
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
                              'Tahap yang Disetujui: Tahap $currentStage ($currentStageName)',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF166534)),
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
                              isFinalStage
                                  ? 'Tahap Selanjutnya: Skripsi Lengkap / Lulus'
                                  : 'Tahap Selanjutnya: Tahap ${currentStage + 1} ($nextStageName)',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Catatan / Feedback Pembimbing (Opsional):',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.slate800),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Contoh: Naskah bab 2 dan metodologi telah diperiksa dan siap melangkah ke sempro.',
                    hintStyle: const TextStyle(fontSize: 11, color: AppColors.slate400),
                    contentPadding: const EdgeInsets.all(10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
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
                      final messenger = ScaffoldMessenger.of(context);
                      final nav = Navigator.of(ctx);
                      setDialogState(() => isSubmitting = true);
                      try {
                        final service = ref.read(supabaseServiceProvider);
                        await service.approveAndAdvanceThesisStage(
                          thesisId: thesis['id'],
                          studentId: thesis['student_id'],
                          currentStageOrder: currentStage,
                          lecturerNotes: notesController.text.trim(),
                        );
                        nav.pop();
                        messenger.showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.success,
                            content: Text('Berhasil! Tahap $currentStage telah disetujui untuk $studentName.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        if (mounted) {
                          _loadDashboardData();
                        }
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        messenger.showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.danger,
                            content: Text('Gagal menyetujui: $e'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
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
    final user = ref.watch(authControllerProvider).userProfile;

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user?.fullName ?? 'Dosen Pembimbing',
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
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                      value: _isLoading ? '...' : '${_theses.length}',
                      subValue: 'Bimbingan Aktif',
                      icon: Icons.people_outline_rounded,
                      color: AppColors.primary,
                      onTap: () => context.push('/lecturer/students'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      title: 'Review Topik',
                      value: _isLoading ? '...' : '$_pendingTopicsCount',
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
                      value: _isLoading ? '...' : '${_consultations.length}',
                      subValue: 'Jadwal',
                      icon: Icons.event_available_outlined,
                      color: AppColors.success,
                      onTap: () => context.push('/lecturer/consultations'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ============================================================
              // PERMOHONAN PERGANTIAN TOPIK MAHASISWA
              // ============================================================
              if (_changeRequests.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.warningLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.swap_horiz_rounded, color: AppColors.warning, size: 18),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Permohonan Pergantian Topik',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.slate900),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.warningLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_changeRequests.length} Permohonan',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ..._changeRequests.map((req) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.slate900.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                req.studentName ?? 'Mahasiswa Bimbingan',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.slate900),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.warningLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Perlu Respon', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.warning)),
                            ),
                          ],
                        ),
                        Text(
                          'NIM: ${req.studentNim ?? "-"} • Diajukan: ${AppDateFormat.formatMedium(req.requestedAt)}',
                          style: const TextStyle(fontSize: 11, color: AppColors.slate500),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Judul Skripsi Saat Ini: ${req.currentTopicTitle ?? "-"}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.slate800),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.slate50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Alasan Mengapa Ganti Topik:', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.slate500)),
                              const SizedBox(height: 4),
                              Text(
                                '"${req.reason}"',
                                style: const TextStyle(fontSize: 12, color: AppColors.slate800, fontStyle: FontStyle.italic, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.danger,
                                  side: const BorderSide(color: AppColors.danger),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                onPressed: () => _showRejectTopicChangeDialog(req),
                                child: const Text('Tolak', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  foregroundColor: AppColors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                onPressed: () => _showApproveTopicChangeDialog(req),
                                icon: const Icon(Icons.check_rounded, size: 16),
                                label: const Text('Setujui Ganti', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 20),
              ],

              // ============================================================
              // 2. DEDICATED SECTION: VERIFIKASI & PERSETUJUAN ROADMAP MAHASISWA
              // ============================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 18),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Persetujuan Roadmap Mahasiswa',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.slate900),
                      ),
                    ],
                  ),
                  if (_theses.isNotEmpty)
                    InkWell(
                      onTap: () => context.push('/lecturer/students'),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_theses.length} Mahasiswa',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                            ),
                            const SizedBox(width: 3),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 9, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Roadmap mahasiswa hanya dapat dilanjutkan ke tahap berikutnya setelah Anda memberikan persetujuan.',
                style: TextStyle(fontSize: 11, color: AppColors.slate500),
              ),
              const SizedBox(height: 12),

              if (_isLoading)
                const LoadingShimmer()
              else if (_theses.isEmpty)
                const AppCard(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.assignment_turned_in_outlined, size: 40, color: AppColors.slate300),
                        SizedBox(height: 8),
                        Text(
                          'Belum Ada Mahasiswa Bimbingan yang Memerlukan Persetujuan',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.slate600),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Persetujuan usulan topik skripsi akan mengaktifkan roadmap mahasiswa di sini.',
                          style: TextStyle(fontSize: 11, color: AppColors.slate400),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _theses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final thesis = _theses[index];
                    final currentStage = thesis['current_stage_order'] as int? ?? 1;
                    final isCompletedAll = currentStage >= 8 &&
                        ((thesis['overall_progress_percentage'] as num?)?.toDouble() ?? 0.0) >= 100.0;
                    final stageName = _stageNames.length >= currentStage ? _stageNames[currentStage - 1] : 'Tahap $currentStage';
                    final student = thesis['student_profile'];
                    final studentName = student?['full_name'] ?? 'Mahasiswa';
                    final studentNim = student?['identifier_number'] ?? '-';
                    final progress = ((thesis['overall_progress_percentage'] as num?)?.toDouble() ?? 0.0) / 100.0;

                    return AppCard(
                      padding: const EdgeInsets.all(14),
                      onTap: () async {
                        await context.push('/lecturer/students/detail', extra: thesis);
                        _loadDashboardData();
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      studentName,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.slate900),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'NIM: $studentNim',
                                      style: const TextStyle(fontSize: 11, color: AppColors.slate500),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isCompletedAll ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isCompletedAll ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
                                  ),
                                ),
                                child: Text(
                                  isCompletedAll ? 'Lulus / Selesai' : 'Tahap $currentStage dari 8',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isCompletedAll ? const Color(0xFF065F46) : const Color(0xFF92400E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            thesis['title'] ?? 'Skripsi',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.slate700),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          // Stage pill & progress
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.flag_rounded, size: 14, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Tahap Berjalan: $stageName',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                                  ),
                                ],
                              ),
                              Text(
                                '${(progress * 100).toInt()}% Selesai',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.slate700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                              backgroundColor: AppColors.slate100,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'Lihat Detail Topik & Roadmap',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.primary),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Direct Action: Setujui Lanjut Tahap
                          if (!isCompletedAll)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  elevation: 0,
                                ),
                                onPressed: () => _showApproveStageDialog(thesis),
                                icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                                label: Text(
                                  'Setujui Tahap $currentStage & Lanjut',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                              ),
                            )
                          else
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.stars_rounded, color: AppColors.success, size: 16),
                                    SizedBox(width: 6),
                                    Text(
                                      'Seluruh Tahapan Skripsi Telah Selesai',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF166534)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),

              const SizedBox(height: 24),

              // ============================================================
              // 3. JADWAL KONSULTASI HARI INI
              // ============================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Konsultasi Bimbingan',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.slate900),
                  ),
                  TextButton(
                    onPressed: () => context.push('/lecturer/consultations'),
                    child: const Text('Lihat Semua', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_consultations.isEmpty)
                const AppCard(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'Belum ada jadwal konsultasi mendatang.',
                      style: TextStyle(fontSize: 12, color: AppColors.slate500),
                    ),
                  ),
                )
              else
                AppCard(
                  child: Column(
                    children: _consultations.take(3).map((c) {
                      final studentName = c.studentName ?? 'Mahasiswa';
                      final time = AppDateFormat.formatDateTime(c.scheduledStart);
                      return Column(
                        children: [
                          _ConsultationItem(
                            name: studentName,
                            time: time,
                            agenda: c.agenda,
                            status: c.status.name,
                            onAction: () => context.push('/lecturer/consultations'),
                          ),
                          if (c != _consultations.take(3).last) const Divider(height: 20),
                        ],
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
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
