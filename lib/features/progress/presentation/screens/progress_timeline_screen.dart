import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_badge.dart';

class ProgressTimelineScreen extends ConsumerWidget {
  const ProgressTimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stages = [
      {'order': 1, 'name': 'Pengajuan Topik', 'status': 'COMPLETED', 'progress': 100, 'date': '15 Ags 2026'},
      {'order': 2, 'name': 'Proposal Skripsi', 'status': 'COMPLETED', 'progress': 100, 'date': '01 Sep 2026'},
      {'order': 3, 'name': 'Seminar Proposal', 'status': 'COMPLETED', 'progress': 100, 'date': '10 Sep 2026'},
      {'order': 4, 'name': 'Pengumpulan Data', 'status': 'COMPLETED', 'progress': 100, 'date': '20 Sep 2026'},
      {'order': 5, 'name': 'Analisis Data', 'status': 'IN_PROGRESS', 'progress': 60, 'date': 'Target: 05 Okt 2026'},
      {'order': 6, 'name': 'Penyusunan Naskah Skripsi', 'status': 'NOT_STARTED', 'progress': 0, 'date': 'Target: 20 Okt 2026'},
      {'order': 7, 'name': 'Seminar Hasil', 'status': 'NOT_STARTED', 'progress': 0, 'date': 'Target: 10 Nov 2026'},
      {'order': 8, 'name': 'Sidang Akhir Skripsi', 'status': 'NOT_STARTED', 'progress': 0, 'date': 'Target: 01 Des 2026'},
    ];

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: const Text('Monitoring Progress Skripsi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Gauge Card
            AppCard(
              backgroundColor: AppColors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Progres Kumulatif', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.slate900)),
                      Text('62.5%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: const LinearProgressIndicator(
                      value: 0.625,
                      minHeight: 10,
                      backgroundColor: AppColors.slate100,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('4 dari 8 Tahap Selesai', style: TextStyle(fontSize: 12, color: AppColors.slate500)),
                      Text('Sedang Berjalan: Tahap 5', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Timeline List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: stages.length,
              itemBuilder: (context, index) {
                final stage = stages[index];
                final isLast = index == stages.length - 1;
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
                            color: status == 'COMPLETED' ? AppColors.success.withOpacity(0.4) : AppColors.slate200,
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
                            if (status == 'IN_PROGRESS') {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppColors.primary,
                                  content: Text('Membuka upload dokumen & catatan untuk ${stage['name']}'),
                                ),
                              );
                            }
                          },
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
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
                                    stage['date'] as String,
                                    style: const TextStyle(fontSize: 11, color: AppColors.slate400),
                                  ),
                                ],
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
    );
  }
}
