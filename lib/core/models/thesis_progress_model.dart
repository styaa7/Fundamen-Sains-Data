enum StageStatus {
  notStarted,
  inProgress,
  completed;

  static StageStatus fromString(String? val) {
    switch (val?.toUpperCase()) {
      case 'IN_PROGRESS':
        return StageStatus.inProgress;
      case 'COMPLETED':
        return StageStatus.completed;
      case 'NOT_STARTED':
      default:
        return StageStatus.notStarted;
    }
  }

  String get label {
    switch (this) {
      case StageStatus.notStarted:
        return 'Belum Mulai';
      case StageStatus.inProgress:
        return 'Sedang Berjalan';
      case StageStatus.completed:
        return 'Selesai';
    }
  }

  String get name {
    switch (this) {
      case StageStatus.notStarted:
        return 'NOT_STARTED';
      case StageStatus.inProgress:
        return 'IN_PROGRESS';
      case StageStatus.completed:
        return 'COMPLETED';
    }
  }
}

class ThesisProgressStage {
  final String id;
  final String thesisId;
  final int stageOrder;
  final String stageName;
  final StageStatus status;
  final double progressPercentage;
  final DateTime? startDate;
  final DateTime? targetDate;
  final DateTime? completedDate;
  final String? studentNotes;
  final String? documentUrl;

  ThesisProgressStage({
    required this.id,
    required this.thesisId,
    required this.stageOrder,
    required this.stageName,
    required this.status,
    this.progressPercentage = 0.0,
    this.startDate,
    this.targetDate,
    this.completedDate,
    this.studentNotes,
    this.documentUrl,
  });

  factory ThesisProgressStage.fromJson(Map<String, dynamic> json) {
    return ThesisProgressStage(
      id: json['id'] as String,
      thesisId: json['thesis_id'] as String,
      stageOrder: json['stage_order'] as int,
      stageName: json['stage_name'] as String,
      status: StageStatus.fromString(json['status'] as String?),
      progressPercentage: (json['progress_percentage'] as num?)?.toDouble() ?? 0.0,
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date'] as String) : null,
      targetDate: json['target_date'] != null ? DateTime.parse(json['target_date'] as String) : null,
      completedDate: json['completed_date'] != null ? DateTime.parse(json['completed_date'] as String) : null,
      studentNotes: json['student_notes'] as String?,
      documentUrl: json['document_url'] as String?,
    );
  }
}

class Thesis {
  final String id;
  final String studentId;
  final String lecturerId;
  final String topicSubmissionId;
  final String title;
  final int currentStageOrder;
  final double overallProgressPercentage;
  final List<ThesisProgressStage> stages;

  Thesis({
    required this.id,
    required this.studentId,
    required this.lecturerId,
    required this.topicSubmissionId,
    required this.title,
    this.currentStageOrder = 1,
    this.overallProgressPercentage = 12.5,
    this.stages = const [],
  });

  factory Thesis.fromJson(Map<String, dynamic> json) {
    var rawStages = json['thesis_progress'] as List<dynamic>? ?? [];
    var parsedStages = rawStages
        .map((s) => ThesisProgressStage.fromJson(s as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.stageOrder.compareTo(b.stageOrder));

    return Thesis(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      lecturerId: json['lecturer_id'] as String,
      topicSubmissionId: json['topic_submission_id'] as String,
      title: json['title'] as String? ?? 'Skripsi',
      currentStageOrder: json['current_stage_order'] as int? ?? 1,
      overallProgressPercentage: (json['overall_progress_percentage'] as num?)?.toDouble() ?? 12.5,
      stages: parsedStages,
    );
  }
}
