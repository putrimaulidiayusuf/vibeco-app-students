class ClassRanking {
  final int rank;
  final String className;
  final double score;
  final int? classId;
  final int? submissionCount;
  final double? averageScore;

  ClassRanking({
    required this.rank,
    required this.className,
    required this.score,
    this.classId,
    this.submissionCount,
    this.averageScore,
  });

  factory ClassRanking.fromJson(Map<String, dynamic> json, {int? index}) {
    return ClassRanking(
      rank: json['rank'] != null
          ? (json['rank'] is int
              ? json['rank']
              : (json['rank'] as num).toInt())
          : (index ?? 0) + 1,
      className: json['class_name']?.toString() ?? '',
      score: json['score'] != null
          ? (json['score'] as num).toDouble()
          : 0.0,
      classId: json['class_id'] != null
          ? (json['class_id'] is int
              ? json['class_id']
              : int.tryParse(json['class_id'].toString()))
          : null,
      submissionCount: json['submission_count'] != null
          ? (json['submission_count'] as num).toInt()
          : null,
      averageScore: json['average_score'] != null
          ? (json['average_score'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'class_name': className,
      'score': score,
      'class_id': classId,
      'submission_count': submissionCount,
      'average_score': averageScore,
    };
  }
}
