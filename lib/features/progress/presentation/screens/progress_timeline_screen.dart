import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/models/consultation_model.dart';
import '../../../../core/models/thesis_progress_model.dart';
import '../../../../core/services/ml_api_service.dart';
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

  // ML State (Linear Regression & Logistic Regression)
  bool _isLoadingMl = false;
  CompletionTimePrediction? _completionPrediction;
  OntimeRiskPrediction? _ontimePrediction;
  String? _mlError;
  int _totalConsultations = 0;
  int _daysSinceStart = 0;

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
      final finalThesis = thesisData ?? _createDummyTestingThesis(targetId);

      if (mounted) {
        setState(() {
          _thesis = finalThesis;
          _isLoading = false;
        });

        // Jalankan prediksi ML secara otomatis jika data thesis tersedia
        _runMlPredictions(targetId, finalThesis);
      }
    } catch (_) {
      if (mounted) {
        final dummy = _createDummyTestingThesis('dummy-student-id');
        setState(() {
          _thesis = dummy;
          _isLoading = false;
        });
        _runMlPredictions('dummy-student-id', dummy);
      }
    }
  }

  Thesis _createDummyTestingThesis(String studentId) {
    final now = DateTime.now();
    return Thesis(
      id: 'demo-thesis-uuid',
      studentId: studentId,
      lecturerId: '22222222-2222-2222-2222-222222222222',
      topicSubmissionId: 'demo-topic-uuid',
      title: 'Klasifikasi Citra Rontgen Paru-Paru Menggunakan Convolutional Neural Network',
      currentStageOrder: 3,
      overallProgressPercentage: 37.5,
      createdAt: now.subtract(const Duration(days: 90)),
      stages: [
        ThesisProgressStage(
          id: 's1',
          thesisId: 'demo-thesis-uuid',
          stageOrder: 1,
          stageName: 'Pengajuan Topik',
          status: StageStatus.completed,
          progressPercentage: 100.0,
          studentNotes: 'Topik disetujui dosen pembimbing.',
          completedDate: now.subtract(const Duration(days: 75)),
        ),
        ThesisProgressStage(
          id: 's2',
          thesisId: 'demo-thesis-uuid',
          stageOrder: 2,
          stageName: 'Proposal Skripsi',
          status: StageStatus.completed,
          progressPercentage: 100.0,
          studentNotes: 'Naskah proposal bab 1-3 rampung dan disetujui.',
          completedDate: now.subtract(const Duration(days: 20)),
        ),
        ThesisProgressStage(
          id: 's3',
          thesisId: 'demo-thesis-uuid',
          stageOrder: 3,
          stageName: 'Seminar Proposal',
          status: StageStatus.inProgress,
          progressPercentage: 40.0,
          studentNotes: 'Menunggu jadwal sidang seminar proposal.',
          startDate: now.subtract(const Duration(days: 15)),
        ),
        ThesisProgressStage(
          id: 's4',
          thesisId: 'demo-thesis-uuid',
          stageOrder: 4,
          stageName: 'Pengumpulan Data',
          status: StageStatus.notStarted,
          progressPercentage: 0.0,
        ),
        ThesisProgressStage(
          id: 's5',
          thesisId: 'demo-thesis-uuid',
          stageOrder: 5,
          stageName: 'Analisis Data',
          status: StageStatus.notStarted,
          progressPercentage: 0.0,
        ),
        ThesisProgressStage(
          id: 's6',
          thesisId: 'demo-thesis-uuid',
          stageOrder: 6,
          stageName: 'Penyusunan Naskah',
          status: StageStatus.notStarted,
          progressPercentage: 0.0,
        ),
        ThesisProgressStage(
          id: 's7',
          thesisId: 'demo-thesis-uuid',
          stageOrder: 7,
          stageName: 'Seminar Hasil',
          status: StageStatus.notStarted,
          progressPercentage: 0.0,
        ),
        ThesisProgressStage(
          id: 's8',
          thesisId: 'demo-thesis-uuid',
          stageOrder: 8,
          stageName: 'Sidang Akhir',
          status: StageStatus.notStarted,
          progressPercentage: 0.0,
        ),
      ],
    );
  }

  Future<void> _runMlPredictions(String studentId, Thesis thesis) async {
    if (thesis.overallProgressPercentage >= 100.0) return;

    setState(() {
      _isLoadingMl = true;
      _mlError = null;
    });

    try {
      final service = ref.read(supabaseServiceProvider);
      final mlApi = ref.read(mlApiServiceProvider);

      // 1. Ambil data riwayat konsultasi mahasiswa
      List<Consultation> consults = [];
      try {
        consults = await service.fetchConsultations(studentId: studentId);
      } catch (_) {
        consults = [];
      }

      final completedConsults = consults
          .where((c) => c.status == ConsultationStatus.completed)
          .length;
      final totalConsults = completedConsults > 0 ? completedConsults : consults.length;

      // 2. Hitung days_since_start dari created_at thesis atau tanggal pertama tahapan
      DateTime? startDate = thesis.createdAt;
      if (startDate == null && thesis.stages.isNotEmpty) {
        final sortedStages = List<ThesisProgressStage>.from(thesis.stages)
          ..sort((a, b) => a.stageOrder.compareTo(b.stageOrder));
        startDate = sortedStages.first.startDate ?? sortedStages.first.completedDate;
      }
      startDate ??= DateTime.now().subtract(const Duration(days: 30));

      final rawDays = DateTime.now().difference(startDate).inDays;
      final daysSinceStart = rawDays < 7 ? 7 : rawDays;

      // 3. Hitung fitur turunan lainnya
      final currentStage = thesis.currentStageOrder.clamp(1, 8);
      final avgDaysPerStage = daysSinceStart / (currentStage > 0 ? currentStage : 1);
      final consultationFrequency = (totalConsults / (daysSinceStart / 30.0)).clamp(0.0, 10.0);
      final stageCompletionRate = (currentStage / 8.0).clamp(0.0, 1.0);
      const revisionCount = 1; // Estimasi konservatif revisi

      // 4. Panggil Linear Regression & Logistic Regression secara paralel
      final results = await Future.wait([
        mlApi.predictCompletionTime(
          currentStageOrder: currentStage,
          overallProgressPercentage: thesis.overallProgressPercentage,
          daysSinceStart: daysSinceStart,
          totalConsultations: totalConsults,
          totalRevisions: revisionCount,
          avgDaysPerStage: double.parse(avgDaysPerStage.toStringAsFixed(1)),
        ),
        mlApi.predictOntimeRisk(
          currentStageOrder: currentStage,
          overallProgressPercentage: thesis.overallProgressPercentage,
          daysSinceStart: daysSinceStart,
          consultationFrequency: double.parse(consultationFrequency.toStringAsFixed(1)),
          revisionCount: revisionCount,
          stageCompletionRate: double.parse(stageCompletionRate.toStringAsFixed(2)),
        ),
      ]);

      if (mounted) {
        setState(() {
          _completionPrediction = results[0] as CompletionTimePrediction;
          _ontimePrediction = results[1] as OntimeRiskPrediction;
          _totalConsultations = totalConsults;
          _daysSinceStart = daysSinceStart;
          _isLoadingMl = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMl = false;
          _mlError = 'Gagal memuat prediksi ML ($e). Pastikan server FastAPI di ml_api sedang aktif di localhost:8000.';
        });
      }
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
              const SizedBox(height: 16),

              // === CARD PREDIKSI ML (LINEAR & LOGISTIC REGRESSION) ===
              _buildMlPredictionsCard(),

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
                              color: status == 'COMPLETED' ? AppColors.success.withValues(alpha: 0.4) : AppColors.slate200,
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

  // ===========================================================================
  // ML Prediction Cards (Linear Regression & Logistic Regression)
  // ===========================================================================

  Widget _buildMlPredictionsCard() {
    final hasData = _completionPrediction != null && _ontimePrediction != null;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasData ? const Color(0xFF818CF8) : AppColors.border,
          width: hasData ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(79, 70, 229, 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: Color(0xFF4F46E5),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Progress Analytics',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate900,
                      ),
                    ),
                    Text(
                      'Prediksi waktu (Linear Reg.) & risiko keterlambatan (Logistic Reg.)',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isLoadingMl)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
            ],
          ),

          // Loading Indicator
          if (_isLoadingMl && !hasData) ...[
            const SizedBox(height: 16),
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Menghitung prediksi dengan model Machine Learning...',
                      style: TextStyle(fontSize: 12, color: AppColors.slate600),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Error Display
          if (_mlError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.danger, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _mlError!,
                      style: const TextStyle(fontSize: 12, color: AppColors.danger, height: 1.3),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      if (_thesis != null) {
                        final user = ref.read(authControllerProvider).userProfile;
                        final targetId = widget.studentId ?? user?.id ?? '';
                        _runMlPredictions(targetId, _thesis!);
                      }
                    },
                    child: const Text('Coba Lagi', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ),
          ],

          // Predictions Content
          if (hasData) ...[
            const SizedBox(height: 14),

            // 1. LINEAR REGRESSION CARD
            _buildLinearRegressionCard(_completionPrediction!),

            const SizedBox(height: 12),

            // 2. LOGISTIC REGRESSION CARD
            _buildLogisticRegressionCard(_ontimePrediction!),

            const SizedBox(height: 12),

            // Summary Stats Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Durasi Skripsi', '$_daysSinceStart Hari'),
                  Container(width: 1, height: 24, color: AppColors.slate200),
                  _buildStatItem('Total Konsultasi', '$_totalConsultations Kali'),
                  Container(width: 1, height: 24, color: AppColors.slate200),
                  _buildStatItem(
                    'Penyelesaian',
                    '${_thesis?.overallProgressPercentage.toStringAsFixed(0)}%',
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.slate800),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.slate500),
        ),
      ],
    );
  }

  Widget _buildLinearRegressionCard(CompletionTimePrediction pred) {
    final days = pred.predictedDays.round();
    final weeks = pred.predictedWeeks.toStringAsFixed(1);
    final targetDate = DateTime.now().add(Duration(days: days));
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final formattedTarget = '${targetDate.day} ${months[targetDate.month]} ${targetDate.year}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'LINEAR REGRESSION',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Estimasi Waktu Kelulusan',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.slate800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFC7D2FE)),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, color: Color(0xFF4F46E5), size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$days Hari Lagi (~$weeks Minggu)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF3730A3),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Estimasi Tanggal Selesai: $formattedTarget',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF4338CA)),
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

  Widget _buildLogisticRegressionCard(OntimeRiskPrediction risk) {
    Color riskColor;
    Color riskBg;
    IconData riskIcon;

    switch (risk.riskLevel.toUpperCase()) {
      case 'HIGH':
        riskColor = const Color(0xFFDC2626);
        riskBg = const Color(0xFFFEF2F2);
        riskIcon = Icons.warning_rounded;
        break;
      case 'MEDIUM':
        riskColor = const Color(0xFFD97706);
        riskBg = const Color(0xFFFFFBEB);
        riskIcon = Icons.error_outline_rounded;
        break;
      case 'LOW':
      default:
        riskColor = const Color(0xFF059669);
        riskBg = const Color(0xFFECFDF5);
        riskIcon = Icons.check_circle_rounded;
        break;
    }

    final pOnTime = (risk.probabilityOnTime * 100).toStringAsFixed(1);
    final pLate = (risk.probabilityLate * 100).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'LOGISTIC REGRESSION',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Prediksi Risiko Keterlambatan',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.slate800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: riskBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: riskColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(riskIcon, color: riskColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        risk.riskLabel,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: riskColor,
                        ),
                      ),
                      Text(
                        risk.prediction == 'ON_TIME'
                            ? 'Peluang selesai tepat waktu: $pOnTime%'
                            : 'Peluang mengalami keterlambatan: $pLate%',
                        style: TextStyle(fontSize: 11, color: riskColor.withValues(alpha: 0.9)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tepat Waktu', style: TextStyle(fontSize: 11, color: Color(0xFF047857))),
                      Text('$pOnTime%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF047857))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Terlambat', style: TextStyle(fontSize: 11, color: Color(0xFFB91C1C))),
                      Text('$pLate%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFB91C1C))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
