class AppSettings {
  final double latitude;
  final double longitude;
  final double radius;
  final String startTime; // HH:mm format
  final String endTime; // HH:mm format
  final String? schoolName;

  AppSettings({
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.startTime,
    required this.endTime,
    this.schoolName,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : 0.0,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : 0.0,
      radius: json['radius'] != null
          ? (json['radius'] as num).toDouble()
          : 100.0,
      startTime: json['start_time']?.toString() ?? '06:00',
      endTime: json['end_time']?.toString() ?? '08:00',
      schoolName: json['school_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'start_time': startTime,
      'end_time': endTime,
      'school_name': schoolName,
    };
  }
}
