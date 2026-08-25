import 'package:equatable/equatable.dart';

class RepaymentTransactionModel extends Equatable {
  final String type;
  final int amountPaise;
  final String note;
  final DateTime recordedAt;

  const RepaymentTransactionModel({
    required this.type,
    required this.amountPaise,
    required this.note,
    required this.recordedAt,
  });

  factory RepaymentTransactionModel.fromJson(Map<String, dynamic> json) {
    return RepaymentTransactionModel(
      type: json['type'] ?? 'payment',
      amountPaise: json['amountPaise'] as int? ?? ((json['amount'] as num?)?.toInt() ?? 0) * 100,
      note: json['note'] ?? '',
      recordedAt: DateTime.parse(json['recordedAt']),
    );
  }

  double get amount => amountPaise / 100;

  @override
  List<Object> get props => [type, amountPaise, note, recordedAt];
}

class RepaymentPeriodModel extends Equatable {
  final int periodIndex;
  final DateTime periodStart;
  final DateTime periodEnd;
  final String status;
  final bool hasPayments;
  final int totalPaidPaise;
  final List<RepaymentTransactionModel> transactions;

  const RepaymentPeriodModel({
    required this.periodIndex,
    required this.periodStart,
    required this.periodEnd,
    required this.status,
    required this.hasPayments,
    required this.totalPaidPaise,
    required this.transactions,
  });

  factory RepaymentPeriodModel.fromJson(Map<String, dynamic> json) {
    return RepaymentPeriodModel(
      periodIndex: json['periodIndex'] as int,
      periodStart: DateTime.parse(json['periodStart']),
      periodEnd: DateTime.parse(json['periodEnd']),
      status: json['status'] as String,
      hasPayments: json['hasPayments'] as bool,
      totalPaidPaise: json['totalPaidPaise'] as int,
      transactions: (json['transactions'] as List)
          .map((e) => RepaymentTransactionModel.fromJson(e))
          .toList(),
    );
  }

  double get totalPaid => totalPaidPaise / 100;

  @override
  List<Object> get props => [
        periodIndex,
        periodStart,
        periodEnd,
        status,
        hasPayments,
        totalPaidPaise,
        transactions,
      ];
}

class RepaymentTimelineModel extends Equatable {
  final bool trackingEnabled;
  final String? reason;
  final int? durationMonths;
  final DateTime? startDate;
  final List<RepaymentPeriodModel> timeline;
  final List<RepaymentTransactionModel> postTermTransactions;

  const RepaymentTimelineModel({
    required this.trackingEnabled,
    this.reason,
    this.durationMonths,
    this.startDate,
    required this.timeline,
    required this.postTermTransactions,
  });

  factory RepaymentTimelineModel.fromJson(Map<String, dynamic> json) {
    if (json['trackingEnabled'] == false) {
      return RepaymentTimelineModel(
        trackingEnabled: false,
        reason: json['reason'],
        timeline: const [],
        postTermTransactions: const [],
      );
    }
    
    final data = json['data'] ?? {};
    return RepaymentTimelineModel(
      trackingEnabled: true,
      durationMonths: data['durationMonths'] as int?,
      startDate: data['startDate'] != null ? DateTime.parse(data['startDate']) : null,
      timeline: (data['timeline'] as List?)
              ?.map((e) => RepaymentPeriodModel.fromJson(e))
              .toList() ??
          [],
      postTermTransactions: (data['postTermTransactions'] as List?)
              ?.map((e) => RepaymentTransactionModel.fromJson(e))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [
        trackingEnabled,
        reason,
        durationMonths,
        startDate,
        timeline,
        postTermTransactions,
      ];
}
