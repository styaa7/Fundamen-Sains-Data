import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../models/consultation_model.dart';
import '../services/calendar_service.dart';
import '../utils/app_date_format.dart';

class CalendarSyncSheet extends StatelessWidget {
  final Consultation consultation;

  const CalendarSyncSheet({
    super.key,
    required this.consultation,
  });

  static Future<void> show(BuildContext context, Consultation consultation) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CalendarSyncSheet(consultation: consultation),
    );
  }

  static Future<void> syncDirectly(BuildContext context, Consultation consultation) async {
    final success = await CalendarService.addConsultationToDeviceCalendar(consultation);
    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: AppColors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text('Membuka aplikasi kalender HP... Silakan simpan jadwal.'),
              ),
            ],
          ),
        ),
      );
    } else {
      // If direct intent failed, fallback to show sheet with options
      if (context.mounted) {
        show(context, consultation);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = AppDateFormat.formatFull(consultation.scheduledStart);
    final timeStr =
        '${AppDateFormat.formatTime(consultation.scheduledStart)} - ${AppDateFormat.formatTime(consultation.scheduledEnd)} WIB';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: AppColors.slate300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sinkron ke Kalender HP',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.slate900,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Tambahkan pengingat ke aplikasi kalender handphone Anda',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.slate500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Jadwal Preview Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.slate50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.event, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 16, color: AppColors.slate500),
                      const SizedBox(width: 8),
                      Text(
                        timeStr,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.slate700,
                        ),
                      ),
                    ],
                  ),
                  if (consultation.agenda.isNotEmpty) ...[
                    const Divider(height: 16),
                    Text(
                      'Agenda: ${consultation.agenda}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.slate600,
                        height: 1.3,
                      ),
                    ),
                  ],
                  if (consultation.lecturerName != null && consultation.lecturerName!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Dosen: ${consultation.lecturerName}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate600,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Option 1: Native Phone Calendar (Google Calendar / Apple Calendar / Samsung)
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                final success = await CalendarService.addConsultationToDeviceCalendar(consultation);
                if (!context.mounted) return;

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.success,
                      content: Text('Aplikasi kalender HP berhasil dibuka. Tekan Simpan di kalender Anda.'),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.danger,
                      content: Text('Tidak dapat membuka aplikasi kalender bawaan HP.'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.phone_android_rounded, size: 20),
              label: const Text(
                'Buka di Aplikasi Kalender HP',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),

            const SizedBox(height: 10),

            // Option 2: Google Calendar Direct Web
            OutlinedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                final success = await CalendarService.openGoogleCalendarWeb(consultation);
                if (!context.mounted) return;

                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.danger,
                      content: Text('Gagal membuka Google Calendar via browser.'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.public_rounded, size: 18, color: AppColors.slate700),
              label: const Text(
                'Buka lewat Google Calendar (Web/Browser)',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.slate700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
