import 'package:equatable/equatable.dart';

class PortfolioSummaryModel extends Equatable {
  final int loanCount;
  final int activeLoanCount;
  final int totalLentPaise;
  final int totalCollectedPaise;
  final int outstandingPaise;

  const PortfolioSummaryModel({
    required this.loanCount,
    required this.activeLoanCount,
    required this.totalLentPaise,
    required this.totalCollectedPaise,
    required this.outstandingPaise,
  });

  factory PortfolioSummaryModel.fromJson(Map<String, dynamic> json) {
    return PortfolioSummaryModel(
      loanCount: json['loanCount'] as int? ?? 0,
      activeLoanCount: json['activeLoanCount'] as int? ?? 0,
      totalLentPaise: json['totalLentPaise'] as int? ?? 0,
      totalCollectedPaise: json['totalCollectedPaise'] as int? ?? 0,
      outstandingPaise: json['outstandingPaise'] as int? ?? 0,
    );
  }

  // F.3 alignment: expose Rupees for UI
  double get totalLent => totalLentPaise / 100;
  double get totalCollected => totalCollectedPaise / 100;
  double get outstanding => outstandingPaise / 100;

  @override
  List<Object> get props => [
        loanCount,
        activeLoanCount,
        totalLentPaise,
        totalCollectedPaise,
        outstandingPaise,
      ];
}
