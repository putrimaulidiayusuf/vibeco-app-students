class MonthlyClassScore {
  final int id;
  final int schoolClassId;
  final String schoolClassName;
  final int year;
  final int month;
  final double score;
  final String createdAt;
  final String updatedAt;

  MonthlyClassScore({
    required this.id,
    required this.schoolClassId,
    required this.schoolClassName,
    required this.year,
    required this.month,
    required this.score,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Handles both /monthly-class-scores format and /rankings?interval=monthly format.
  /// Rankings format: {class_id, class_name, score}
  factory MonthlyClassScore.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return MonthlyClassScore(
      id: (json['id'] as int?) ?? 0,
      schoolClassId: (json['school_class_id'] as int?) ?? (json['class_id'] as int?) ?? 0,
      schoolClassName: json['school_class_name']?.toString() ?? json['class_name']?.toString() ?? '',
      year: (json['year'] as int?) ?? now.year,
      month: (json['month'] as int?) ?? now.month,
      score: json['score'] != null ? (json['score'] as num).toDouble() : 0.0,
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_class_id': schoolClassId,
      'school_class_name': schoolClassName,
      'year': year,
      'month': month,
      'score': score,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
