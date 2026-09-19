enum NotificationCategory { all, loans, payments, security, kyc, chitFunds }

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String eventType;
  final String type; // legacy
  final String? referenceType;
  final String? referenceId;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final Map<String, dynamic> data;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.eventType = 'general',
    this.type = 'general',
    this.referenceType,
    this.referenceId,
    required this.isRead,
    this.readAt,
    required this.createdAt,
    required this.data,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      eventType: json['eventType'] ?? json['type'] ?? 'general',
      type: json['type'] ?? 'general',
      referenceType: json['referenceType'],
      referenceId: json['referenceId'],
      isRead: json['isRead'] ?? false,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      data: Map<String, dynamic>.from(json['data'] ?? {}),
    );
  }

  NotificationModel copyWith({bool? isRead, DateTime? readAt}) {
    return NotificationModel(
      id: id,
      title: title,
      body: body,
      eventType: eventType,
      type: type,
      referenceType: referenceType,
      referenceId: referenceId,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
      data: data,
    );
  }

  /// Map eventType to a display category
  NotificationCategory get category {
    const loans = {
      'LOAN_CREATED', 'LOAN_RECEIVED', 'AGREEMENT_READY', 'AGREEMENT_ACCEPTED',
      'LOAN_ACTIVATED', 'LOAN_COMPLETED', 'LOAN_CLOSED',
    };
    const payments = {'PAYMENT_RECEIVED', 'PAYMENT_FAILED'};
    const security = {'MPIN_CREATED', 'EMAIL_VERIFIED', 'ACCOUNT_CREATED'};
    const kyc = {'KYC_UPDATE'};
    const chit = {
      'CHIT_INVITE', 'CHIT_JOINED', 'CHIT_CONTRIBUTION_DUE',
      'AUCTION_OPENED', 'AUCTION_CLOSED', 'CHIT_PAYOUT',
    };
    if (loans.contains(eventType)) return NotificationCategory.loans;
    if (payments.contains(eventType)) return NotificationCategory.payments;
    if (security.contains(eventType)) return NotificationCategory.security;
    if (kyc.contains(eventType)) return NotificationCategory.kyc;
    if (chit.contains(eventType)) return NotificationCategory.chitFunds;
    return NotificationCategory.all;
  }
}
