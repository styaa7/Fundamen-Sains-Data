import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_badge.dart';

class ConsultationListScreen extends ConsumerStatefulWidget {
  const ConsultationListScreen({super.key});

  @override
  ConsumerState<ConsultationListScreen> createState() => _ConsultationListScreenState();
}

class _ConsultationListScreenState extends ConsumerState<ConsultationListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          tabs: const [
            Tab(text: 'Mendatang (Upcoming)'),
            Tab(text: 'Riwayat (History)'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/student/consultation/book'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: AppColors.white),
        label: const Text('Ajukan Konsultasi', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600)),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Upcoming
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ConsultationCard(
                date: 'Senin, 28 September 2026',
                time: '10:00 - 11:00 WIB',
                lecturer: 'Dr. Ir. Hendra Wijaya, M.T.',
                agenda: 'Evaluasi Arsitektur Algoritma CNN dan Hasil Evaluasi Bab 4',
                status: 'CONFIRMED',
                notes: null,
              ),
              const SizedBox(height: 12),
              _ConsultationCard(
                date: 'Kamis, 01 Oktober 2026',
                time: '14:00 - 15:00 WIB',
                lecturer: 'Dr. Ir. Hendra Wijaya, M.T.',
                agenda: 'Diskusi Naskah Publikasi Ilmiah & Draf Naskah Final',
                status: 'REQUESTED',
                notes: null,
              ),
            ],
          ),

          // Tab 2: History
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ConsultationCard(
                date: 'Jumat, 18 September 2026',
                time: '09:00 - 10:00 WIB',
                lecturer: 'Dr. Ir. Hendra Wijaya, M.T.',
                agenda: 'Review Bab 3 Metodologi dan Kuisioner Validasi Ahli',
                status: 'COMPLETED',
                notes: 'Format instrumen sudah baik. Tambahkan 2 responden ahli sebelum implementasi.',
              ),
              const SizedBox(height: 12),
              _ConsultationCard(
                date: 'Rabu, 02 September 2026',
                time: '13:00 - 14:00 WIB',
                lecturer: 'Dr. Ir. Hendra Wijaya, M.T.',
                agenda: 'Bimbingan Bab 1 Latar Belakang & Identifikasi Masalah',
                status: 'COMPLETED',
                notes: 'Latar belakang diperkuat dengan data statistik dari BPS tahun terakhir.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConsultationCard extends StatelessWidget {
  final String date;
  final String time;
  final String lecturer;
  final String agenda;
  final String status;
  final String? notes;

  const _ConsultationCard({
    required this.date,
    required this.time,
    required this.lecturer,
    required this.agenda,
    required this.status,
    this.notes,
  });

  @override
  Widget build(BuildContext context) {
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
                  Text(date, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.slate900)),
                ],
              ),
              StatusBadge.fromStatus(status),
            ],
          ),
          const SizedBox(height: 6),
          Text(time, style: const TextStyle(fontSize: 12, color: AppColors.slate500)),
          const Divider(height: 20),
          Text('Dosen Pembimbing: $lecturer', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.slate700)),
          const SizedBox(height: 6),
          Text('Agenda: $agenda', style: const TextStyle(fontSize: 12, color: AppColors.slate600, height: 1.4)),
          if (notes != null) ...[
            const SizedBox(height: 12),
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
                  const Text('Catatan & Feedback Dosen:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.slate700)),
                  const SizedBox(height: 4),
                  Text(notes!, style: const TextStyle(fontSize: 12, color: AppColors.slate600, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
