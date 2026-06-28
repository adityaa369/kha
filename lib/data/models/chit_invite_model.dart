import 'chit_fund_model.dart';

class ChitInviteModel {
  final String id;
  final ChitFundModel chitFund;
  final String senderId;
  final String senderName;
  final String senderPhone;
  final String receiverPhone;
  final String status;

  ChitInviteModel({
    required this.id,
    required this.chitFund,
    required this.senderId,
    required this.senderName,
    required this.senderPhone,
    required this.receiverPhone,
    required this.status,
  });

  factory ChitInviteModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> senderObj = json['sender'] ?? {};

    return ChitInviteModel(
      id: json['_id'] ?? '',
      chitFund: ChitFundModel.fromJson(json['chitFund'] ?? {}),
      senderId: senderObj['_id'] ?? '',
      senderName:
          '${senderObj['firstName'] ?? ''} ${senderObj['lastName'] ?? ''}'
              .trim(),
      senderPhone: senderObj['phone'] ?? '',
      receiverPhone: json['receiverPhone'] ?? '',
      status: json['status'] ?? 'pending',
    );
  }
}
