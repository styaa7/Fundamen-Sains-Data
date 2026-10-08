import 'package:intl/intl.dart';

class AppDateFormat {
  static String formatFull(DateTime date) {
    try {
      return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
    } catch (_) {
      try {
        return DateFormat('EEEE, d MMMM yyyy').format(date);
      } catch (_) {
        return '${date.day}/${date.month}/${date.year}';
      }
    }
  }

  static String formatMedium(DateTime date) {
    try {
      return DateFormat('d MMMM yyyy', 'id_ID').format(date);
    } catch (_) {
      try {
        return DateFormat('d MMMM yyyy').format(date);
      } catch (_) {
        return '${date.day}/${date.month}/${date.year}';
      }
    }
  }

  static String formatDateTime(DateTime date) {
    try {
      return DateFormat('d MMMM yyyy, HH:mm', 'id_ID').format(date);
    } catch (_) {
      try {
        return DateFormat('d MMMM yyyy, HH:mm').format(date);
      } catch (_) {
        return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
      }
    }
  }

  static String formatTime(DateTime date) {
    try {
      return DateFormat('HH:mm').format(date);
    } catch (_) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }
}
