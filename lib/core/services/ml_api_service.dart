import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service to communicate with the SkripsiFlow ML API (FastAPI backend).
///
/// Base URL defaults to localhost:8000 for development.
/// Change [baseUrl] in production deployment.
class MlApiService {
  // For Android emulator use 10.0.2.2, for iOS simulator use localhost
  // For physical device, use the machine's IP on the local network
  static const String _defaultBaseUrl = 'http://localhost:8000';

  final String baseUrl;
  final http.Client _client;

  MlApiService({
    this.baseUrl = _defaultBaseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  // ===========================================================================
  // 1. LINEAR REGRESSION — Prediksi Waktu Penyelesaian
  // ===========================================================================

  /// Predict estimated days to complete thesis.
  Future<CompletionTimePrediction> predictCompletionTime({
    required int currentStageOrder,
    required double overallProgressPercentage,
    required int daysSinceStart,
    required int totalConsultations,
    required int totalRevisions,
    required double avgDaysPerStage,
  }) async {
    final response = await _post('/predict/completion-time', {
      'current_stage_order': currentStageOrder,
      'overall_progress_percentage': overallProgressPercentage,
      'days_since_start': daysSinceStart,
      'total_consultations': totalConsultations,
      'total_revisions': totalRevisions,
      'avg_days_per_stage': avgDaysPerStage,
    });

    return CompletionTimePrediction.fromJson(response['data']);
  }

  // ===========================================================================
  // 2. LOGISTIC REGRESSION — Prediksi Risiko Keterlambatan
  // ===========================================================================

  /// Predict if student will complete thesis on time.
  Future<OntimeRiskPrediction> predictOntimeRisk({
    required int currentStageOrder,
    required double overallProgressPercentage,
    required int daysSinceStart,
    required double consultationFrequency,
    required int revisionCount,
    required double stageCompletionRate,
  }) async {
    final response = await _post('/predict/ontime-risk', {
      'current_stage_order': currentStageOrder,
      'overall_progress_percentage': overallProgressPercentage,
      'days_since_start': daysSinceStart,
      'consultation_frequency': consultationFrequency,
      'revision_count': revisionCount,
      'stage_completion_rate': stageCompletionRate,
    });

    return OntimeRiskPrediction.fromJson(response['data']);
  }

  // ===========================================================================
  // 3. NAIVE BAYES — Pra-Evaluasi Kualitas Topik
  // ===========================================================================

  /// Predict topic quality (APPROVED/REVISION/REJECTED).
  Future<TopicQualityPrediction> predictTopicQuality({
    required String title,
    required String background,
    required String problemFormulation,
    required String methodology,
  }) async {
    final response = await _post('/predict/topic-quality', {
      'title': title,
      'background': background,
      'problem_formulation': problemFormulation,
      'methodology': methodology,
    });

    return TopicQualityPrediction.fromJson(response['data']);
  }

  // ===========================================================================
  // 4. SVM — Kategorisasi Bidang Topik
  // ===========================================================================

  /// Predict topic category and recommend lecturers.
  Future<TopicCategoryPrediction> predictTopicCategory({
    required String title,
    required String description,
    String? methodology,
  }) async {
    final response = await _post('/predict/topic-category', {
      'title': title,
      'description': description,
      'methodology': methodology ?? '',
    });

    return TopicCategoryPrediction.fromJson(response['data']);
  }

  // ===========================================================================
  // 5. MODEL METRICS
  // ===========================================================================

  /// Get training metrics for all models.
  Future<Map<String, dynamic>> getModelMetrics() async {
    final response = await _get('/models/metrics');
    return response['data'] as Map<String, dynamic>;
  }

  // ===========================================================================
  // HTTP Helpers
  // ===========================================================================

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw MlApiException(
          'API Error ${response.statusCode}: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is MlApiException) rethrow;
      throw MlApiException('Connection error: $e');
    }
  }

  Future<Map<String, dynamic>> _get(String path) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw MlApiException(
          'API Error ${response.statusCode}: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is MlApiException) rethrow;
      throw MlApiException('Connection error: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}

// =============================================================================
// Response Models
// =============================================================================

class CompletionTimePrediction {
  final double predictedDays;
  final double predictedWeeks;
  final String model;

  CompletionTimePrediction({
    required this.predictedDays,
    required this.predictedWeeks,
    required this.model,
  });

  factory CompletionTimePrediction.fromJson(Map<String, dynamic> json) {
    return CompletionTimePrediction(
      predictedDays: (json['predicted_days_to_complete'] as num).toDouble(),
      predictedWeeks: (json['predicted_weeks'] as num).toDouble(),
      model: json['model'] as String,
    );
  }
}

class OntimeRiskPrediction {
  final String prediction;
  final double probabilityOnTime;
  final double probabilityLate;
  final String riskLevel;
  final String riskLabel;
  final String model;

  OntimeRiskPrediction({
    required this.prediction,
    required this.probabilityOnTime,
    required this.probabilityLate,
    required this.riskLevel,
    required this.riskLabel,
    required this.model,
  });

  factory OntimeRiskPrediction.fromJson(Map<String, dynamic> json) {
    return OntimeRiskPrediction(
      prediction: json['prediction'] as String,
      probabilityOnTime: (json['probability_on_time'] as num).toDouble(),
      probabilityLate: (json['probability_late'] as num).toDouble(),
      riskLevel: json['risk_level'] as String,
      riskLabel: json['risk_label'] as String,
      model: json['model'] as String,
    );
  }
}

class TopicQualityPrediction {
  final String predictedStatus;
  final String predictedLabel;
  final Map<String, double> probabilities;
  final String feedback;
  final String model;

  TopicQualityPrediction({
    required this.predictedStatus,
    required this.predictedLabel,
    required this.probabilities,
    required this.feedback,
    required this.model,
  });

  factory TopicQualityPrediction.fromJson(Map<String, dynamic> json) {
    final probs = (json['probabilities'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, (v as num).toDouble()),
    );
    return TopicQualityPrediction(
      predictedStatus: json['predicted_status'] as String,
      predictedLabel: json['predicted_label'] as String,
      probabilities: probs,
      feedback: json['feedback'] as String,
      model: json['model'] as String,
    );
  }
}

class TopicCategoryPrediction {
  final String predictedCategory;
  final double confidence;
  final Map<String, double> probabilities;
  final List<Map<String, dynamic>> top3Categories;
  final List<String> recommendedLecturers;
  final String model;

  TopicCategoryPrediction({
    required this.predictedCategory,
    required this.confidence,
    required this.probabilities,
    required this.top3Categories,
    required this.recommendedLecturers,
    required this.model,
  });

  factory TopicCategoryPrediction.fromJson(Map<String, dynamic> json) {
    final probs = (json['probabilities'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, (v as num).toDouble()),
    );
    final top3 = (json['top_3_categories'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final lecturers = (json['recommended_lecturers'] as List)
        .map((e) => e as String)
        .toList();

    return TopicCategoryPrediction(
      predictedCategory: json['predicted_category'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      probabilities: probs,
      top3Categories: top3,
      recommendedLecturers: lecturers,
      model: json['model'] as String,
    );
  }
}

// =============================================================================
// Custom Exception
// =============================================================================

class MlApiException implements Exception {
  final String message;
  final int? statusCode;

  MlApiException(this.message, {this.statusCode});

  @override
  String toString() => 'MlApiException: $message';
}
