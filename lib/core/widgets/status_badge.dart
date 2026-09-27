import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });

  factory StatusBadge.fromStatus(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
      case 'COMPLETED':
      case 'CONFIRMED':
        return StatusBadge(
          label: status == 'APPROVED'
              ? 'Disetujui'
              : (status == 'CONFIRMED' ? 'Terkonfirmasi' : 'Selesai'),
          backgroundColor: AppColors.successLight,
          textColor: AppColors.success,
          icon: Icons.check_circle_outline_rounded,
        );
      case 'SUBMITTED':
      case 'REQUESTED':
        return StatusBadge(
          label: status == 'SUBMITTED' ? 'Diajukan' : 'Menunggu Konfirmasi',
          backgroundColor: AppColors.infoLight,
          textColor: AppColors.info,
          icon: Icons.access_time_rounded,
        );
      case 'UNDER_REVIEW':
      case 'IN_PROGRESS':
        return StatusBadge(
          label: status == 'UNDER_REVIEW' ? 'Sedang Direview' : 'Sedang Berjalan',
          backgroundColor: AppColors.primaryLight,
          textColor: AppColors.primary,
          icon: Icons.sync_rounded,
        );
      case 'REVISION':
        return const StatusBadge(
          label: 'Perlu Revisi',
          backgroundColor: AppColors.warningLight,
          textColor: AppColors.warning,
          icon: Icons.edit_note_rounded,
        );
      case 'REJECTED':
      case 'CANCELLED':
        return StatusBadge(
          label: status == 'REJECTED' ? 'Ditolak' : 'Dibatalkan',
          backgroundColor: AppColors.dangerLight,
          textColor: AppColors.danger,
          icon: Icons.cancel_outlined,
        );
      case 'DRAFT':
      case 'NOT_STARTED':
      default:
        return StatusBadge(
          label: status == 'DRAFT' ? 'Draft' : 'Belum Mulai',
          backgroundColor: AppColors.slate100,
          textColor: AppColors.slate600,
          icon: Icons.circle_outlined,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
