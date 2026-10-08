import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/models/topic_model.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class TopicFormScreen extends ConsumerStatefulWidget {
  const TopicFormScreen({super.key});

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

    try {
      final topic = TopicSubmission(
        id: '',
        studentId: user?.id ?? '',
        lecturerId: '22222222-2222-2222-2222-222222222222',
        title: _titleController.text.trim(),
        background: _backgroundController.text.trim(),
        description: _descriptionController.text.trim(),
        problemFormulation: _problemController.text.trim(),
        researchObjective: _objectiveController.text.trim(),
        methodology: _methodologyController.text.trim(),
        status: targetStatus,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(supabaseServiceProvider).createOrUpdateTopic(topic);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text(
              targetStatus == TopicStatus.draft
                  ? 'Draft pengajuan topik berhasil disimpan'
                  : 'Pengajuan topik skripsi berhasil dikirim!',
            ),
          ),
        );
        context.pop();
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
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Pengajuan Topik Skripsi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                      label: 'Simpan Draf',
                      onPressed: () => _submitTopic(TopicStatus.draft),
                      type: ButtonType.outline,
                      isLoading: _isSubmitting,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'Submit Pengajuan',
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
