import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile_model.dart';
import '../models/topic_model.dart';
import '../models/consultation_model.dart';
import '../models/thesis_progress_model.dart';
import '../models/notification_model.dart';

class SupabaseService {
  final SupabaseClient? _client;
  SupabaseService([this._client]);

  SupabaseClient get client => _client ?? Supabase.instance.client;

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

  User? get currentUser {
    try {
      return client.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  // PROFILE
  Future<UserProfile?> fetchUserProfile(String userId) async {
    final response = await client
        .from('profiles')
        .select('*, students:students!students_id_fkey(*), lecturers:lecturers!lecturers_id_fkey(*)')
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

  Future<TopicSubmission?> fetchTopicById(String topicId) async {
    final response = await client
        .from('topic_submissions')
        .select('''
          *,
          student_profile:profiles!topic_submissions_student_id_fkey(full_name),
          lecturer_profile:profiles!topic_submissions_lecturer_id_fkey(full_name)
        ''')
        .eq('id', topicId)
        .maybeSingle();

    if (response == null) return null;
    return TopicSubmission.fromJson(response);
  }

  Future<List<Map<String, dynamic>>> fetchLecturers() async {
    final response = await client
        .from('profiles')
        .select('id, full_name, identifier_number, email')
        .eq('role', 'dosen');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> reviewTopic({
    required String topicId,
    required String action,
    String? feedback,
  }) async {
    try {
      await client.functions.invoke(
        'process-topic-review',
        body: {
          'topic_id': topicId,
          'action': action,
          'feedback': feedback,
        },
      );
      return;
    } catch (_) {
      // Direct database update fallback
      final topicResp = await client
          .from('topic_submissions')
          .select()
          .eq('id', topicId)
          .single();

      final studentId = topicResp['student_id'] as String;
      final lecturerId = topicResp['lecturer_id'] as String? ?? currentUser?.id ?? '';
      final title = topicResp['title'] as String;

      await client.from('topic_submissions').update({
        'status': action,
        'lecturer_feedback': feedback,
        'reviewed_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', topicId);

      // If approved, create thesis and initialize progress stages if not yet exists
      if (action == 'APPROVED') {
        final existingThesis = await client
            .from('theses')
            .select()
            .eq('student_id', studentId)
            .maybeSingle();

        if (existingThesis == null) {
          final newThesis = await client.from('theses').insert({
            'student_id': studentId,
            'lecturer_id': lecturerId,
            'topic_submission_id': topicId,
            'title': title,
            'current_stage_order': 2,
            'overall_progress_percentage': 25.0,
          }).select().single();

          final stages = [
            {'order': 1, 'name': 'Pengajuan Topik', 'status': 'COMPLETED', 'pct': 100.0},
            {'order': 2, 'name': 'Proposal Skripsi', 'status': 'IN_PROGRESS', 'pct': 50.0},
            {'order': 3, 'name': 'Seminar Proposal', 'status': 'NOT_STARTED', 'pct': 0.0},
            {'order': 4, 'name': 'Pengumpulan Data', 'status': 'NOT_STARTED', 'pct': 0.0},
            {'order': 5, 'name': 'Analisis Data', 'status': 'NOT_STARTED', 'pct': 0.0},
            {'order': 6, 'name': 'Penyusunan Naskah', 'status': 'NOT_STARTED', 'pct': 0.0},
            {'order': 7, 'name': 'Seminar Hasil', 'status': 'NOT_STARTED', 'pct': 0.0},
            {'order': 8, 'name': 'Sidang Akhir', 'status': 'NOT_STARTED', 'pct': 0.0},
          ];

          for (final st in stages) {
            await client.from('thesis_progress').insert({
              'thesis_id': newThesis['id'],
              'stage_order': st['order'],
              'stage_name': st['name'],
              'status': st['status'],
              'progress_percentage': st['pct'],
            });
          }
        }
      }

      // Notify student
      await client.from('notifications').insert({
        'user_id': studentId,
        'title': 'Hasil Review Topik Skripsi',
        'message': 'Topik skripsi Anda telah di-$action oleh dosen pembimbing.',
        'type': 'topic_review',
        'reference_id': topicId,
      });
    }
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
    try {
      final response = await client.functions.invoke(
        'book-consultation',
        body: {
          'lecturer_id': lecturerId,
          'scheduled_start': scheduledStart.toIso8601String(),
          'scheduled_end': scheduledEnd.toIso8601String(),
          'agenda': agenda,
        },
      );

      if (response.status == 201 || response.status == 200) {
        return;
      }
    } catch (_) {
      // Fallback: direct conflict check and database insert
    }

    final userId = currentUser?.id;
    if (userId == null) throw Exception('Sesi pengguna tidak valid');

    // Cek irisan jadwal pada dosen (Anti-bentrok)
    final conflicts = await client
        .from('consultations')
        .select('id')
        .eq('lecturer_id', lecturerId)
        .inFilter('status', ['CONFIRMED', 'REQUESTED'])
        .lt('scheduled_start', scheduledEnd.toIso8601String())
        .gt('scheduled_end', scheduledStart.toIso8601String());

    if ((conflicts as List).isNotEmpty) {
      throw Exception('Dosen telah memiliki agenda bimbingan pada rentang jam tersebut. Silakan pilih waktu lain.');
    }

    // Insert record
    final newConsultation = await client.from('consultations').insert({
      'student_id': userId,
      'lecturer_id': lecturerId,
      'scheduled_start': scheduledStart.toIso8601String(),
      'scheduled_end': scheduledEnd.toIso8601String(),
      'agenda': agenda,
      'status': 'REQUESTED',
    }).select().single();

    // Notifikasi untuk dosen
    try {
      await client.from('notifications').insert({
        'user_id': lecturerId,
        'title': 'Permintaan Konsultasi Baru',
        'message': 'Mahasiswa bimbingan mengajukan jadwal konsultasi untuk agenda: "$agenda"',
        'type': 'consultation',
        'reference_id': newConsultation['id'],
      });
    } catch (_) {}
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
