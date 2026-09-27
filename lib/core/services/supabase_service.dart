import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile_model.dart';
import '../models/topic_model.dart';
import '../models/consultation_model.dart';
import '../models/thesis_progress_model.dart';
import '../models/notification_model.dart';

class SupabaseService {
  final SupabaseClient client = Supabase.instance.client;

  // AUTH
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  User? get currentUser => client.auth.currentUser;

  // PROFILE
  Future<UserProfile?> fetchUserProfile(String userId) async {
    final response = await client
        .from('profiles')
        .select('*, students(*), lecturers(*)')
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return UserProfile.fromJson(response);
  }

  // TOPIC SUBMISSIONS
  Future<List<TopicSubmission>> fetchTopics({String? studentId, String? lecturerId}) async {
    var query = client.from('topic_submissions').select('''
      *,
      student_profile:profiles!topic_submissions_student_id_fkey(full_name),
      lecturer_profile:profiles!topic_submissions_lecturer_id_fkey(full_name)
    ''');

    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }
    if (lecturerId != null) {
      query = query.eq('lecturer_id', lecturerId);
    }

    final response = await query.order('created_at', ascending: false);
    return (response as List).map((json) => TopicSubmission.fromJson(json)).toList();
  }

  Future<TopicSubmission> createOrUpdateTopic(TopicSubmission topic) async {
    if (topic.id.isEmpty) {
      final response = await client
          .from('topic_submissions')
          .insert(topic.toJson())
          .select()
          .single();
      return TopicSubmission.fromJson(response);
    } else {
      final response = await client
          .from('topic_submissions')
          .update(topic.toJson())
          .eq('id', topic.id)
          .select()
          .single();
      return TopicSubmission.fromJson(response);
    }
  }

  Future<void> reviewTopic({
    required String topicId,
    required String action,
    String? feedback,
  }) async {
    await client.functions.invoke(
      'process-topic-review',
      body: {
        'topic_id': topicId,
        'action': action,
        'feedback': feedback,
      },
    );
  }

  // CONSULTATIONS
  Future<List<Consultation>> fetchConsultations({String? studentId, String? lecturerId}) async {
    var query = client.from('consultations').select('''
      *,
      student_profile:profiles!consultations_student_id_fkey(full_name),
      lecturer_profile:profiles!consultations_lecturer_id_fkey(full_name),
      consultation_notes(*)
    ''');

    if (studentId != null) query = query.eq('student_id', studentId);
    if (lecturerId != null) query = query.eq('lecturer_id', lecturerId);

    final response = await query.order('scheduled_start', ascending: false);
    return (response as List).map((json) => Consultation.fromJson(json)).toList();
  }

  Future<void> bookConsultation({
    required String lecturerId,
    required DateTime scheduledStart,
    required DateTime scheduledEnd,
    required String agenda,
  }) async {
    final response = await client.functions.invoke(
      'book-consultation',
      body: {
        'lecturer_id': lecturerId,
        'scheduled_start': scheduledStart.toIso8601String(),
        'scheduled_end': scheduledEnd.toIso8601String(),
        'agenda': agenda,
      },
    );

    if (response.status != 201 && response.status != 200) {
      throw Exception(response.data?['message'] ?? 'Gagal membuat jadwal konsultasi');
    }
  }

  Future<void> updateConsultationStatus({
    required String consultationId,
    required String status,
    String? rejectionReason,
  }) async {
    await client.from('consultations').update({
      'status': status,
      if (rejectionReason != null) 'rejection_reason': rejectionReason,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', consultationId);
  }

  Future<void> saveConsultationNotes({
    required String consultationId,
    required String notes,
    String? feedback,
    String? actionItems,
  }) async {
    await client.from('consultation_notes').upsert({
      'consultation_id': consultationId,
      'lecturer_notes': notes,
      'feedback': feedback,
      'action_items': actionItems,
      'updated_at': DateTime.now().toIso8601String(),
    });

    await updateConsultationStatus(
      consultationId: consultationId,
      status: 'COMPLETED',
    );
  }

  // THESIS & PROGRESS
  Future<Thesis?> fetchStudentThesis(String studentId) async {
    final response = await client
        .from('theses')
        .select('*, thesis_progress(*)')
        .eq('student_id', studentId)
        .maybeSingle();

    if (response == null) return null;
    return Thesis.fromJson(response);
  }

  Future<void> updateStageProgress({
    required String stageId,
    String? notes,
    String? documentUrl,
  }) async {
    await client.from('thesis_progress').update({
      if (notes != null) 'student_notes': notes,
      if (documentUrl != null) 'document_url': documentUrl,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', stageId);
  }

  // NOTIFICATIONS
  Future<List<AppNotification>> fetchNotifications(String userId) async {
    final response = await client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => AppNotification.fromJson(json)).toList();
  }

  Future<void> markNotificationAsRead(String notifId) async {
    await client.from('notifications').update({'is_read': true}).eq('id', notifId);
  }
}
