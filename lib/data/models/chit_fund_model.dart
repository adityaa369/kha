class ChitFundModel {
  final String id;
  final String name;
  final double totalValue;
  final int totalMonths;
  final double monthlySubscription;
  final double organizerFeePercent;
  final String branchName;
  final String status;
  final int currentSubscribersCount;
  final int completedMonths;
  final String owner;

  ChitFundModel({
    required this.id,
    required this.name,
    required this.totalValue,
    required this.totalMonths,
    required this.monthlySubscription,
    required this.organizerFeePercent,
    required this.branchName,
    required this.status,
    required this.currentSubscribersCount,
    required this.completedMonths,
    required this.owner,
  });

  factory ChitFundModel.fromJson(Map<String, dynamic> json) {
    return ChitFundModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      totalValue: (json['totalValue'] ?? 0).toDouble(),
      totalMonths: json['totalMonths'] ?? 0,
      monthlySubscription: (json['monthlySubscription'] ?? 0).toDouble(),
      organizerFeePercent: (json['organizerFeePercent'] ?? 0).toDouble(),
      branchName: json['branchName'] ?? '',
      status: json['status'] ?? 'registration',
      currentSubscribersCount: json['currentSubscribersCount'] ?? 0,
      completedMonths: json['completedMonths'] ?? 0,
      owner: json['owner'] ?? '',
    );
  }
}
