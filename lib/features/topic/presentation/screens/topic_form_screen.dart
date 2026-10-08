import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/models/topic_model.dart';
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

  Future<void> _submitTopic(TopicStatus targetStatus) async {
    if (!_formKey.currentState!.validate()) return;

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
              const Text(
                'Calon Dosen Pembimbing',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.slate800),
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
}
