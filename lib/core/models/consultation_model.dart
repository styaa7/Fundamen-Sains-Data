enum ConsultationStatus {
  requested,
  confirmed,
  rejected,
  completed,
  cancelled;

  static ConsultationStatus fromString(String? val) {
    switch (val?.toUpperCase()) {
      case 'CONFIRMED':
        return ConsultationStatus.confirmed;
      case 'REJECTED':
        return ConsultationStatus.rejected;
      case 'COMPLETED':
        return ConsultationStatus.completed;
      case 'CANCELLED':
        return ConsultationStatus.cancelled;
      case 'REQUESTED':
      default:
        return ConsultationStatus.requested;
    }
  }

  String get label {
    switch (this) {
      case ConsultationStatus.requested:
        return 'Menunggu Konfirmasi';
      case ConsultationStatus.confirmed:
        return 'Terkonfirmasi';
      case ConsultationStatus.rejected:
        return 'Ditolak';
      case ConsultationStatus.completed:
        return 'Selesai';
      case ConsultationStatus.cancelled:
        return 'Dibatalkan';
    }
  }

  String get name {
    switch (this) {
      case ConsultationStatus.requested:
        return 'REQUESTED';
      case ConsultationStatus.confirmed:
        return 'CONFIRMED';
      case ConsultationStatus.rejected:
        return 'REJECTED';
      case ConsultationStatus.completed:
        return 'COMPLETED';
      case ConsultationStatus.cancelled:
        return 'CANCELLED';
    }
  }
}

class ConsultationNote {
  final String id;
  final String consultationId;
  final String lecturerNotes;
  final String? feedback;
  final String? actionItems;
  final DateTime createdAt;

  ConsultationNote({
    required this.id,
    required this.consultationId,
    required this.lecturerNotes,
    this.feedback,
    this.actionItems,
    required this.createdAt,
  });

  factory ConsultationNote.fromJson(Map<String, dynamic> json) {
    return ConsultationNote(
      id: json['id'] as String,
      consultationId: json['consultation_id'] as String,
      lecturerNotes: json['lecturer_notes'] as String? ?? '',
      feedback: json['feedback'] as String?,
      actionItems: json['action_items'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    );
  }
}

class Consultation {
  final String id;
  final String studentId;
  final String lecturerId;
  final DateTime scheduledStart;
  final DateTime scheduledEnd;
  final String agenda;
  final ConsultationStatus status;
  final String? rejectionReason;
  final DateTime createdAt;
  
  // Joined relations
  final String? studentName;
  final String? lecturerName;
  final ConsultationNote? note;

  Consultation({
    required this.id,
    required this.studentId,
    required this.lecturerId,
    required this.scheduledStart,
    required this.scheduledEnd,
    required this.agenda,
    required this.status,
    this.rejectionReason,
    required this.createdAt,
    this.studentName,
    this.lecturerName,
    this.note,
  });

  factory Consultation.fromJson(Map<String, dynamic> json) {
    return Consultation(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      lecturerId: json['lecturer_id'] as String,
      scheduledStart: DateTime.parse(json['scheduled_start'] as String),
      scheduledEnd: DateTime.parse(json['scheduled_end'] as String),
      agenda: json['agenda'] as String? ?? '',
      status: ConsultationStatus.fromString(json['status'] as String?),
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      studentName: json['student_profile']?['full_name'] as String?,
      lecturerName: json['lecturer_profile']?['full_name'] as String?,
      note: json['consultation_notes'] != null && (json['consultation_notes'] as List).isNotEmpty
          ? ConsultationNote.fromJson(json['consultation_notes'][0] as Map<String, dynamic>)
          : null,
    );
  }
}
