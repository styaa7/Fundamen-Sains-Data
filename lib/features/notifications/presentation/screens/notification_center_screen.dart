import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = [
      {
        'title': 'Jadwal Konsultasi Dikonfirmasi',
        'message': 'Dosen pembimbing Dr. Ir. Hendra Wijaya mengonfirmasi jadwal bimbingan pada 28 September 2026, 10:00 WIB.',
        'time': '10 menit yang lalu',
        'is_read': false,
        'icon': Icons.event_available_rounded,
        'color': AppColors.success,
      },
      {
        'title': 'Topik Skripsi Disetujui! 🎉',
        'message': 'Pengajuan topik "Penerapan Algoritma Deep Learning..." telah disetujui. Tahap Proposal kini aktif.',
        'time': '2 jam yang lalu',
        'is_read': false,
        'icon': Icons.check_circle_outline_rounded,
        'color': AppColors.primary,
      },
      {
        'title': 'Catatan Konsultasi Baru',
        'message': 'Dosen telah menambahkan catatan dan tugas untuk sesi bimbingan Bab 3 Metodologi Penelitian.',
        'time': '1 hari yang lalu',
        'is_read': true,
        'icon': Icons.rate_review_outlined,
        'color': AppColors.slate500,
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: const Text('Pusat Notifikasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Tandai Dibaca', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final notif = notifications[index];
          final isRead = notif['is_read'] as bool;

          return AppCard(
            backgroundColor: isRead ? AppColors.white : AppColors.primaryLight.withOpacity(0.3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (notif['color'] as Color).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(notif['icon'] as IconData, size: 20, color: notif['color'] as Color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notif['title'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
                                color: AppColors.slate900,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notif['message'] as String,
                        style: const TextStyle(fontSize: 12, color: AppColors.slate600, height: 1.4),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notif['time'] as String,
                        style: const TextStyle(fontSize: 11, color: AppColors.slate400),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
