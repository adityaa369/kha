import 'package:equatable/equatable.dart';

class IntentModel extends Equatable {
  final String intentId;
  final String loanId;
  final String action; // e.g. ADD_CREDIT, CLOSE_LOAN, ACCEPT_LOAN
  final String status; // PENDING, CONSUMED, EXPIRED, CANCELLED
  final Map<String, dynamic> payload;

  const IntentModel({
    required this.intentId,
    required this.loanId,
    required this.action,
    required this.status,
    required this.payload,
  });

  factory IntentModel.fromJson(Map<String, dynamic> json) {
    return IntentModel(
      intentId: json['intentId'] ?? '',
      loanId: json['loanId'] ?? '',
      action: json['action'] ?? '',
      status: json['status'] ?? 'UNKNOWN',
      payload: json['payload'] ?? {},
    );
  }

  @override
  List<Object?> get props => [intentId, loanId, action, status, payload];
}
