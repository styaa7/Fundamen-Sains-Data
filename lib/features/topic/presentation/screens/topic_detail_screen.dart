import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/models/topic_model.dart';
import '../../../../core/models/user_role.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class TopicDetailScreen extends ConsumerStatefulWidget {
  final String topicId;

  const TopicDetailScreen({super.key, required this.topicId});

  @override
  ConsumerState<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends ConsumerState<TopicDetailScreen> {
  bool _isLoading = false;

  Future<void> _handleLecturerReview(String action) async {
    final feedbackController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Konfirmasi Review ($action)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Berikan catatan atau feedback untuk mahasiswa:'),
            const SizedBox(height: 12),
            TextField(
              controller: feedbackController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Tuliskan catatan evaluasi di sini...'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kirim Review')),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await ref.read(supabaseServiceProvider).reviewTopic(
              topicId: widget.topicId,
              action: action,
              feedback: feedbackController.text.trim(),
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(backgroundColor: AppColors.success, content: Text('Review $action berhasil disimpan')),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(backgroundColor: AppColors.danger, content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).userProfile;
    final isLecturer = user?.role == UserRole.dosen;

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: const Text('Detail Pengajuan Topik', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      StatusBadge.fromStatus('SUBMITTED'),
                      const Text('27 September 2026', style: TextStyle(fontSize: 11, color: AppColors.slate400)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Penerapan Algoritma Deep Learning untuk Deteksi Penyakit Daun Padi Berbasis Citra Digital',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.slate900),
                  ),
                  const SizedBox(height: 8),
                  const Text('Oleh: Ahmad Fauzi (NIM: 2021001)', style: TextStyle(fontSize: 12, color: AppColors.slate600)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Content Sections
            _DetailSection(
              title: 'Latar Belakang',
              content: 'Sektor pertanian menghadapi tantangan besar terkait penyakit tanaman yang menurunkan hasil panen hingga 30%. Pendeteksian dini secara otomatis menggunakan kamera smartphone dapat membantu petani mengidentifikasi penyakit secara tepat.',
            ),
            const SizedBox(height: 12),
            _DetailSection(
              title: 'Rumusan Masalah',
              content: '1. Bagaimana merancang arsitektur model Convolutional Neural Network (CNN) yang ringan untuk mendeteksi penyakit daun padi?\n2. Berapa tingkat akurasi model yang dihasilkan?',
            ),
            const SizedBox(height: 12),
            _DetailSection(
              title: 'Rencana Metodologi',
              content: 'Dataset citra sebanyak 2.500 foto, augmentasi data, training model menggunakan MobileNetV3 dengan transfer learning, evaluasi precision, recall, dan F1-Score.',
            ),
            const SizedBox(height: 24),

            // Lecturer Action Bar
            if (isLecturer) ...[
              const Text('Aksi Review Dosen', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.slate900)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Setujui',
                      onPressed: () => _handleLecturerReview('APPROVED'),
                      type: ButtonType.primary,
                      isLoading: _isLoading,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppButton(
                      label: 'Revisi',
                      onPressed: () => _handleLecturerReview('REVISION'),
                      type: ButtonType.secondary,
                      isLoading: _isLoading,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppButton(
                      label: 'Tolak',
                      onPressed: () => _handleLecturerReview('REJECTED'),
                      type: ButtonType.danger,
                      isLoading: _isLoading,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final String content;

  const _DetailSection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.slate800)),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 13, color: AppColors.slate600, height: 1.5)),
        ],
      ),
    );
  }
}
