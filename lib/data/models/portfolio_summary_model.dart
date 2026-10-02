import 'package:equatable/equatable.dart';

class MonthlyCollection extends Equatable {
  final String month;
  final int amountPaise;

  const MonthlyCollection({required this.month, required this.amountPaise});

  double get amountRupees => amountPaise / 100;

  factory MonthlyCollection.fromJson(Map<String, dynamic> json) {
    return MonthlyCollection(
      month: json['month']?.toString() ?? '',
      amountPaise: (json['amountPaise'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [month, amountPaise];
}

class LenderStats extends Equatable {
  final int loanCount;
  final int activeLoanCount;
  final int closedLoanCount;
  final int defaultedLoanCount;
  final int totalLentPaise;
  final int totalCollectedPaise;
  final int outstandingPaise;
  final int collectionRatePct;
  final List<MonthlyCollection> monthlyCollections;

  const LenderStats({
    required this.loanCount,
    required this.activeLoanCount,
    required this.closedLoanCount,
    required this.defaultedLoanCount,
    required this.totalLentPaise,
    required this.totalCollectedPaise,
    required this.outstandingPaise,
    required this.collectionRatePct,
    required this.monthlyCollections,
  });

  double get totalLent => totalLentPaise / 100;
  double get totalCollected => totalCollectedPaise / 100;
  double get outstanding => outstandingPaise / 100;

  factory LenderStats.fromJson(Map<String, dynamic> json) {
    final rawMonthly = json['monthlyCollections'];
    final monthly = (rawMonthly is List)
        ? rawMonthly
            .map((e) => MonthlyCollection.fromJson(e as Map<String, dynamic>))
            .toList()
        : <MonthlyCollection>[];
    return LenderStats(
      loanCount: (json['loanCount'] as num?)?.toInt() ?? 0,
      activeLoanCount: (json['activeLoanCount'] as num?)?.toInt() ?? 0,
      closedLoanCount: (json['closedLoanCount'] as num?)?.toInt() ?? 0,
      defaultedLoanCount: (json['defaultedLoanCount'] as num?)?.toInt() ?? 0,
      totalLentPaise: (json['totalLentPaise'] as num?)?.toInt() ?? 0,
      totalCollectedPaise: (json['totalCollectedPaise'] as num?)?.toInt() ?? 0,
      outstandingPaise: (json['outstandingPaise'] as num?)?.toInt() ?? 0,
      collectionRatePct: (json['collectionRatePct'] as num?)?.toInt() ?? 0,
      monthlyCollections: monthly,
    );
  }

  @override
  List<Object?> get props => [
        loanCount,
        activeLoanCount,
        closedLoanCount,
        defaultedLoanCount,
        totalLentPaise,
        totalCollectedPaise,
        outstandingPaise,
        collectionRatePct,
      ];
}

class BorrowerStats extends Equatable {
  final int loanCount;
  final int activeLoanCount;
  final int closedLoanCount;
  final int totalBorrowedPaise;
  final int totalRepaidPaise;
  final int outstandingPaise;
  final int repaymentRatePct;

  const BorrowerStats({
    required this.loanCount,
    required this.activeLoanCount,
    required this.closedLoanCount,
    required this.totalBorrowedPaise,
    required this.totalRepaidPaise,
    required this.outstandingPaise,
    required this.repaymentRatePct,
  });

  double get totalBorrowed => totalBorrowedPaise / 100;
  double get totalRepaid => totalRepaidPaise / 100;
  double get outstanding => outstandingPaise / 100;

  factory BorrowerStats.fromJson(Map<String, dynamic> json) {
    return BorrowerStats(
      loanCount: (json['loanCount'] as num?)?.toInt() ?? 0,
      activeLoanCount: (json['activeLoanCount'] as num?)?.toInt() ?? 0,
      closedLoanCount: (json['closedLoanCount'] as num?)?.toInt() ?? 0,
      totalBorrowedPaise: (json['totalBorrowedPaise'] as num?)?.toInt() ?? 0,
      totalRepaidPaise: (json['totalRepaidPaise'] as num?)?.toInt() ?? 0,
      outstandingPaise: (json['outstandingPaise'] as num?)?.toInt() ?? 0,
      repaymentRatePct: (json['repaymentRatePct'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        loanCount,
        activeLoanCount,
        closedLoanCount,
        totalBorrowedPaise,
        totalRepaidPaise,
        outstandingPaise,
        repaymentRatePct,
      ];
}

class PortfolioSummaryModel extends Equatable {
  final int loanCount;
  final int activeLoanCount;
  final int totalLentPaise;
  final int totalCollectedPaise;
  final int outstandingPaise;
  final LenderStats? lenderStats;
  final BorrowerStats? borrowerStats;

  const PortfolioSummaryModel({
    required this.loanCount,
    required this.activeLoanCount,
    required this.totalLentPaise,
    required this.totalCollectedPaise,
    required this.outstandingPaise,
    this.lenderStats,
    this.borrowerStats,
  });

  factory PortfolioSummaryModel.fromJson(Map<String, dynamic> json) {
    return PortfolioSummaryModel(
      loanCount: (json['loanCount'] as num?)?.toInt() ?? 0,
      activeLoanCount: (json['activeLoanCount'] as num?)?.toInt() ?? 0,
      totalLentPaise: (json['totalLentPaise'] as num?)?.toInt() ?? 0,
      totalCollectedPaise: (json['totalCollectedPaise'] as num?)?.toInt() ?? 0,
      outstandingPaise: (json['outstandingPaise'] as num?)?.toInt() ?? 0,
      lenderStats: json['lenderStats'] != null
          ? LenderStats.fromJson(json['lenderStats'] as Map<String, dynamic>)
          : null,
      borrowerStats: json['borrowerStats'] != null
          ? BorrowerStats.fromJson(json['borrowerStats'] as Map<String, dynamic>)
          : null,
    );
  }

  double get totalLent => totalLentPaise / 100;
  double get totalCollected => totalCollectedPaise / 100;
  double get outstanding => outstandingPaise / 100;

  @override
  List<Object?> get props => [
        loanCount,
        activeLoanCount,
        totalLentPaise,
        totalCollectedPaise,
        outstandingPaise,
        lenderStats,
        borrowerStats,
      ];
}
