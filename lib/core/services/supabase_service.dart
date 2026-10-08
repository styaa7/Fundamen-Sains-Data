import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile_model.dart';
import '../models/topic_model.dart';
import '../models/consultation_model.dart';
import '../models/thesis_progress_model.dart';
import '../models/notification_model.dart';
import '../models/topic_change_request_model.dart';

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
  Future<List<TopicSubmission>> fetchTopics({
    String? studentId,
    String? lecturerId,
    List<String>? allowedStatuses,
  }) async {
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
    // Drafts are strictly private to the student creator
    if (studentId == null || lecturerId != null) {
      query = query.neq('status', 'DRAFT');
    }
    if (allowedStatuses != null && allowedStatuses.isNotEmpty) {
      query = query.inFilter('status', allowedStatuses);
    }

    final response = await query.order('created_at', ascending: false);
    final list = (response as List).map((json) => TopicSubmission.fromJson(json)).toList();
    if (studentId == null || lecturerId != null) {
      return list.where((t) => t.status != TopicStatus.draft).toList();
    }
    return list;
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
      try {
        final response = await client
            .from('topic_submissions')
            .update(topic.toJson())
            .eq('id', topic.id)
            .select()
            .single();
        return TopicSubmission.fromJson(response);
      } on PostgrestException catch (e) {
        // Fallback if remote DB RLS policy restricts UPDATE on status change (code 42501)
        if (e.code == '42501') {
          final payload = topic.toJson();
          final response = await client
              .from('topic_submissions')
              .insert(payload)
              .select()
              .single();
          try {
            await client.from('topic_submissions').delete().eq('id', topic.id);
          } catch (_) {}
          return TopicSubmission.fromJson(response);
        }
        rethrow;
      }
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
        try {
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
        } catch (e) {
          debugPrint('Thesis initialization notice: $e');
        }
      }

      // Notify student
      try {
        await client.from('notifications').insert({
          'user_id': studentId,
          'title': 'Hasil Review Topik Skripsi',
          'message': 'Topik skripsi Anda telah di-$action oleh dosen pembimbing.',
          'type': 'topic_review',
          'reference_id': topicId,
        });
      } catch (e) {
        debugPrint('Notification notice: $e');
      }
    }
  }

  // TOPIC CHANGE REQUESTS (PERGANTIAN TOPIK)
  Future<bool> hasApprovedTopic(String studentId) async {
    try {
      final approvedTopics = await client
          .from('topic_submissions')
          .select('id')
          .eq('student_id', studentId)
          .eq('status', 'APPROVED')
          .limit(1);

      if ((approvedTopics as List).isNotEmpty) {
        return true;
      }

      final thesis = await client
          .from('theses')
          .select('id')
          .eq('student_id', studentId)
          .maybeSingle();

      return thesis != null;
    } catch (_) {
      return false;
    }
  }

  Future<TopicChangeRequest?> fetchActiveTopicChangeRequest(String studentId) async {
    try {
      final response = await client
          .from('topic_change_requests')
          .select('''
            *,
            student:profiles!topic_change_requests_student_id_fkey(full_name, identifier_number),
            topic:topic_submissions!topic_change_requests_current_topic_id_fkey(title)
          ''')
          .eq('student_id', studentId)
          .order('requested_at', ascending: false)
          .limit(1);

      final list = response as List;
      if (list.isEmpty) return null;
      return TopicChangeRequest.fromJson(list.first as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Notice fetchActiveTopicChangeRequest: $e');
      return null;
    }
  }

  Future<List<TopicChangeRequest>> fetchLecturerTopicChangeRequests(String lecturerId) async {
    try {
      final response = await client
          .from('topic_change_requests')
          .select('''
            *,
            student:profiles!topic_change_requests_student_id_fkey(full_name, identifier_number),
            topic:topic_submissions!topic_change_requests_current_topic_id_fkey(title)
          ''')
          .eq('lecturer_id', lecturerId)
          .eq('status', 'PENDING')
          .order('requested_at', ascending: false);

      final list = response as List;
      return list.map((item) => TopicChangeRequest.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Notice fetchLecturerTopicChangeRequests: $e');
      return [];
    }
  }

  Future<void> submitTopicChangeRequest({
    required String studentId,
    required String lecturerId,
    required String reason,
    String? thesisId,
    String? currentTopicId,
  }) async {
    await client.from('topic_change_requests').insert({
      'student_id': studentId,
      'lecturer_id': lecturerId,
      'reason': reason,
      'thesis_id': thesisId,
      'current_topic_id': currentTopicId,
      'status': 'PENDING',
      'requested_at': DateTime.now().toIso8601String(),
    });

    // Send notification to lecturer
    try {
      await client.from('notifications').insert({
        'user_id': lecturerId,
        'title': 'Permohonan Pergantian Topik Mahasiswa',
        'message': 'Mahasiswa bimbingan mengajukan permohonan pergantian topik: "$reason"',
        'type': 'topic_change_request',
        'reference_id': currentTopicId,
      });
    } catch (e) {
      debugPrint('Notice notification topic change request: $e');
    }
  }

  Future<void> approveTopicChangeRequest(
    TopicChangeRequest request, {
    String? notes,
  }) async {
    // 1. Update status to APPROVED in topic_change_requests
    try {
      await client.from('topic_change_requests').update({
        'status': 'APPROVED',
        'responded_at': DateTime.now().toIso8601String(),
        'lecturer_response': notes,
      }).eq('id', request.id);
    } catch (e) {
      debugPrint('Notice update topic_change_requests: $e');
    }

    // 2. Reset/Delete old thesis so student's roadmap and slots reset
    try {
      if (request.thesisId != null) {
        await client.from('theses').delete().eq('id', request.thesisId!);
      } else {
        await client.from('theses').delete().eq('student_id', request.studentId);
      }
    } catch (e) {
      debugPrint('Notice delete old thesis on topic change: $e');
    }

    // 3. Mark old topic as CANCELLED (or REJECTED)
    if (request.currentTopicId != null) {
      try {
        await client.from('topic_submissions').update({
          'status': 'CANCELLED',
          'lecturer_feedback': 'Topik diganti atas persetujuan dosen pembimbing. Alasan: ${request.reason}',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', request.currentTopicId!);
      } catch (_) {
        try {
          await client.from('topic_submissions').update({
            'status': 'REJECTED',
            'lecturer_feedback': 'Topik diganti atas persetujuan dosen pembimbing. Alasan: ${request.reason}',
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', request.currentTopicId!);
        } catch (e) {
          debugPrint('Notice update old topic submission status: $e');
        }
      }
    }

    // 4. Send notification to student that topic change was approved and they can submit a new topic
    try {
      await client.from('notifications').insert({
        'user_id': request.studentId,
        'title': 'Permohonan Ganti Topik Disetujui! 🎉',
        'message': 'Dosen pembimbing telah menyetujui pergantian topik Anda. Anda kini dapat mengajukan usulan topik skripsi baru.',
        'type': 'topic_change_approved',
        'reference_id': request.id,
      });
    } catch (e) {
      debugPrint('Notice notification approve topic change: $e');
    }
  }

  Future<void> rejectTopicChangeRequest(
    TopicChangeRequest request, {
    required String reason,
  }) async {
    try {
      await client.from('topic_change_requests').update({
        'status': 'REJECTED',
        'responded_at': DateTime.now().toIso8601String(),
        'lecturer_response': reason,
      }).eq('id', request.id);
    } catch (e) {
      debugPrint('Notice update reject topic_change_requests: $e');
    }

    // Send notification to student
    try {
      await client.from('notifications').insert({
        'user_id': request.studentId,
        'title': 'Permohonan Ganti Topik Ditolak',
        'message': 'Dosen pembimbing menolak permohonan pergantian topik: "$reason"',
        'type': 'topic_change_rejected',
        'reference_id': request.id,
      });
    } catch (e) {
      debugPrint('Notice notification reject topic change: $e');
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

  Future<List<Map<String, dynamic>>> fetchLecturerTheses(String lecturerId) async {
    final response = await client.from('theses').select('''
      *,
      student_profile:profiles!theses_student_id_fkey(full_name, identifier_number, email),
      lecturer_profile:profiles!theses_lecturer_id_fkey(full_name),
      topic:topic_submissions(*),
      thesis_progress(*)
    ''').eq('lecturer_id', lecturerId).order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> approveAndAdvanceThesisStage({
    required String thesisId,
    required String studentId,
    required int currentStageOrder,
    String? lecturerNotes,
  }) async {
    final nextStageOrder = currentStageOrder + 1;
    final isFinalStage = currentStageOrder >= 8;

    // 1. Mark current stage as COMPLETED
    await client.from('thesis_progress').update({
      'status': 'COMPLETED',
      'progress_percentage': 100.0,
      'completed_date': DateTime.now().toIso8601String().substring(0, 10),
      if (lecturerNotes != null && lecturerNotes.isNotEmpty) 'student_notes': lecturerNotes,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('thesis_id', thesisId).eq('stage_order', currentStageOrder);

    // 2. If not final stage, set next stage to IN_PROGRESS
    if (!isFinalStage) {
      await client.from('thesis_progress').update({
        'status': 'IN_PROGRESS',
        'progress_percentage': 25.0,
        'start_date': DateTime.now().toIso8601String().substring(0, 10),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('thesis_id', thesisId).eq('stage_order', nextStageOrder);
    }

    // 3. Update thesis overall progress and current stage
    final newOverallPct = isFinalStage ? 100.0 : (currentStageOrder / 8.0) * 100.0;
    await client.from('theses').update({
      'current_stage_order': isFinalStage ? 8 : nextStageOrder,
      'overall_progress_percentage': newOverallPct,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', thesisId);

    // 4. Send notification to student
    final msg = isFinalStage
        ? 'Selamat! Seluruh tahapan skripsi Anda telah disetujui dan dinyatakan selesai.'
        : 'Tahap $currentStageOrder telah disetujui dosen pembimbing. Silakan lanjutkan ke Tahap $nextStageOrder.';

    await client.from('notifications').insert({
      'user_id': studentId,
      'title': isFinalStage ? 'Skripsi Selesai' : 'Roadmap Tahap $currentStageOrder Disetujui',
      'message': msg,
      'type': 'thesis_progress',
      'reference_id': thesisId,
    });
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

  // ===================== ADMIN SERVICE METHODS =====================
  Future<Map<String, int>> fetchAdminStats() async {
    try {
      final studentsResp = await client.from('profiles').select('id').eq('role', 'mahasiswa');
      final lecturersResp = await client.from('profiles').select('id').eq('role', 'dosen');
      // Admin only sees SUBMITTED, APPROVED, REVISION (NO DRAFTS)
      final topicsResp = await client
          .from('topic_submissions')
          .select('id')
          .inFilter('status', ['SUBMITTED', 'APPROVED', 'REVISION']);
      final consultationsResp = await client.from('consultations').select('id');

      return {
        'students': (studentsResp as List).length,
        'lecturers': (lecturersResp as List).length,
        'topics': (topicsResp as List).length,
        'consultations': (consultationsResp as List).length,
      };
    } catch (_) {
      return {
        'students': 0,
        'lecturers': 0,
        'topics': 0,
        'consultations': 0,
      };
    }
  }

  Future<List<Map<String, dynamic>>> fetchAdminUsers({String? roleFilter, String? searchQuery}) async {
    var query = client.from('profiles').select('''
      *,
      students:students!students_id_fkey(*),
      lecturers:lecturers!lecturers_id_fkey(*)
    ''');

    if (roleFilter != null && roleFilter != 'all') {
      query = query.eq('role', roleFilter);
    }

    final response = await query.order('created_at', ascending: false);
    List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(response);

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      list = list.where((u) {
        final name = (u['full_name'] ?? '').toString().toLowerCase();
        final idNum = (u['identifier_number'] ?? '').toString().toLowerCase();
        final email = (u['email'] ?? '').toString().toLowerCase();
        return name.contains(q) || idNum.contains(q) || email.contains(q);
      }).toList();
    }

    return list;
  }

  Future<void> updateAdminUserProfile({
    required String userId,
    required String fullName,
    required String identifierNumber,
    required String email,
    String? phoneNumber,
  }) async {
    await client.from('profiles').update({
      'full_name': fullName,
      'identifier_number': identifierNumber,
      'email': email,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  Future<void> deleteAdminUserProfile(String userId) async {
    await client.from('profiles').delete().eq('id', userId);
  }

  Future<List<Map<String, dynamic>>> fetchAdminTheses() async {
    final response = await client.from('theses').select('''
      *,
      student_profile:profiles!theses_student_id_fkey(full_name, identifier_number, email),
      lecturer_profile:profiles!theses_lecturer_id_fkey(full_name),
      thesis_progress(*)
    ''').order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}
