import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/models/consultation_model.dart';
import '../../../../core/models/user_role.dart';
import '../../../../core/utils/app_date_format.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class ConsultationListScreen extends ConsumerStatefulWidget {
  const ConsultationListScreen({super.key});

  @override
  ConsumerState<ConsultationListScreen> createState() => _ConsultationListScreenState();
}

class _ConsultationListScreenState extends ConsumerState<ConsultationListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Consultation> _consultations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadConsultations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadConsultations() async {
    setState(() {
      _isLoading = true;
    });

    final auth = ref.read(authControllerProvider);
    final user = auth.userProfile;
    final service = ref.read(supabaseServiceProvider);

    try {
      List<Consultation> list;
      if (user?.role == UserRole.mahasiswa) {
        list = await service.fetchConsultations(studentId: user?.id);
      } else if (user?.role == UserRole.dosen) {
        list = await service.fetchConsultations(lecturerId: user?.id);
      } else {
        list = await service.fetchConsultations();
      }

      if (mounted) {
        setState(() {
          _consultations = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateStatus(String id, String status, {String? reason}) async {
    try {
      await ref.read(supabaseServiceProvider).updateConsultationStatus(
            consultationId: id,
            status: status,
            rejectionReason: reason,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text('Status konsultasi diubah ke $status'),
        ),
      );
      _loadConsultations();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.danger, content: Text('Error: $e')),
      );
    }
  }

  Future<void> _completeWithNotes(String id) async {
    final noteController = TextEditingController();
    final actionItemsController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Catatan Hasil Bimbingan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Catatan & Feedback Bimbingan',
                  hintText: 'Tuliskan poin-poin yang dibahas...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: actionItemsController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Target / Action Items Mahasiswa',
                  hintText: 'Tugas yang harus diselesaikan mahasiswa selanjutnya...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Simpan & Selesaikan'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await ref.read(supabaseServiceProvider).saveConsultationNotes(
              consultationId: id,
              notes: noteController.text.trim().isEmpty ? 'Bimbingan telah terlaksana.' : noteController.text.trim(),
              feedback: noteController.text.trim(),
              actionItems: actionItemsController.text.trim(),
            );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: AppColors.success, content: Text('Catatan bimbingan berhasil disimpan!')),
        );
        _loadConsultations();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.danger, content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.userProfile;
    final isStudent = user?.role == UserRole.mahasiswa;
    final isLecturer = user?.role == UserRole.dosen;

    final upcoming = _consultations.where((c) =>
        c.status == ConsultationStatus.requested || c.status == ConsultationStatus.confirmed).toList();
    final history = _consultations.where((c) =>
        c.status == ConsultationStatus.completed ||
        c.status == ConsultationStatus.rejected ||
        c.status == ConsultationStatus.cancelled).toList();

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: const Text('Jadwal Konsultasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.slate500,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: [
            Tab(text: 'Aktif / Mendatang (${upcoming.length})'),
            Tab(text: 'Riwayat Selesai (${history.length})'),
          ],
        ),
      ),
      floatingActionButton: isStudent
          ? FloatingActionButton.extended(
              onPressed: () async {
                await context.push('/student/consultation/book');
                _loadConsultations();
              },
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_rounded, color: AppColors.white),
              label: const Text('Ajukan Konsultasi', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600)),
            )
          : null,
      body: _isLoading
          ? const Padding(
              padding: EdgeInsets.all(16.0),
              child: LoadingShimmer(),
            )
          : RefreshIndicator(
              onRefresh: _loadConsultations,
              color: AppColors.primary,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildList(upcoming, isLecturer: isLecturer, isStudent: isStudent, isUpcoming: true),
                  _buildList(history, isLecturer: isLecturer, isStudent: isStudent, isUpcoming: false),
                ],
              ),
            ),
    );
  }

  Widget _buildList(List<Consultation> list, {required bool isLecturer, required bool isStudent, required bool isUpcoming}) {
    if (list.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 60),
          EmptyStateView(
            title: isUpcoming ? 'Belum Ada Jadwal Aktif' : 'Belum Ada Riwayat Konsultasi',
            description: isUpcoming
                ? 'Jadwal konsultasi yang Anda ajukan atau tunggu konfirmasi akan tampil di sini.'
                : 'Konsultasi yang telah selesai, ditolak, atau dibatalkan akan diarsipkan di sini.',
            icon: Icons.event_note_outlined,
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = list[index];
        final dateStr = AppDateFormat.formatFull(item.scheduledStart);
        final timeStr = '${AppDateFormat.formatTime(item.scheduledStart)} - ${AppDateFormat.formatTime(item.scheduledEnd)} WIB';

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(dateStr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.slate900)),
                    ],
                  ),
                  StatusBadge.fromStatus(item.status.name.toUpperCase()),
                ],
              ),
              const SizedBox(height: 6),
              Text(timeStr, style: const TextStyle(fontSize: 12, color: AppColors.slate500)),
              const Divider(height: 20),

              if (item.lecturerName != null && item.lecturerName!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text('Dosen Pembimbing: ${item.lecturerName}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.slate700)),
                ),
              if (item.studentName != null && item.studentName!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text('Mahasiswa: ${item.studentName}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                ),

              const SizedBox(height: 4),
              Text('Agenda: ${item.agenda}', style: const TextStyle(fontSize: 12, color: AppColors.slate600, height: 1.4)),

              // Notes & Feedback
              if (item.note != null) ...[
                const SizedBox(height: 12),
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
                      const Text('Catatan & Feedback Dosen:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.slate700)),
                      const SizedBox(height: 4),
                      Text(item.note!.lecturerNotes, style: const TextStyle(fontSize: 12, color: AppColors.slate600, fontStyle: FontStyle.italic)),
                      if (item.note!.actionItems != null && item.note!.actionItems!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text('Action Items: ${item.note!.actionItems}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
                      ],
                    ],
                  ),
                ),
              ],

              // Dosen Action Buttons
              if (isLecturer && item.status == ConsultationStatus.requested) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Setujui',
                        type: ButtonType.primary,
                        onPressed: () => _updateStatus(item.id, 'CONFIRMED'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppButton(
                        label: 'Tolak',
                        type: ButtonType.danger,
                        onPressed: () => _updateStatus(item.id, 'REJECTED', reason: 'Jadwal bertabrakan dengan agenda lain'),
                      ),
                    ),
                  ],
                ),
              ],

              if (isLecturer && item.status == ConsultationStatus.confirmed) ...[
                const SizedBox(height: 14),
                AppButton(
                  label: 'Selesaikan & Beri Catatan',
                  type: ButtonType.primary,
                  isFullWidth: true,
                  onPressed: () => _completeWithNotes(item.id),
                ),
              ],

              // Student Action Button
              if (isStudent && item.status == ConsultationStatus.requested) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                    onPressed: () => _updateStatus(item.id, 'CANCELLED'),
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: const Text('Batalkan Pengajuan', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
