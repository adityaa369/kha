class SecurityEventModel {
  final String eventType;
  final String result;
  final DateTime createdAt;

  SecurityEventModel({
    required this.eventType,
    required this.result,
    required this.createdAt,
  });

  factory SecurityEventModel.fromJson(Map<String, dynamic> json) {
    return SecurityEventModel(
      eventType: json['eventType'] ?? 'UNKNOWN',
      result: json['result'] ?? 'UNKNOWN',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}
