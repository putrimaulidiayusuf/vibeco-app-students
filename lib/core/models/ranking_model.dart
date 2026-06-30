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

class PiketDayRanking {
  final int rank;
  final String dayOfWeek;
  final String dayNameId;
  final double averageScore;
  final double? maxScore;
  final int piketCount;

  PiketDayRanking({
    required this.rank,
    required this.dayOfWeek,
    required this.dayNameId,
    required this.averageScore,
    this.maxScore,
    required this.piketCount,
  });

  factory PiketDayRanking.fromJson(Map<String, dynamic> json, int rank) {
    return PiketDayRanking(
      rank: rank,
      dayOfWeek: json['day_of_week']?.toString() ?? '',
      dayNameId: json['day_name_id']?.toString() ?? '',
      averageScore: json['average_score'] != null
          ? (json['average_score'] as num).toDouble()
          : 0.0,
      maxScore: json['max_score'] != null
          ? (json['max_score'] as num).toDouble()
          : null,
      piketCount: json['piket_count'] != null
          ? (json['piket_count'] as num).toInt()
          : 0,
    );
  }
}
