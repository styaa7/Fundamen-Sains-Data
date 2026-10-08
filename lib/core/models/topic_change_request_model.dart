class TopicChangeRequest {
  final String id;
  final String studentId;
  final String lecturerId;
  final String? thesisId;
  final String? currentTopicId;
  final String reason;
  final String status; // 'PENDING', 'APPROVED', 'REJECTED'
  final String? lecturerResponse;
  final DateTime requestedAt;
  final DateTime? respondedAt;

  // Joined presentation fields
  final String? studentName;
  final String? studentNim;
  final String? currentTopicTitle;

  TopicChangeRequest({
    required this.id,
    required this.studentId,
    required this.lecturerId,
    this.thesisId,
    this.currentTopicId,
    required this.reason,
    this.status = 'PENDING',
    this.lecturerResponse,
    required this.requestedAt,
    this.respondedAt,
    this.studentName,
    this.studentNim,
    this.currentTopicTitle,
  });

  bool get isPending => status == 'PENDING';
  bool get isApproved => status == 'APPROVED';
  bool get isRejected => status == 'REJECTED';

  factory TopicChangeRequest.fromJson(Map<String, dynamic> json) {
    final studentProfile = json['student'] as Map<String, dynamic>?;
    final topicData = json['topic'] as Map<String, dynamic>?;

    return TopicChangeRequest(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      lecturerId: json['lecturer_id'] as String,
      thesisId: json['thesis_id'] as String?,
      currentTopicId: json['current_topic_id'] as String?,
      reason: json['reason'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      lecturerResponse: json['lecturer_response'] as String?,
      requestedAt: json['requested_at'] != null
          ? DateTime.parse(json['requested_at'] as String)
          : DateTime.now(),
      respondedAt: json['responded_at'] != null
          ? DateTime.parse(json['responded_at'] as String)
          : null,
      studentName: studentProfile?['full_name'] as String?,
      studentNim: studentProfile?['identifier_number'] as String?,
      currentTopicTitle: topicData?['title'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'lecturer_id': lecturerId,
      if (thesisId != null) 'thesis_id': thesisId,
      if (currentTopicId != null) 'current_topic_id': currentTopicId,
      'reason': reason,
      'status': status,
      if (lecturerResponse != null) 'lecturer_response': lecturerResponse,
      'requested_at': requestedAt.toIso8601String(),
      if (respondedAt != null) 'responded_at': respondedAt!.toIso8601String(),
    };
  }
}
