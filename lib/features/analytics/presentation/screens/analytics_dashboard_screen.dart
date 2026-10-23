import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';


import '../../../../core/services/ml_api_service.dart';

/// Analytics Dashboard Screen — Menampilkan fitur ML SkripsiFlow
///
/// 4 Tab:
///   1. Prediksi Waktu (Linear Regression)
///   2. Risiko Terlambat (Logistic Regression)
///   3. Evaluasi Topik (Naive Bayes)
///   4. Kategori Topik (SVM)
class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MlApiService _mlApi = MlApiService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mlApi.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Text(
          'ML Analytics',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFF818CF8),
          indicatorWeight: 3,
          labelColor: const Color(0xFF818CF8),
          unselectedLabelColor: const Color(0xFF94A3B8),
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.timer, size: 18), text: 'Prediksi Waktu'),
            Tab(icon: Icon(Icons.shield, size: 18), text: 'Risiko'),
            Tab(icon: Icon(Icons.fact_check, size: 18), text: 'Evaluasi Topik'),
            Tab(icon: Icon(Icons.label, size: 18), text: 'Kategori Topik'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CompletionTimeTab(mlApi: _mlApi),
          _OntimeRiskTab(mlApi: _mlApi),
          _TopicQualityTab(mlApi: _mlApi),
          _TopicCategoryTab(mlApi: _mlApi),
        ],
      ),
    );
  }
}

// =============================================================================
// TAB 1: Linear Regression — Prediksi Waktu Penyelesaian
// =============================================================================
class _CompletionTimeTab extends StatefulWidget {
  final MlApiService mlApi;
  const _CompletionTimeTab({required this.mlApi});

  @override
  State<_CompletionTimeTab> createState() => _CompletionTimeTabState();
}

class _CompletionTimeTabState extends State<_CompletionTimeTab> {
  final _formKey = GlobalKey<FormState>();
  double _stage = 3;
  double _progress = 37.5;
  double _days = 90;
  double _consultations = 5;
  double _revisions = 1;
  double _avgDays = 30;

  CompletionTimePrediction? _result;
  bool _loading = false;
  String? _error;

  Future<void> _predict() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await widget.mlApi.predictCompletionTime(
        currentStageOrder: _stage.round(),
        overallProgressPercentage: _progress,
        daysSinceStart: _days.round(),
        totalConsultations: _consultations.round(),
        totalRevisions: _revisions.round(),
        avgDaysPerStage: _avgDays,
      );
      setState(() { _result = result; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            '📈 Linear Regression',
            'Memprediksi estimasi hari penyelesaian skripsi',
            const Color(0xFF3B82F6),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
          const SizedBox(height: 20),

          // Input sliders
          _buildSlider('Tahapan Saat Ini', _stage, 1, 8, 7, (v) => setState(() => _stage = v)),
          _buildSlider('Progress (%)', _progress, 0, 100, 100, (v) => setState(() => _progress = v)),
          _buildSlider('Hari Sejak Mulai', _days, 1, 365, 364, (v) => setState(() => _days = v)),
          _buildSlider('Total Konsultasi', _consultations, 0, 30, 30, (v) => setState(() => _consultations = v)),
          _buildSlider('Total Revisi', _revisions, 0, 5, 5, (v) => setState(() => _revisions = v)),
          _buildSlider('Rata-rata Hari/Stage', _avgDays, 5, 60, 55, (v) => setState(() => _avgDays = v)),

          const SizedBox(height: 16),
          _buildPredictButton(_predict, _loading),
          const SizedBox(height: 20),

          if (_error != null) _buildErrorCard(_error!),
          if (_result != null)
            _buildResultCard(
              icon: Icons.timer,
              color: const Color(0xFF3B82F6),
              title: 'Estimasi Penyelesaian',
              children: [
                _buildMetricRow('Hari', '${_result!.predictedDays} hari'),
                _buildMetricRow('Minggu', '${_result!.predictedWeeks} minggu'),
                _buildMetricRow('Model', _result!.model),
              ],
            ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.95, 0.95)),
        ],
      ),
    );
  }
}

// =============================================================================
// TAB 2: Logistic Regression — Risiko Keterlambatan
// =============================================================================
class _OntimeRiskTab extends StatefulWidget {
  final MlApiService mlApi;
  const _OntimeRiskTab({required this.mlApi});

  @override
  State<_OntimeRiskTab> createState() => _OntimeRiskTabState();
}

class _OntimeRiskTabState extends State<_OntimeRiskTab> {
  double _stage = 4;
  double _progress = 50;
  double _days = 120;
  double _consultFreq = 1.5;
  double _revisions = 2;
  double _completionRate = 0.8;

  OntimeRiskPrediction? _result;
  bool _loading = false;
  String? _error;

  Future<void> _predict() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await widget.mlApi.predictOntimeRisk(
        currentStageOrder: _stage.round(),
        overallProgressPercentage: _progress,
        daysSinceStart: _days.round(),
        consultationFrequency: _consultFreq,
        revisionCount: _revisions.round(),
        stageCompletionRate: _completionRate,
      );
      setState(() { _result = result; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Color _riskColor(String level) {
    switch (level) {
      case 'HIGH': return const Color(0xFFEF4444);
      case 'MEDIUM': return const Color(0xFFF59E0B);
      default: return const Color(0xFF22C55E);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            '🎯 Logistic Regression',
            'Klasifikasi: Tepat Waktu vs Terlambat',
            const Color(0xFF8B5CF6),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
          const SizedBox(height: 20),

          _buildSlider('Tahapan Saat Ini', _stage, 1, 8, 7, (v) => setState(() => _stage = v)),
          _buildSlider('Progress (%)', _progress, 0, 100, 100, (v) => setState(() => _progress = v)),
          _buildSlider('Hari Sejak Mulai', _days, 1, 365, 364, (v) => setState(() => _days = v)),
          _buildSlider('Konsultasi/Bulan', _consultFreq, 0, 5, 50, (v) => setState(() => _consultFreq = v), decimals: 1),
          _buildSlider('Jumlah Revisi', _revisions, 0, 5, 5, (v) => setState(() => _revisions = v)),
          _buildSlider('Stage Completion Rate', _completionRate, 0, 2, 20, (v) => setState(() => _completionRate = v), decimals: 2),

          const SizedBox(height: 16),
          _buildPredictButton(_predict, _loading),
          const SizedBox(height: 20),

          if (_error != null) _buildErrorCard(_error!),
          if (_result != null)
            _buildResultCard(
              icon: Icons.shield,
              color: _riskColor(_result!.riskLevel),
              title: _result!.riskLabel,
              children: [
                _buildMetricRow('Prediksi', _result!.prediction == 'TEPAT_WAKTU' ? '✅ Tepat Waktu' : '⚠️ Terlambat'),
                _buildMetricRow('P(Tepat Waktu)', '${(_result!.probabilityOnTime * 100).toStringAsFixed(1)}%'),
                _buildMetricRow('P(Terlambat)', '${(_result!.probabilityLate * 100).toStringAsFixed(1)}%'),
                _buildMetricRow('Level Risiko', _result!.riskLevel),
                const SizedBox(height: 12),
                // Risk bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: _result!.probabilityLate,
                    backgroundColor: const Color(0xFF1E293B),
                    valueColor: AlwaysStoppedAnimation(_riskColor(_result!.riskLevel)),
                    minHeight: 10,
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.95, 0.95)),
        ],
      ),
    );
  }
}

// =============================================================================
// TAB 3: Naive Bayes — Evaluasi Kualitas Topik
// =============================================================================
class _TopicQualityTab extends StatefulWidget {
  final MlApiService mlApi;
  const _TopicQualityTab({required this.mlApi});

  @override
  State<_TopicQualityTab> createState() => _TopicQualityTabState();
}

class _TopicQualityTabState extends State<_TopicQualityTab> {
  final _titleCtrl = TextEditingController();
  final _bgCtrl = TextEditingController();
  final _problemCtrl = TextEditingController();
  final _methodCtrl = TextEditingController();

  TopicQualityPrediction? _result;
  bool _loading = false;
  String? _error;

  Future<void> _predict() async {
    if (_titleCtrl.text.isEmpty || _bgCtrl.text.isEmpty ||
        _problemCtrl.text.isEmpty || _methodCtrl.text.isEmpty) {
      setState(() => _error = 'Semua field harus diisi');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final result = await widget.mlApi.predictTopicQuality(
        title: _titleCtrl.text,
        background: _bgCtrl.text,
        problemFormulation: _problemCtrl.text,
        methodology: _methodCtrl.text,
      );
      setState(() { _result = result; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'APPROVED': return const Color(0xFF22C55E);
      case 'REVISION': return const Color(0xFFF59E0B);
      default: return const Color(0xFFEF4444);
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'APPROVED': return Icons.check_circle;
      case 'REVISION': return Icons.error;
      default: return Icons.cancel;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            '📝 Naive Bayes',
            'Pra-evaluasi kualitas topik skripsi',
            const Color(0xFFF59E0B),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
          const SizedBox(height: 20),

          _buildTextField(_titleCtrl, 'Judul Topik Skripsi', maxLines: 2),
          const SizedBox(height: 12),
          _buildTextField(_bgCtrl, 'Latar Belakang', maxLines: 4),
          const SizedBox(height: 12),
          _buildTextField(_problemCtrl, 'Rumusan Masalah', maxLines: 3),
          const SizedBox(height: 12),
          _buildTextField(_methodCtrl, 'Metodologi', maxLines: 3),

          const SizedBox(height: 16),
          _buildPredictButton(_predict, _loading),
          const SizedBox(height: 20),

          if (_error != null) _buildErrorCard(_error!),
          if (_result != null) ...[
            _buildResultCard(
              icon: _statusIcon(_result!.predictedStatus),
              color: _statusColor(_result!.predictedStatus),
              title: _result!.predictedLabel,
              children: [
                _buildMetricRow('Status', _result!.predictedStatus),
                ...(_result!.probabilities.entries.map((e) =>
                  _buildMetricRow('P(${e.key})', '${(e.value * 100).toStringAsFixed(1)}%'),
                )),
                const Divider(color: Color(0xFF334155), height: 20),
                Text(
                  '💡 ${_result!.feedback}',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFCBD5E1),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.95, 0.95)),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// TAB 4: SVM — Kategorisasi Bidang Topik
// =============================================================================
class _TopicCategoryTab extends StatefulWidget {
  final MlApiService mlApi;
  const _TopicCategoryTab({required this.mlApi});

  @override
  State<_TopicCategoryTab> createState() => _TopicCategoryTabState();
}

class _TopicCategoryTabState extends State<_TopicCategoryTab> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _methodCtrl = TextEditingController();

  TopicCategoryPrediction? _result;
  bool _loading = false;
  String? _error;

  Future<void> _predict() async {
    if (_titleCtrl.text.isEmpty || _descCtrl.text.isEmpty) {
      setState(() => _error = 'Judul dan deskripsi harus diisi');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final result = await widget.mlApi.predictTopicCategory(
        title: _titleCtrl.text,
        description: _descCtrl.text,
        methodology: _methodCtrl.text,
      );
      setState(() { _result = result; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            '🔬 SVM (Support Vector Machine)',
            'Auto-kategorisasi bidang & rekomendasi dosen',
            const Color(0xFFEC4899),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
          const SizedBox(height: 20),

          _buildTextField(_titleCtrl, 'Judul Topik Skripsi', maxLines: 2),
          const SizedBox(height: 12),
          _buildTextField(_descCtrl, 'Deskripsi Topik', maxLines: 4),
          const SizedBox(height: 12),
          _buildTextField(_methodCtrl, 'Metodologi (Opsional)', maxLines: 3),

          const SizedBox(height: 16),
          _buildPredictButton(_predict, _loading),
          const SizedBox(height: 20),

          if (_error != null) _buildErrorCard(_error!),
          if (_result != null) ...[
            // Category result
            _buildResultCard(
              icon: Icons.label,
              color: const Color(0xFFEC4899),
              title: _result!.predictedCategory,
              children: [
                _buildMetricRow('Confidence', '${(_result!.confidence * 100).toStringAsFixed(1)}%'),
                const SizedBox(height: 12),
                Text(
                  'Top 3 Kategori:',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                ...(_result!.top3Categories.map((cat) {
                  final prob = (cat['probability'] as num).toDouble();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            cat['category'] as String,
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                          ),
                        ),
                        Expanded(
                          flex: 5,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: prob,
                              backgroundColor: const Color(0xFF1E293B),
                              valueColor: const AlwaysStoppedAnimation(Color(0xFFEC4899)),
                              minHeight: 8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(prob * 100).toStringAsFixed(1)}%',
                          style: GoogleFonts.jetBrainsMono(
                            color: const Color(0xFF94A3B8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                })),
              ],
            ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.95, 0.95)),

            const SizedBox(height: 16),

            // Lecturer recommendations
            if (_result!.recommendedLecturers.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1E293B),
                      const Color(0xFF1E293B).withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.school, color: Color(0xFF818CF8), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Dosen yang Direkomendasikan',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF818CF8),
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...(_result!.recommendedLecturers.map((lecturer) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.person, color: Color(0xFF94A3B8), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              lecturer,
                              style: GoogleFonts.inter(
                                color: const Color(0xFFE2E8F0),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ))),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(begin: 0.1),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// SHARED HELPER WIDGETS
// =============================================================================

Widget _buildSectionHeader(String title, String subtitle, Color color) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF94A3B8),
          ),
        ),
      ],
    ),
  );
}

Widget _buildSlider(
  String label,
  double value,
  double min,
  double max,
  int divisions,
  ValueChanged<double> onChanged, {
  int decimals = 0,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
            ),
            Text(
              value.toStringAsFixed(decimals),
              style: GoogleFonts.jetBrainsMono(
                color: const Color(0xFF818CF8),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: const Color(0xFF818CF8),
            inactiveTrackColor: const Color(0xFF1E293B),
            thumbColor: const Color(0xFF818CF8),
            overlayColor: const Color(0xFF818CF8).withOpacity(0.2),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    ),
  );
}

Widget _buildPredictButton(VoidCallback onPressed, bool loading) {
  return SizedBox(
    width: double.infinity,
    height: 52,
    child: ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF818CF8),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      child: loading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            )
          : Text(
              '🚀 Prediksi Sekarang',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
    ),
  );
}

Widget _buildResultCard({
  required IconData icon,
  required Color color,
  required String title,
  required List<Widget> children,
}) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFF1E293B),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withOpacity(0.4)),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.1),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        const Divider(color: Color(0xFF334155), height: 24),
        ...children,
      ],
    ),
  );
}

Widget _buildMetricRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: const Color(0xFF94A3B8),
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

Widget _buildErrorCard(String error) {
  return Container(
    padding: const EdgeInsets.all(14),
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: const Color(0xFFEF4444).withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
    ),
    child: Row(
      children: [
        const Icon(Icons.warning, color: Color(0xFFEF4444), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            error,
            style: GoogleFonts.inter(color: const Color(0xFFFCA5A5), fontSize: 13),
          ),
        ),
      ],
    ),
  );
}

Widget _buildTextField(
  TextEditingController controller,
  String label, {
  int maxLines = 1,
}) {
  return TextField(
    controller: controller,
    maxLines: maxLines,
    style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13),
      filled: true,
      fillColor: const Color(0xFF1E293B),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF818CF8), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}
