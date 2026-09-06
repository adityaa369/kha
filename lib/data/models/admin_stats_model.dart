class AdminStats {
  final int totalUsers;
  final int totalLoans;
  final int totalChits;
  final int activeLoans;
  final int activeChits;
  final double totalLoanVolume;
  final double totalChitVolume;
  final int newUsers; // last 30 days
  final int newLoans; // last 30 days

  const AdminStats({
    required this.totalUsers,
    required this.totalLoans,
    required this.totalChits,
    required this.activeLoans,
    required this.activeChits,
    required this.totalLoanVolume,
    required this.totalChitVolume,
    required this.newUsers,
    required this.newLoans,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) => AdminStats(
    totalUsers: json['totalUsers'] ?? 0,
    totalLoans: json['totalLoans'] ?? 0,
    totalChits: json['totalChits'] ?? 0,
    activeLoans: json['activeLoans'] ?? 0,
    activeChits: json['activeChits'] ?? 0,
    totalLoanVolume: (json['totalLoanVolumePaise'] != null ? json['totalLoanVolumePaise'] / 100.0 : (json['totalLoanVolume'] ?? 0).toDouble()),
    totalChitVolume: (json['totalChitVolumePaise'] != null ? json['totalChitVolumePaise'] / 100.0 : (json['totalChitVolume'] ?? 0).toDouble()),
    newUsers: json['newUsers'] ?? 0,
    newLoans: json['newLoans'] ?? 0,
  );
}
