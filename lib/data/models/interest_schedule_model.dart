import 'package:equatable/equatable.dart';

class InterestPeriodViewModel extends Equatable {
  final String month;
  final int accruedPaise;
  final int paidPaise;

  const InterestPeriodViewModel({
    required this.month,
    required this.accruedPaise,
    required this.paidPaise,
  });

  factory InterestPeriodViewModel.fromJson(Map<String, dynamic> json) {
    return InterestPeriodViewModel(
      month: json['month'] as String,
      accruedPaise: json['accruedPaise'] as int,
      paidPaise: json['paidPaise'] as int,
    );
  }

  @override
  List<Object?> get props => [month, accruedPaise, paidPaise];
}

class InterestScheduleModel extends Equatable {
  final int totalAccruedPaise;
  final int totalPaidPaise;
  final int outstandingInterestPaise;
  final int originalPrincipalPaise;
  final int interestRateBps;
  final String interestMethod;
  final List<InterestPeriodViewModel> schedule;

  const InterestScheduleModel({
    required this.totalAccruedPaise,
    required this.totalPaidPaise,
    required this.outstandingInterestPaise,
    required this.originalPrincipalPaise,
    required this.interestRateBps,
    required this.interestMethod,
    required this.schedule,
  });

  factory InterestScheduleModel.fromJson(Map<String, dynamic> json) {
    return InterestScheduleModel(
      totalAccruedPaise: json['totalAccruedPaise'] as int,
      totalPaidPaise: json['totalPaidPaise'] as int,
      outstandingInterestPaise: json['outstandingInterestPaise'] as int,
      originalPrincipalPaise: json['originalPrincipalPaise'] as int,
      interestRateBps: json['interestRateBps'] as int,
      interestMethod: json['interestMethod'] as String,
      schedule: (json['schedule'] as List)
          .map((e) => InterestPeriodViewModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
        totalAccruedPaise,
        totalPaidPaise,
        outstandingInterestPaise,
        originalPrincipalPaise,
        interestRateBps,
        interestMethod,
        schedule,
      ];
}
