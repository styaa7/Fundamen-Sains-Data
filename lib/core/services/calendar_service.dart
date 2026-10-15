import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/consultation_model.dart';

class CalendarService {
  /// Membuka aplikasi kalender bawaan handphone (Google Calendar / Apple Calendar / Samsung Calendar)
  /// dengan data jadwal bimbingan yang terisi otomatis.
  static Future<bool> addConsultationToDeviceCalendar(
    Consultation consultation, {
    Duration reminderDuration = const Duration(minutes: 30),
  }) async {
    try {
      final title = 'Bimbingan Skripsi: ${consultation.agenda.isNotEmpty ? consultation.agenda : "Konsultasi Skripsi"}';
      
      final buffer = StringBuffer();
      buffer.writeln('Agenda: ${consultation.agenda}');
      if (consultation.lecturerName != null && consultation.lecturerName!.isNotEmpty) {
        buffer.writeln('Dosen Pembimbing: ${consultation.lecturerName}');
      }
      if (consultation.studentName != null && consultation.studentName!.isNotEmpty) {
        buffer.writeln('Mahasiswa: ${consultation.studentName}');
      }
      buffer.writeln('Status: ${consultation.status.label}');
      if (consultation.note != null && consultation.note!.lecturerNotes.isNotEmpty) {
        buffer.writeln('Catatan: ${consultation.note!.lecturerNotes}');
      }

      final Event event = Event(
        title: title,
        description: buffer.toString(),
        location: 'Ruang Bimbingan Dosen / Online',
        startDate: consultation.scheduledStart,
        endDate: consultation.scheduledEnd,
        iosParams: IOSParams(
          reminder: reminderDuration,
        ),
        androidParams: const AndroidParams(
          emailInvites: [],
        ),
      );

      final success = await Add2Calendar.addEvent2Cal(event);
      return success;
    } catch (e) {
      debugPrint('Error adding event to phone calendar: $e');
      return false;
    }
  }

  /// Membuat link langsung ke Google Calendar Web (bisa dibuka di browser HP / aplikasi)
  /// sebagai alternatif jika perangkat membutuhkan link web langsung.
  static Future<bool> openGoogleCalendarWeb(Consultation consultation) async {
    try {
      final title = 'Bimbingan Skripsi: ${consultation.agenda.isNotEmpty ? consultation.agenda : "Konsultasi Skripsi"}';
      
      final buffer = StringBuffer();
      buffer.writeln('Agenda: ${consultation.agenda}');
      if (consultation.lecturerName != null && consultation.lecturerName!.isNotEmpty) {
        buffer.writeln('Dosen: ${consultation.lecturerName}');
      }
      if (consultation.studentName != null && consultation.studentName!.isNotEmpty) {
        buffer.writeln('Mahasiswa: ${consultation.studentName}');
      }
      buffer.writeln('Status: ${consultation.status.label}');

      // Format ISO 8601 UTC for Google Calendar: YYYYMMDDTHHMMSSZ
      final startUtc = consultation.scheduledStart.toUtc();
      final endUtc = consultation.scheduledEnd.toUtc();
      final format = DateFormat("yyyyMMdd'T'HHmmss'Z'");
      final dates = '${format.format(startUtc)}/${format.format(endUtc)}';

      final uri = Uri.https('calendar.google.com', '/calendar/render', {
        'action': 'TEMPLATE',
        'text': title,
        'dates': dates,
        'details': buffer.toString(),
        'location': 'Ruang Bimbingan / Online',
      });

      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error opening Google Calendar: $e');
      return false;
    }
  }
}
