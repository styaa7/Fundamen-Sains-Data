import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/models/topic_model.dart';
import '../../../../core/services/ml_api_service.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class TopicFormScreen extends ConsumerStatefulWidget {
  final String? topicId;
  final TopicSubmission? initialTopic;

  const TopicFormScreen({
    super.key,
    this.topicId,
    this.initialTopic,
  });

  @override
  ConsumerState<TopicFormScreen> createState() => _TopicFormScreenState();
}

class _TopicFormScreenState extends ConsumerState<TopicFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _backgroundController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _problemController = TextEditingController();
  final _objectiveController = TextEditingController();
  final _methodologyController = TextEditingController();
  bool _isSubmitting = false;

  // AI Assistant State (Naive Bayes & SVM)
  bool _isAnalyzingAi = false;
  TopicQualityPrediction? _qualityPrediction;
  TopicCategoryPrediction? _categoryPrediction;
  String? _aiAnalysisError;

  TopicSubmission? _editingTopic;
  bool _isLoadingInitial = false;

  List<Map<String, dynamic>> _lecturers = [];
  String? _selectedLecturerId;
  bool _isLoadingLecturers = true;

  bool get _isEditing => (_editingTopic?.id.isNotEmpty ?? false) || (widget.topicId?.isNotEmpty ?? false);

  @override
  void initState() {
    super.initState();
    if (widget.initialTopic != null) {
      _editingTopic = widget.initialTopic;
      _populateFromTopic(widget.initialTopic!);
    } else if (widget.topicId != null && widget.topicId!.isNotEmpty) {
      _loadTopicFromId(widget.topicId!);
    }
    _loadLecturers();
  }

  void _populateFromTopic(TopicSubmission topic) {
    _titleController.text = topic.title;
    _backgroundController.text = topic.background;
    _descriptionController.text = topic.description;
    _problemController.text = topic.problemFormulation;
    _objectiveController.text = topic.researchObjective;
    _methodologyController.text = topic.methodology;
    if (topic.lecturerId != null) {
      _selectedLecturerId = topic.lecturerId;
    }
  }

  Future<void> _loadTopicFromId(String id) async {
    setState(() => _isLoadingInitial = true);
    try {
      final loaded = await ref.read(supabaseServiceProvider).fetchTopicById(id);
      if (loaded != null && mounted) {
        setState(() {
          _editingTopic = loaded;
          _populateFromTopic(loaded);
          _isLoadingInitial = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingInitial = false);
    }
  }

  bool _hasApprovedTopic = false;

  Future<void> _loadLecturers() async {
    try {
      final auth = ref.read(authControllerProvider);
      final user = auth.userProfile;
      if (user != null && !_isEditing) {
        final approved = await ref.read(supabaseServiceProvider).hasApprovedTopic(user.id);
        if (mounted) setState(() => _hasApprovedTopic = approved);
      }

      final list = await ref.read(supabaseServiceProvider).fetchLecturers();
      if (mounted) {
        setState(() {
          _lecturers = list;
          if (_selectedLecturerId == null) {
            if (list.isNotEmpty) {
              _selectedLecturerId = list.first['id'] as String;
            } else {
              _selectedLecturerId = '22222222-2222-2222-2222-222222222222';
            }
          }
          _isLoadingLecturers = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _selectedLecturerId ??= '22222222-2222-2222-2222-222222222222';
          _isLoadingLecturers = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _backgroundController.dispose();
    _descriptionController.dispose();
    _problemController.dispose();
    _objectiveController.dispose();
    _methodologyController.dispose();
    super.dispose();
  }

  void _fillDummyTopicData() {
    setState(() {
      _titleController.text = 'Implementasi Algoritma Support Vector Machine dan Naive Bayes untuk Klasifikasi Topik Skripsi Otomatis';
      _backgroundController.text = 'Proses seleksi dan peninjauan usulan judul skripsi sering memakan waktu lama. Penerapan teknologi text mining dan machine learning dapat membantu mempercepat klasifikasi bidang dan pra-evaluasi kelayakan secara objektif.';
      _descriptionController.text = 'Sistem berbasis web dan mobile yang mengklasifikasikan usulan topik skripsi mahasiswa ke dalam kategori bidang keahlian dan menguji tingkat kelayakan format.';
      _problemController.text = '1. Bagaimana merancang model SVM dan Naive Bayes untuk klasifikasi teks berbahasa Indonesia?\n2. Seberapa tinggi akurasi dan presisi model dalam mengelompokkan kategori topik skripsi?';
      _objectiveController.text = 'Mengembangkan modul klasifikasi topik skripsi otomatis berbasis machine learning dengan akurasi di atas 85% untuk membantu efisiensi dosen dan mahasiswa.';
      _methodologyController.text = 'Pengumpulan dataset teks dari naskah usulan skripsi, preprocessing (tokenizing, stopword removal), pembobotan TF-IDF, training model SVM dan Multinomial Naive Bayes, serta evaluasi k-fold cross validation.';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.primary,
        content: Text('✨ Contoh usulan topik fiktif berhasil dimuat! Silakan coba klik tombol AI di bawah.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  /// Menjalankan analisis paralel model Naive Bayes (Kualitas) & SVM (Kategori)
  Future<void> _analyzeTopicWithAi() async {
    final title = _titleController.text.trim();
    final background = _backgroundController.text.trim();
    final description = _descriptionController.text.trim();
    final problem = _problemController.text.trim();
    final methodology = _methodologyController.text.trim();

    if (title.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.warning,
          content: Text('Ketik judul minimal 5 karakter terlebih dahulu untuk analisis AI.'),
        ),
      );
      return;
    }

    setState(() {
      _isAnalyzingAi = true;
      _aiAnalysisError = null;
    });

    try {
      final mlApi = ref.read(mlApiServiceProvider);

      // Jalankan Naive Bayes dan SVM secara paralel
      final results = await Future.wait([
        mlApi.predictTopicQuality(
          title: title,
          background: background.isNotEmpty ? background : title,
          problemFormulation: problem.isNotEmpty ? problem : title,
          methodology: methodology.isNotEmpty ? methodology : title,
        ),
        mlApi.predictTopicCategory(
          title: title,
          description: description.isNotEmpty ? description : (background.isNotEmpty ? background : title),
          methodology: methodology,
        ),
      ]);

      if (mounted) {
        setState(() {
          _qualityPrediction = results[0] as TopicQualityPrediction;
          _categoryPrediction = results[1] as TopicCategoryPrediction;
          _isAnalyzingAi = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Text('✨ Analisis AI selesai! Hasil Naive Bayes & SVM telah siap.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzingAi = false;
          _aiAnalysisError = 'Gagal terhubung ke ML API ($e). Pastikan server FastAPI di ml_api sedang aktif di localhost:8000.';
        });
      }
    }
  }

  void _selectRecommendedLecturer(String lecturerName) {
    final cleanName = lecturerName.toLowerCase();
    for (final lec in _lecturers) {
      final fullName = (lec['full_name'] as String? ?? '').toLowerCase();
      final parts = fullName.split(RegExp(r'[\s,.]+')).where((p) => p.length > 3);
      bool isMatch = false;
      for (final p in parts) {
        if (cleanName.contains(p)) {
          isMatch = true;
          break;
        }
      }
      if (isMatch) {
        setState(() {
          _selectedLecturerId = lec['id'] as String;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text('Dosen pembimbing disetel: ${lec['full_name']}'),
          ),
        );
        return;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.info,
        content: Text('Rekomendasi SVM: $lecturerName. Silakan sesuaikan di dropdown calon dosen.'),
      ),
    );
  }

  Future<void> _submitTopic(TopicStatus targetStatus) async {
    if (!_formKey.currentState!.validate()) return;

    // Peringatan jika model Naive Bayes memprediksi REJECTED saat submit resmi
    if (targetStatus == TopicStatus.submitted &&
        _qualityPrediction != null &&
        _qualityPrediction!.predictedStatus == 'REJECTED') {
      final shouldProceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.danger),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Peringatan Kualitas Topik',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          content: Text(
            'Model Naive Bayes memprediksi usulan topik ini berpotensi DITOLAK (REJECTED) dengan catatan:\n\n'
            '${_qualityPrediction!.feedback}\n\n'
            'Apakah Anda ingin tetap mengirimkan pengajuan sekarang atau menyempurnakan usulan topik terlebih dahulu?',
            style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.slate700),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Perbaiki Dulu'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Tetap Ajukan'),
            ),
          ],
        ),
      );

      if (shouldProceed != true) return;
    }

    setState(() => _isSubmitting = true);
    final user = ref.read(authControllerProvider).userProfile;
    final currentUserId = user?.id ?? ref.read(supabaseServiceProvider).currentUser?.id ?? '';
    final topicId = _editingTopic?.id ?? widget.topicId ?? '';

    try {
      final topic = TopicSubmission(
        id: topicId,
        studentId: currentUserId,
        lecturerId: _selectedLecturerId ?? '22222222-2222-2222-2222-222222222222',
        title: _titleController.text.trim(),
        background: _backgroundController.text.trim(),
        description: _descriptionController.text.trim(),
        problemFormulation: _problemController.text.trim(),
        researchObjective: _objectiveController.text.trim(),
        methodology: _methodologyController.text.trim(),
        status: targetStatus,
        createdAt: _editingTopic?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(supabaseServiceProvider).createOrUpdateTopic(topic);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text(
              targetStatus == TopicStatus.draft
                  ? (topicId.isNotEmpty ? 'Perubahan draf berhasil disimpan' : 'Draft pengajuan topik berhasil disimpan')
                  : (topicId.isNotEmpty ? 'Topik skripsi berhasil diajukan!' : 'Pengajuan topik skripsi berhasil dikirim!'),
            ),
          ),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.danger, content: Text('Gagal menyimpan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingInitial) {
      return Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          title: const Text('Memuat Draf...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_hasApprovedTopic && !_isEditing) {
      return Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          title: const Text('Pengajuan Topik Baru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_person_outlined, size: 64, color: AppColors.warning),
                const SizedBox(height: 16),
                const Text(
                  'Pengajuan Topik Dinonaktifkan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.slate900),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Anda telah memiliki topik skripsi yang disetujui oleh dosen pembimbing. Untuk dapat mengajukan judul baru, silakan ajukan permohonan pergantian topik terlebih dahulu melalui dashboard.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.slate600, height: 1.4),
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'Kembali ke Dashboard',
                  onPressed: () => context.pop(),
                  type: ButtonType.primary,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Lanjutkan Pengajuan Topik' : 'Pengajuan Topik Skripsi',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isEditing) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFC7D2FE)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _editingTopic?.status == TopicStatus.revision
                              ? 'Mode Revisi: Perbarui data pengajuan sesuai instruksi dosen pembimbing.'
                              : 'Mode Draf: Anda dapat melengkapi usulan topik ini lalu menekan tombol "Ajukan Sekarang".',
                          style: const TextStyle(fontSize: 12, color: AppColors.slate700, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Pemilihan Calon Dosen Pembimbing
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Calon Dosen Pembimbing',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.slate800),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: _fillDummyTopicData,
                    icon: const Icon(Icons.flash_on_rounded, size: 14, color: AppColors.primary),
                    label: const Text('Isi Contoh Cepat', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.slate50,
                ),
                child: _isLoadingLecturers
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Memuat daftar dosen...', style: TextStyle(fontSize: 13, color: AppColors.slate500)),
                      )
                    : DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedLecturerId ?? (_lecturers.isNotEmpty ? _lecturers.first['id'] : '22222222-2222-2222-2222-222222222222'),
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                          items: _lecturers.isNotEmpty
                              ? _lecturers.map((lec) {
                                  return DropdownMenuItem<String>(
                                    value: lec['id'] as String,
                                    child: Text(
                                      '${lec['full_name']} (${lec['identifier_number'] ?? 'Dosen'})',
                                      style: const TextStyle(fontSize: 13, color: AppColors.slate800),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList()
                              : [
                                  const DropdownMenuItem<String>(
                                    value: '22222222-2222-2222-2222-222222222222',
                                    child: Text('Dr. Ir. Hendra Wijaya, M.T. (Dosen Default)', style: TextStyle(fontSize: 13)),
                                  ),
                                ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedLecturerId = val);
                            }
                          },
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Judul Skripsi',
                hint: 'Masukkan usulan judul skripsi (min. 15 karakter)',
                controller: _titleController,
                maxLines: 2,
                validator: (val) => (val == null || val.length < 15) ? 'Judul minimal 15 karakter' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Latar Belakang',
                hint: 'Jelaskan konteks dan urgensi penelitian ini...',
                controller: _backgroundController,
                maxLines: 4,
                validator: (val) => (val == null || val.length < 30) ? 'Latar belakang minimal 30 karakter' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Deskripsi / Topik Singkat',
                hint: 'Deskripsikan batasan dan ruang lingkup topik...',
                controller: _descriptionController,
                maxLines: 3,
                validator: (val) => (val == null || val.isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Rumusan Masalah',
                hint: '1. Bagaimana merancang...\n2. Bagaimana efektivitas...',
                controller: _problemController,
                maxLines: 3,
                validator: (val) => (val == null || val.isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Tujuan Penelitian',
                hint: 'Tujuan yang ingin dicapai melalui skripsi ini...',
                controller: _objectiveController,
                maxLines: 3,
                validator: (val) => (val == null || val.isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Rencana Metodologi Penelitian',
                hint: 'Jelaskan tahapan pengumpulan data, algoritma, atau metode analisis...',
                controller: _methodologyController,
                maxLines: 3,
                validator: (val) => (val == null || val.isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 24),

              // === ASISTEN AI (NAIVE BAYES & SVM) ===
              _buildAiAssistantSection(),

              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: _isEditing ? 'Simpan Draf' : 'Simpan Draf',
                      onPressed: () => _submitTopic(TopicStatus.draft),
                      type: ButtonType.outline,
                      isLoading: _isSubmitting,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: _isEditing ? 'Ajukan Sekarang' : 'Submit Pengajuan',
                      onPressed: () => _submitTopic(TopicStatus.submitted),
                      type: ButtonType.primary,
                      isLoading: _isSubmitting,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // AI Assistant Section Widgets
  // ===========================================================================

  Widget _buildAiAssistantSection() {
    final hasResults = _qualityPrediction != null && _categoryPrediction != null;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasResults ? const Color(0xFF818CF8) : AppColors.border,
          width: hasResults ? 1.5 : 1,
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome,
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
                      'Asisten AI: Evaluasi & Kategori',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate900,
                      ),
                    ),
                    Text(
                      'Pra-evaluasi kelayakan (Naive Bayes) & kategori bidang (SVM)',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AppButton(
            label: _isAnalyzingAi
                ? 'Menganalisis dengan AI...'
                : (hasResults ? 'Analisis Ulang dengan AI' : 'Cek Kualitas & Kategori AI'),
            icon: Icons.psychology_rounded,
            onPressed: _isAnalyzingAi ? null : _analyzeTopicWithAi,
            type: hasResults ? ButtonType.outline : ButtonType.primary,
            isLoading: _isAnalyzingAi,
          ),
          if (_aiAnalysisError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _aiAnalysisError!,
                      style: const TextStyle(fontSize: 12, color: AppColors.danger, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (hasResults) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 16),
            _buildSvmCard(_categoryPrediction!),
            const SizedBox(height: 16),
            _buildNaiveBayesCard(_qualityPrediction!),
          ],
        ],
      ),
    );
  }

  Widget _buildSvmCard(TopicCategoryPrediction cat) {
    IconData getCategoryIcon(String category) {
      switch (category.toLowerCase()) {
        case 'ai/ml':
          return Icons.memory_rounded;
        case 'iot':
          return Icons.sensors_rounded;
        case 'mobile dev':
          return Icons.phone_android_rounded;
        case 'web dev':
          return Icons.language_rounded;
        case 'data science':
          return Icons.insights_rounded;
        case 'cybersecurity':
          return Icons.security_rounded;
        case 'game dev':
          return Icons.sports_esports_rounded;
        default:
          return Icons.category_rounded;
      }
    }

    final catIcon = getCategoryIcon(cat.predictedCategory);
    final confidencePercent = (cat.confidence * 100).toStringAsFixed(1);

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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'MODEL SVM',
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
                  'Kategorisasi Bidang & Dosen',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.slate800),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$confidencePercent% Match',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF4F46E5)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDDD6FE)),
            ),
            child: Row(
              children: [
                Icon(catIcon, color: const Color(0xFF7C3AED), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Bidang Penelitian Terdeteksi:', style: TextStyle(fontSize: 11, color: AppColors.slate500)),
                      Text(
                        cat.predictedCategory,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF5B21B6)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text('Top Bidang Relevan:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.slate600)),
          const SizedBox(height: 6),
          ...cat.top3Categories.map((item) {
            final name = item['category'] as String;
            final prob = (item['probability'] as num).toDouble();
            final isPrimary = name == cat.predictedCategory;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 85,
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w500,
                        color: isPrimary ? AppColors.slate900 : AppColors.slate600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: prob,
                        minHeight: 6,
                        backgroundColor: AppColors.slate100,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isPrimary ? const Color(0xFF4F46E5) : const Color(0xFFA5B4FC),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 45,
                    child: Text(
                      '${(prob * 100).toStringAsFixed(1)}%',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w500,
                        color: isPrimary ? const Color(0xFF4F46E5) : AppColors.slate500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          if (cat.recommendedLecturers.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.slate100),
            const SizedBox(height: 8),
            const Text(
              'Rekomendasi Dosen Pembimbing (SVM):',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.slate700),
            ),
            const SizedBox(height: 6),
            ...cat.recommendedLecturers.map((lec) {
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.school_outlined, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        lec,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.slate800),
                      ),
                    ),
                    InkWell(
                      onTap: () => _selectRecommendedLecturer(lec),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFC7D2FE)),
                        ),
                        child: const Text(
                          'Pilih Dosen',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildNaiveBayesCard(TopicQualityPrediction qual) {
    Color statusColor;
    Color statusBg;
    IconData statusIcon;
    String statusLabel;

    switch (qual.predictedStatus) {
      case 'APPROVED':
        statusColor = const Color(0xFF059669);
        statusBg = const Color(0xFFECFDF5);
        statusIcon = Icons.check_circle_rounded;
        statusLabel = 'Layak Diterima (Approved)';
        break;
      case 'REVISION':
        statusColor = const Color(0xFFD97706);
        statusBg = const Color(0xFFFFFBEB);
        statusIcon = Icons.warning_amber_rounded;
        statusLabel = 'Perlu Revisi (Revision)';
        break;
      default:
        statusColor = const Color(0xFFDC2626);
        statusBg = const Color(0xFFFEF2F2);
        statusIcon = Icons.cancel_rounded;
        statusLabel = 'Berisiko Ditolak (Rejected)';
    }

    final pApproved = (qual.probabilities['APPROVED'] ?? 0.0) * 100;
    final pRevision = (qual.probabilities['REVISION'] ?? 0.0) * 100;
    final pRejected = (qual.probabilities['REJECTED'] ?? 0.0) * 100;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'MODEL NAIVE BAYES',
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
                  'Pra-Evaluasi Kelayakan Topik',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.slate800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Prediksi Status Kelayakan:', style: TextStyle(fontSize: 11, color: AppColors.slate500)),
                      Text(
                        statusLabel,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: statusColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text('Distribusi Probabilitas:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.slate600)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildProbabilityPill('Approved', pApproved, const Color(0xFF10B981)),
              const SizedBox(width: 8),
              _buildProbabilityPill('Revision', pRevision, const Color(0xFFF59E0B)),
              const SizedBox(width: 8),
              _buildProbabilityPill('Rejected', pRejected, const Color(0xFFEF4444)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.slate50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.slate200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.tips_and_updates_outlined, size: 16, color: Color(0xFF0284C7)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    qual.feedback,
                    style: const TextStyle(fontSize: 12, color: AppColors.slate700, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProbabilityPill(String label, double value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(
              '${value.toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

