class Assessment {
  final int id;
  final String assessmentId;
  final int sessionId;
  final String traineeId;
  final String rubricId;
  final String rubricVersion;
  final List<int> evidenceEventIds;
  final double? score;
  final double? maxScore;
  final String outcome;
  final String? scoringExplanation;
  final String createdBy;
  final DateTime createdAt;

  Assessment({
    required this.id,
    required this.assessmentId,
    required this.sessionId,
    required this.traineeId,
    required this.rubricId,
    required this.rubricVersion,
    required this.evidenceEventIds,
    this.score,
    this.maxScore,
    required this.outcome,
    this.scoringExplanation,
    required this.createdBy,
    required this.createdAt,
  });

  factory Assessment.fromJson(Map<String, dynamic> json) {
    return Assessment(
      id: json['id'] as int,
      assessmentId: json['assessment_id'] as String,
      sessionId: json['session_id'] as int,
      traineeId: json['trainee_id'] as String,
      rubricId: json['rubric_id'] as String,
      rubricVersion: json['rubric_version'] as String,
      evidenceEventIds:
          (json['evidence_event_ids'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      score: json['score'] as double?,
      maxScore: json['max_score'] as double?,
      outcome: json['outcome'] as String,
      scoringExplanation: json['scoring_explanation'] as String?,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assessment_id': assessmentId,
      'session_id': sessionId,
      'trainee_id': traineeId,
      'rubric_id': rubricId,
      'rubric_version': rubricVersion,
      'evidence_event_ids': evidenceEventIds,
      'score': score,
      'max_score': maxScore,
      'outcome': outcome,
      'scoring_explanation': scoringExplanation,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class AssessmentRubric {
  final int id;
  final String rubricId;
  final String version;
  final String name;
  final String? description;
  final Map<String, dynamic> rules;
  final String createdBy;
  final DateTime createdAt;
  final bool isActive;

  AssessmentRubric({
    required this.id,
    required this.rubricId,
    required this.version,
    required this.name,
    this.description,
    required this.rules,
    required this.createdBy,
    required this.createdAt,
    required this.isActive,
  });

  factory AssessmentRubric.fromJson(Map<String, dynamic> json) {
    return AssessmentRubric(
      id: json['id'] as int,
      rubricId: json['rubric_id'] as String,
      version: json['version'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      rules: json['rules'] as Map<String, dynamic>? ?? {},
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rubric_id': rubricId,
      'version': version,
      'name': name,
      'description': description,
      'rules': rules,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
    };
  }
}
