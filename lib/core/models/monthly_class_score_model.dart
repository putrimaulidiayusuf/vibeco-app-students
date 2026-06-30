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

  factory MonthlyClassScore.fromJson(Map<String, dynamic> json) {
    return MonthlyClassScore(
      id: json['id'] as int,
      schoolClassId: json['school_class_id'] as int,
      schoolClassName: json['school_class_name']?.toString() ?? '',
      year: json['year'] as int,
      month: json['month'] as int,
      score: (json['score'] as num).toDouble(),
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
