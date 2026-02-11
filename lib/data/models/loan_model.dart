import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class LoanModel extends Equatable {
  final String id;
  final String? lenderId; // For loans given by user
  final String? userId; // For loans taken by user
  final String borrowerName;
  final String? initials;
  final double amount;
  final double? interestRate;
  final int? durationMonths;
  final String status; // 'pending_otp', 'active', 'completed', 'overdue', 'due_soon', 'defaulted'
  final double progress; // 0.0 to 1.0
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? activatedAt;
  final String type; // 'personal', 'business', 'home', 'chitfund'
  final String? mobile;
  final String? aadhar;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const LoanModel({
    required this.id,
    this.lenderId,
    this.userId,
    required this.borrowerName,
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
  });

  factory LoanModel.fromJson(Map<String, dynamic> json) {
    return LoanModel(
      id: json['_id'] ?? json['id']?.toString() ?? '',
      lenderId: json['lender_id']?.toString() ?? json['lender']?.toString(),
      userId: json['user_id']?.toString() ?? json['borrower']?.toString(),
      borrowerName: json['borrowerName'] ?? json['borrower_name'] ?? json['lender_name'] ?? '',
      initials: json['initials'] ?? _generateInitials(json['borrowerName'] ?? json['borrower_name'] ?? ''),
      amount: (json['amount'] ?? 0).toDouble(),
      interestRate: json['interestRate']?.toDouble() ?? json['interest_rate']?.toDouble(),
      durationMonths: json['durationMonths'] ?? json['duration_months'],
      status: json['status'] ?? 'active',
      progress: (json['progress'] ?? 0).toDouble(),
      startDate: DateTime.parse(json['startDate'] ?? json['start_date'] ?? DateTime.now().toIso8601String()),
      endDate: json['endDate'] != null || json['end_date'] != null 
          ? DateTime.parse(json['endDate'] ?? json['end_date']) 
          : null,
      activatedAt: json['activatedAt'] != null || json['activated_at'] != null
          ? DateTime.parse(json['activatedAt'] ?? json['activated_at'])
          : null,
      type: json['loanType'] ?? json['type'] ?? 'personal',
      mobile: json['borrowerPhone'] ?? json['mobile'] ?? json['borrower_phone'],
      aadhar: json['borrowerAadhar'] ?? json['aadhar'] ?? json['borrower_aadhar'],
      createdAt: json['created_at'] != null || json['createdAt'] != null
          ? DateTime.parse(json['created_at'] ?? json['createdAt'])
          : null,
      updatedAt: json['updated_at'] != null || json['updatedAt'] != null
          ? DateTime.parse(json['updated_at'] ?? json['updatedAt'])
          : null,
    );
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
    return number.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }

  String get statusDisplay {
    switch (status) {
      case 'pending_otp':
        return 'Pending OTP';
      case 'active':
        return 'On Track';
      case 'due_soon':
        return 'Due Soon';
      case 'overdue':
        return 'Overdue';
      case 'completed':
        return 'Completed';
      case 'defaulted':
        return 'Defaulted';
      default:
        return 'Active';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending_otp':
        return const Color(0xFF6B7280); // Grey
      case 'active':
      case 'completed':
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

  @override
  List<Object?> get props => [
    id,
    lenderId,
    userId,
    borrowerName,
    amount,
    status,
    progress,
    startDate,
    type,
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