class SessionModel {
  final String id;
  final String deviceInfo;
  final DateTime lastUsedAt;
  final DateTime expiresAt;
  final bool isCurrent;

  SessionModel({
    required this.id,
    required this.deviceInfo,
    required this.lastUsedAt,
    required this.expiresAt,
    this.isCurrent = false,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      id: json['_id'] ?? '',
      deviceInfo: json['deviceInfo'] ?? 'Unknown Device',
      lastUsedAt: json['lastUsedAt'] != null ? DateTime.parse(json['lastUsedAt']) : DateTime.now(),
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : DateTime.now(),
      isCurrent: json['isCurrent'] == true,
    );
  }
}
