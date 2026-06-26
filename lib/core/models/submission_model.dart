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
      className: json['class_name']?.toString(),
      date: json['date']?.toString() ?? '',
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
      submittedBy: json['submitted_by']?.toString(),
      verifiedBy: json['verified_by']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
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
    };
  }
}
