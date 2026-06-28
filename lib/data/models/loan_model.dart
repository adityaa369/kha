import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class LoanModel extends Equatable {
  final String id;
  final String? lenderId; // For loans given by user
  final String? userId; // For loans taken by user
  final String borrowerName;
  final String? lenderName;
  final String? lenderPhone;
  final String? initials;
  final double amount;
  final double? interestRate;
  final int? durationMonths;
  final String
  status; // 'pending_otp', 'active', 'completed', 'overdue', 'due_soon', 'defaulted'
  final double progress; // 0.0 to 1.0
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? activatedAt;
  final String type; // 'personal', 'business', 'home', 'chitfund'
  final String? mobile;
  final String? aadhar;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? otp;
  final double? emiAmount;
  final double? totalPayableAmount;
  final String? documentUrl;

  const LoanModel({
    required this.id,
    this.lenderId,
    this.userId,
    required this.borrowerName,
    this.lenderName,
    this.lenderPhone,
    this.initials,
    required this.amount,
    this.interestRate,
    this.durationMonths,
    required this.status,
    required this.progress,
    required this.startDate,
    this.endDate,
    this.activatedAt,
    required this.type,
    this.mobile,
    this.aadhar,
    this.createdAt,
    this.updatedAt,
    this.otp,
    this.emiAmount,
    this.totalPayableAmount,
    this.documentUrl,
  });

  factory LoanModel.fromJson(Map<String, dynamic> json) {
    return LoanModel(
      id: json['_id'] ?? json['id']?.toString() ?? '',
      lenderId: json['lender_id']?.toString() ?? json['lender']?.toString(),
      userId: json['user_id']?.toString() ?? json['borrower']?.toString(),
      borrowerName: json['borrowerName'] ?? json['borrower_name'] ?? '',
      lenderName: json['lenderName'] ?? json['lender_name'],
      lenderPhone:
          json['lenderPhone']?.toString() ?? json['lender_phone']?.toString(),
      initials:
          json['initials'] ??
          _generateInitials(
            json['lenderName'] ??
                json['borrowerName'] ??
                json['borrower_name'] ??
                '',
          ),
      amount: _parseDouble(json['amount']) ?? 0.0,
      interestRate:
          _parseDouble(json['interestRate']) ?? _parseDouble(json['interest_rate']),
      durationMonths: json['durationMonths'] is int
          ? json['durationMonths']
          : (json['duration_months'] is int
              ? json['duration_months']
              : int.tryParse(json['durationMonths']?.toString() ?? json['duration_months']?.toString() ?? '')),
      status: json['status']?.toString() ?? 'active',
      progress: (_parseDouble(json['progress']) ?? 0.0).clamp(0.0, 1.0),
      startDate: _parseDate(json['startDate'] ?? json['start_date']) ?? DateTime.now(),
      endDate: _parseDate(json['endDate'] ?? json['end_date']),
      activatedAt: _parseDate(json['activatedAt'] ?? json['activated_at']),
      type: json['loanType']?.toString() ?? json['type']?.toString() ?? 'personal',
      mobile: json['borrowerPhone']?.toString() ?? json['mobile']?.toString() ?? json['borrower_phone']?.toString(),
      aadhar:
          json['borrowerAadhar']?.toString() ?? json['aadhar']?.toString() ?? json['borrower_aadhar']?.toString(),
      createdAt: _parseDate(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDate(json['updated_at'] ?? json['updatedAt']),
      otp: json['otp']?.toString(),
      emiAmount: _parseDouble(json['emiAmount']) ?? _parseDouble(json['emi_amount']),
      totalPayableAmount:
          _parseDouble(json['totalPayable']) ?? _parseDouble(json['total_payable']),
      documentUrl:
          json['documentUrl']?.toString() ?? json['document_url']?.toString(),
    );
  }

  /// Safely parse a value to double, whether it's an int, double, or numeric string
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed;
    }
    return null;
  }

  /// Safely parse a date string, returning null on failure
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  // For REST API insert
  Map<String, dynamic> toJsonForCreate() {
    return {
      'borrowerName': borrowerName,
      'borrowerPhone': mobile,
      'borrowerAadhar': aadhar,
      'amount': amount,
      'interestRate': interestRate,
      'durationMonths': durationMonths,
      'loanType': type,
    };
  }

  // For Supabase update
  Map<String, dynamic> toJsonForUpdate() {
    return {
      'status': status,
      'progress': progress,
      'activated_at': activatedAt?.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  static String _generateInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '';
  }

  // Helper getters
  String get displayCounterpartyName {
    if (lenderName != null && lenderName!.isNotEmpty) {
      return lenderName!;
    }
    return borrowerName;
  }

  String get displayType {
    final t = type.toLowerCase();
    if (t == 'personal' || t == 'hand_credit') {
      return 'Hand Credit';
    } else if (t == 'business' || t == 'business_credit') {
      return 'Business Credit';
    } else if (t == 'home' || t == 'interest_credit') {
      return 'Interest Credit';
    } else if (t == 'chitfund') {
      return 'Chit Funds';
    }
    return type.toUpperCase();
  }

  String get displayAmount {
    if (amount == 0) return '-';
    return '₹ ${_formatNumber(amount)}';
  }

  String get displayInterestRate {
    if (interestRate == null) return '-';
    return '${interestRate!.toStringAsFixed(1)}%';
  }

  String get displayDuration {
    if (durationMonths == null) return '-';
    return '$durationMonths months';
  }

  static String _formatNumber(double number) {
    return number
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  String get statusDisplay {
    switch (status) {
      case 'pending_approval':
        return 'Pending Approval';
      case 'pending_otp':
        return 'Pending Setup';
      case 'active':
        return 'On Track';
      case 'due_soon':
        return 'Due Soon';
      case 'overdue':
        return 'Overdue';
      case 'completed':
      case 'closed':
        return 'Completed';
      case 'defaulted':
        return 'Defaulted';
      default:
        return 'Active';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending_approval':
      case 'pending_otp':
        return const Color(0xFFF59E0B); // Amber / Orange
      case 'active':
      case 'completed':
      case 'closed':
        return const Color(0xFF10B981); // Green
      case 'due_soon':
        return const Color(0xFFF59E0B); // Yellow
      case 'overdue':
      case 'defaulted':
        return const Color(0xFFEF4444); // Red
      default:
        return const Color(0xFF10B981);
    }
  }

  // Calculate EMI (if interest rate and duration available)
  double? get emi {
    if (emiAmount != null) return emiAmount;
    if (interestRate == null || durationMonths == null || durationMonths == 0) {
      return null;
    }

    final P = amount;
    final r = interestRate! / 100 / 12; // Monthly interest rate
    final n = durationMonths!;

    final emi = P * r * (pow(1 + r, n)) / (pow(1 + r, n) - 1);
    return emi;
  }

  // Calculate total payable amount
  double? get totalPayable {
    if (totalPayableAmount != null) return totalPayableAmount;
    if (emi == null || durationMonths == null) return null;
    return emi! * durationMonths!;
  }

  // Calculate remaining amount
  double get remainingAmount => amount * (1 - progress);

  // Check if loan is overdue
  bool get isOverdue {
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate!) && progress < 1.0;
  }

  // Days remaining until due
  int? get daysRemaining {
    if (endDate == null) return null;
    return endDate!.difference(DateTime.now()).inDays;
  }

  LoanModel copyWith({
    String? id,
    String? lenderId,
    String? userId,
    String? borrowerName,
    String? lenderName,
    String? lenderPhone,
    String? initials,
    double? amount,
    double? interestRate,
    int? durationMonths,
    String? status,
    double? progress,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? activatedAt,
    String? type,
    String? mobile,
    String? aadhar,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? emiAmount,
    double? totalPayableAmount,
    String? documentUrl,
  }) {
    return LoanModel(
      id: id ?? this.id,
      lenderId: lenderId ?? this.lenderId,
      userId: userId ?? this.userId,
      borrowerName: borrowerName ?? this.borrowerName,
      lenderName: lenderName ?? this.lenderName,
      lenderPhone: lenderPhone ?? this.lenderPhone,
      initials: initials ?? this.initials,
      amount: amount ?? this.amount,
      interestRate: interestRate ?? this.interestRate,
      durationMonths: durationMonths ?? this.durationMonths,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      activatedAt: activatedAt ?? this.activatedAt,
      type: type ?? this.type,
      mobile: mobile ?? this.mobile,
      aadhar: aadhar ?? this.aadhar,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      emiAmount: emiAmount ?? this.emiAmount,
      totalPayableAmount: totalPayableAmount ?? this.totalPayableAmount,
      documentUrl: documentUrl ?? this.documentUrl,
    );
  }

  @override
  List<Object?> get props => [
    id,
    lenderId,
    userId,
    borrowerName,
    lenderName,
    lenderPhone,
    amount,
    status,
    progress,
    startDate,
    type,
    emiAmount,
    totalPayableAmount,
    documentUrl,
  ];
}

// Helper function for EMI calculation
double pow(double x, int n) {
  double result = 1;
  for (int i = 0; i < n; i++) {
    result *= x;
  }
  return result;
}
