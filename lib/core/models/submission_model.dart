class AspekPenilaianDetail {
  final int skor;
  final String catatan;

  AspekPenilaianDetail({required this.skor, required this.catatan});

  factory AspekPenilaianDetail.fromJson(Map<String, dynamic> json) {
    return AspekPenilaianDetail(
      skor: json['skor'] is int ? json['skor'] : int.tryParse(json['skor']?.toString() ?? '0') ?? 0,
      catatan: json['catatan']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'skor': skor,
      'catatan': catatan,
    };
  }
}

class DailyClassScore {
  final int id;
  final int score;
  final String kategori;
  final Map<String, AspekPenilaianDetail> aspekPenilaian;
  final List<String> saranPerbaikan;

  DailyClassScore({
    required this.id,
    required this.score,
    required this.kategori,
    required this.aspekPenilaian,
    required this.saranPerbaikan,
  });

  factory DailyClassScore.fromJson(Map<String, dynamic> json) {
    final rawAspek = json['aspek_penilaian'] as Map<String, dynamic>? ?? {};
    final aspek = rawAspek.map((key, val) => MapEntry(
          key,
          AspekPenilaianDetail.fromJson(val as Map<String, dynamic>),
        ));

    final rawSaran = json['saran_perbaikan'] as List<dynamic>? ?? [];
    final saran = rawSaran.map((s) => s.toString()).toList();

    return DailyClassScore(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      score: json['score'] is int ? json['score'] : int.tryParse(json['score']?.toString() ?? '0') ?? 0,
      kategori: json['kategori']?.toString() ?? '',
      aspekPenilaian: aspek,
      saranPerbaikan: saran,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'score': score,
      'kategori': kategori,
      'aspek_penilaian': aspekPenilaian.map((k, v) => MapEntry(k, v.toJson())),
      'saran_perbaikan': saranPerbaikan,
    };
  }
}

class PiketSubmission {
  final int id;
  final int? teamId;
  final String? className;
  final String date;
  final int? aiScore;
  final int? finalScore;
  final String status; // 'pending', 'approved', 'rejected', 'adjusted'
  final List<String> findings;
  final List<String> photoUrls;
  final String? notes;
  final double? latitude;
  final double? longitude;
  final String? submittedBy;
  final String? verifiedBy;
  final String? createdAt;
  final String? updatedAt;
  final DailyClassScore? dailyClassScore;

  PiketSubmission({
    required this.id,
    this.teamId,
    this.className,
    required this.date,
    this.aiScore,
    this.finalScore,
    required this.status,
    this.findings = const [],
    this.photoUrls = const [],
    this.notes,
    this.latitude,
    this.longitude,
    this.submittedBy,
    this.verifiedBy,
    this.createdAt,
    this.updatedAt,
    this.dailyClassScore,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isAdjusted => status == 'adjusted';

  int get displayScore => finalScore ?? aiScore ?? 0;

  factory PiketSubmission.fromJson(Map<String, dynamic> json) {
    // Parse findings — can be a List, a String, or null
    List<String> parsedFindings = [];
    if (json['findings'] != null) {
      if (json['findings'] is List) {
        parsedFindings = (json['findings'] as List)
            .map((f) => f.toString())
            .toList();
      } else if (json['findings'] is String) {
        parsedFindings = [json['findings'].toString()];
      }
    } else if (json['ai_findings'] != null && json['ai_findings'] is List) {
      parsedFindings = (json['ai_findings'] as List)
          .map((f) => f.toString())
          .toList();
    }

    // Parse photo URLs
    List<String> parsedPhotos = [];
    if (json['photo_urls'] != null && json['photo_urls'] is List) {
      parsedPhotos = (json['photo_urls'] as List)
          .map((p) => p.toString())
          .toList();
    } else if (json['photos'] != null && json['photos'] is List) {
      parsedPhotos = (json['photos'] as List)
          .map((p) => p.toString())
          .toList();
    }

    return PiketSubmission(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      teamId: json['team_id'] != null
          ? (json['team_id'] is int
              ? json['team_id']
              : int.tryParse(json['team_id'].toString()))
          : null,
      className: json['class_name']?.toString() ?? json['school_class']?['name']?.toString(),
      date: json['date']?.toString() ?? json['submission_date']?.toString() ?? '',
      aiScore: json['ai_score'] != null
          ? (json['ai_score'] is int
              ? json['ai_score']
              : (json['ai_score'] as num).toInt())
          : null,
      finalScore: json['final_score'] != null
          ? (json['final_score'] is int
              ? json['final_score']
              : (json['final_score'] as num).toInt())
          : null,
      status: json['status']?.toString() ?? 'pending',
      findings: parsedFindings,
      photoUrls: parsedPhotos,
      notes: json['notes']?.toString(),
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      submittedBy: json['submitted_by']?.toString() ?? json['student']?['name']?.toString(),
      verifiedBy: json['verified_by']?.toString() ?? json['verifier']?['name']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      dailyClassScore: json['daily_class_score'] != null
          ? DailyClassScore.fromJson(json['daily_class_score'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'team_id': teamId,
      'class_name': className,
      'date': date,
      'ai_score': aiScore,
      'final_score': finalScore,
      'status': status,
      'findings': findings,
      'photo_urls': photoUrls,
      'notes': notes,
      'latitude': latitude,
      'longitude': longitude,
      'submitted_by': submittedBy,
      'verified_by': verifiedBy,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'daily_class_score': dailyClassScore?.toJson(),
    };
  }
}
