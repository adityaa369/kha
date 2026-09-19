import 'package:equatable/equatable.dart';

class NotificationPreferences extends Equatable {
  final bool loanUpdates;
  final bool paymentUpdates;
  final bool securityAlerts; // Always true — read-only
  final bool kycUpdates;
  final bool chitFundUpdates;
  final bool promotional;

  const NotificationPreferences({
    this.loanUpdates = true,
    this.paymentUpdates = true,
    this.securityAlerts = true,
    this.kycUpdates = true,
    this.chitFundUpdates = true,
    this.promotional = false,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      loanUpdates: json['loanUpdates'] as bool? ?? true,
      paymentUpdates: json['paymentUpdates'] as bool? ?? true,
      securityAlerts: true, // always true regardless of server value
      kycUpdates: json['kycUpdates'] as bool? ?? true,
      chitFundUpdates: json['chitFundUpdates'] as bool? ?? true,
      promotional: json['promotional'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'loanUpdates': loanUpdates,
        'paymentUpdates': paymentUpdates,
        // securityAlerts is not sent — backend ignores it anyway
        'kycUpdates': kycUpdates,
        'chitFundUpdates': chitFundUpdates,
        'promotional': promotional,
      };

  NotificationPreferences copyWith({
    bool? loanUpdates,
    bool? paymentUpdates,
    bool? kycUpdates,
    bool? chitFundUpdates,
    bool? promotional,
  }) {
    return NotificationPreferences(
      loanUpdates: loanUpdates ?? this.loanUpdates,
      paymentUpdates: paymentUpdates ?? this.paymentUpdates,
      securityAlerts: true,
      kycUpdates: kycUpdates ?? this.kycUpdates,
      chitFundUpdates: chitFundUpdates ?? this.chitFundUpdates,
      promotional: promotional ?? this.promotional,
    );
  }

  @override
  List<Object?> get props => [
        loanUpdates,
        paymentUpdates,
        securityAlerts,
        kycUpdates,
        chitFundUpdates,
        promotional,
      ];
}
