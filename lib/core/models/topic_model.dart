enum TopicStatus {
  draft,
  submitted,
  underReview,
  revision,
  approved,
  rejected,
  cancelled;

  static TopicStatus fromString(String? val) {
    switch (val?.toUpperCase()) {
      case 'SUBMITTED':
        return TopicStatus.submitted;
      case 'UNDER_REVIEW':
        return TopicStatus.underReview;
      case 'REVISION':
        return TopicStatus.revision;
      case 'APPROVED':
        return TopicStatus.approved;
      case 'REJECTED':
        return TopicStatus.rejected;
      case 'CANCELLED':
        return TopicStatus.cancelled;
      case 'DRAFT':
      default:
        return TopicStatus.draft;
    }
  }

  String get label {
    switch (this) {
      case TopicStatus.draft:
        return 'Draft';
      case TopicStatus.submitted:
        return 'Diajukan';
      case TopicStatus.underReview:
        return 'Sedang Direview';
      case TopicStatus.revision:
        return 'Perlu Revisi';
      case TopicStatus.approved:
        return 'Disetujui';
      case TopicStatus.rejected:
        return 'Ditolak';
      case TopicStatus.cancelled:
        return 'Dibatalkan / Diganti';
    }
  }

  String get name {
    switch (this) {
      case TopicStatus.draft:
        return 'DRAFT';
      case TopicStatus.submitted:
        return 'SUBMITTED';
      case TopicStatus.underReview:
        return 'UNDER_REVIEW';
      case TopicStatus.revision:
        return 'REVISION';
      case TopicStatus.approved:
        return 'APPROVED';
      case TopicStatus.rejected:
        return 'REJECTED';
      case TopicStatus.cancelled:
        return 'CANCELLED';
    }
  }
}

class TopicSubmission {
  final String id;
  final String studentId;
  final String? lecturerId;
  final String title;
  final String background;
  final String description;
  final String problemFormulation;
  final String researchObjective;
  final String methodology;
  final String? supportingDocumentUrl;
  final TopicStatus status;
  final int revisionCount;
  final String? lecturerFeedback;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined fields
  final String? studentName;
  final String? lecturerName;

  TopicSubmission({
    required this.id,
    required this.studentId,
    this.lecturerId,
    required this.title,
    required this.background,
    required this.description,
    required this.problemFormulation,
    required this.researchObjective,
    required this.methodology,
    this.supportingDocumentUrl,
    required this.status,
    this.revisionCount = 0,
    this.lecturerFeedback,
    this.reviewedAt,
    required this.createdAt,
    required this.updatedAt,
    this.studentName,
    this.lecturerName,
  });

  factory TopicSubmission.fromJson(Map<String, dynamic> json) {
    return TopicSubmission(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      lecturerId: json['lecturer_id'] as String?,
      title: json['title'] as String? ?? '',
      background: json['background'] as String? ?? '',
      description: json['description'] as String? ?? '',
      problemFormulation: json['problem_formulation'] as String? ?? '',
      researchObjective: json['research_objective'] as String? ?? '',
      methodology: json['methodology'] as String? ?? '',
      supportingDocumentUrl: json['supporting_document_url'] as String?,
      status: TopicStatus.fromString(json['status'] as String?),
      revisionCount: json['revision_count'] as int? ?? 0,
      lecturerFeedback: json['lecturer_feedback'] as String?,
      reviewedAt: json['reviewed_at'] != null ? DateTime.parse(json['reviewed_at'] as String) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
      studentName: json['student_profile']?['full_name'] as String?,
      lecturerName: json['lecturer_profile']?['full_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    String statusStr;
    switch (status) {
      case TopicStatus.underReview:
        statusStr = 'UNDER_REVIEW';
        break;
      default:
        statusStr = status.name.toUpperCase();
    }

    return {
      'student_id': studentId,
      'lecturer_id': lecturerId,
      'title': title,
      'background': background,
      'description': description,
      'problem_formulation': problemFormulation,
      'research_objective': researchObjective,
      'methodology': methodology,
      'supporting_document_url': supportingDocumentUrl,
      'status': statusStr,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
