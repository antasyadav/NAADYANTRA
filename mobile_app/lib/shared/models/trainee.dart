class Trainee {
  final int id;
  final String traineeId;
  final String? name;
  final String? cohort;
  final Map<String, dynamic> traineeMetadata;
  final DateTime createdAt;
  final bool isActive;

  Trainee({
    required this.id,
    required this.traineeId,
    this.name,
    this.cohort,
    required this.traineeMetadata,
    required this.createdAt,
    required this.isActive,
  });

  factory Trainee.fromJson(Map<String, dynamic> json) {
    return Trainee(
      id: json['id'] as int,
      traineeId: json['trainee_id'] as String,
      name: json['name'] as String?,
      cohort: json['cohort'] as String?,
      traineeMetadata: json['trainee_metadata'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trainee_id': traineeId,
      'name': name,
      'cohort': cohort,
      'trainee_metadata': traineeMetadata,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
    };
  }
}
