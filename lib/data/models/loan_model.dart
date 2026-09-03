import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

enum LoanStatus {
  pendingApproval('pending_approval'),
  pendingOtp('pending_otp'),
  active('active'),
  completed('completed'),
  overdue('overdue'),
  dueSoon('due_soon'),
  defaulted('defaulted'),
  rejected('rejected'),
  closed('closed');

  final String value;
  const LoanStatus(this.value);

  bool get isPending => this == LoanStatus.pendingApproval || this == LoanStatus.pendingOtp;
  bool get isFinished => this == LoanStatus.completed || this == LoanStatus.closed || this == LoanStatus.defaulted || this == LoanStatus.rejected;

  factory LoanStatus.fromString(String status) {
    return LoanStatus.values.firstWhere(
      (e) => e.value == status,
      orElse: () => LoanStatus.active,
    );
  }
}

class TransactionModel extends Equatable {
  final String type;
  final int amountPaise;
  final String? note;
  final DateTime? recordedAt;
  final String? recordedBy;

  const TransactionModel({
    required this.type,
    required this.amountPaise,
    this.note,
    this.recordedAt,
    this.recordedBy,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      type: json['type'] ?? 'payment',
      amountPaise: json['amountPaise'] is int 
          ? json['amountPaise'] 
          : ((json['amount'] is num ? json['amount'] : 0.0) * 100).toInt(),
      note: json['note'],
      recordedAt: _parseDate(json['recordedAt']),
      recordedBy: json['recordedBy'],
    );
  }

  double get amount => amountPaise / 100;

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => [type, amountPaise, note, recordedAt, recordedBy];
}

class MonthTrackingModel extends Equatable {
  final int monthIndex;
  final String status;
  final DateTime? markedPaidAt;
  final String? markedBy;

  const MonthTrackingModel({
    required this.monthIndex,
    required this.status,
    this.markedPaidAt,
    this.markedBy,
  });

  factory MonthTrackingModel.fromJson(Map<String, dynamic> json) {
    return MonthTrackingModel(
      monthIndex: json['monthIndex'] as int? ?? 1,
      status: json['status'] as String? ?? 'unpaid',
      markedPaidAt: json['markedPaidAt'] != null ? DateTime.tryParse(json['markedPaidAt'].toString()) : null,
      markedBy: json['markedBy'] as String?,
    );
  }

  @override
  List<Object?> get props => [monthIndex, status, markedPaidAt, markedBy];
}

class LoanModel extends Equatable {
  final String id;
  final String? lenderId;
  final String? userId; // borrowerId
  final String borrowerName;
  final String? lenderName;
  final String? lenderPhone;
  final String initials;
  final int amountPaise; // Authoritative Backend Value
  final double? interestRate;
  final int? durationMonths;
  final String status;
  final double progress;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? activatedAt;
  final String type; // e.g. personal, home, business
  final String? mobile;
  final String? aadhar;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  final int emiAmountPaise;
  final int totalPayablePaise;
  final int paidAmountPaise;
  final int principalOutstandingPaise;
  final int interestOutstandingPaise;
  final int feesOutstandingPaise;
  final String? financialStatus;

  final String? documentId;
  final List<TransactionModel> transactions;
  final List<MonthTrackingModel> monthsTracking;

  const LoanModel({
    required this.id,
    this.lenderId,
    this.userId,
    required this.borrowerName,
    this.lenderName,
    this.lenderPhone,
    required this.initials,
    required this.amountPaise,
    this.interestRate,
    this.durationMonths,
    required this.status,
    required this.progress,
    this.startDate,
    this.endDate,
    this.activatedAt,
    required this.type,
    this.mobile,
    this.aadhar,
    this.createdAt,
    this.updatedAt,
    this.emiAmountPaise = 0,
    this.totalPayablePaise = 0,
    this.paidAmountPaise = 0,
    this.principalOutstandingPaise = 0,
    this.interestOutstandingPaise = 0,
    this.feesOutstandingPaise = 0,
    this.financialStatus,
    this.documentId,
    this.transactions = const [],
    this.monthsTracking = const [],
  });

  factory LoanModel.fromJson(Map<String, dynamic> json) {
    int parsePaise(String paiseKey, String amountKey) {
      if (json[paiseKey] is int) return json[paiseKey];
      final amt = _parseDouble(json[amountKey]);
      if (amt != null) return (amt * 100).toInt();
      return 0;
    }

    List<TransactionModel> parseTransactions(dynamic txns) {
      if (txns is List) {
        return txns.map((t) => TransactionModel.fromJson(t as Map<String, dynamic>)).toList();
      }
      return [];
    }

    List<MonthTrackingModel> parseMonthsTracking(dynamic months) {
      if (months is List) {
        return months.map((m) => MonthTrackingModel.fromJson(m as Map<String, dynamic>)).toList();
      }
      return [];
    }

    return LoanModel(
      id: json['_id'] ?? json['id']?.toString() ?? '',
      lenderId: json['lender_id']?.toString() ?? json['lender']?.toString(),
      userId: json['user_id']?.toString() ?? json['borrower']?.toString(),
      borrowerName: json['borrowerName'] ?? json['borrower_name'] ?? '',
      lenderName: json['lenderName'] ?? json['lender_name'],
      lenderPhone: json['lenderPhone']?.toString() ?? json['lender_phone']?.toString(),
      initials: json['initials'] ?? _generateInitials(json['lenderName'] ?? json['borrowerName'] ?? json['borrower_name'] ?? ''),
      amountPaise: parsePaise('amountPaise', 'amount'),
      interestRate: _parseDouble(json['interestRate']) ?? _parseDouble(json['interest_rate']),
      durationMonths: json['durationMonths'] is int
          ? json['durationMonths']
          : int.tryParse(json['durationMonths']?.toString() ?? ''),
      status: json['status'] ?? 'pending_approval',
      progress: _parseDouble(json['progress']) ?? 0.0,
      startDate: TransactionModel._parseDate(json['startDate'] ?? json['start_date']),
      endDate: TransactionModel._parseDate(json['endDate'] ?? json['end_date']),
      activatedAt: TransactionModel._parseDate(json['activatedAt'] ?? json['activated_at']),
      type: json['loanType'] ?? json['type'] ?? 'personal',
      mobile: json['borrowerPhone']?.toString() ?? json['mobile']?.toString(),
      aadhar: json['borrowerAadhar']?.toString() ?? json['aadhar']?.toString(),
      createdAt: TransactionModel._parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: TransactionModel._parseDate(json['updatedAt'] ?? json['updated_at']),
      emiAmountPaise: parsePaise('emiAmountPaise', 'emiAmount'),
      totalPayablePaise: parsePaise('totalPayablePaise', 'totalPayable'),
      paidAmountPaise: parsePaise('paidAmountPaise', 'paidAmount'),
      principalOutstandingPaise: parsePaise('principalOutstandingPaise', 'principalOutstanding'),
      interestOutstandingPaise: parsePaise('interestOutstandingPaise', 'interestOutstanding'),
      feesOutstandingPaise: parsePaise('feesOutstandingPaise', 'feesOutstanding'),
      financialStatus: json['financialStatus'],
      documentId: json['documentId'] ?? json['documentUrl'] ?? json['document_url'],
      transactions: parseTransactions(json['transactions']),
      monthsTracking: parseMonthsTracking(json['monthsTracking']),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
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

  Map<String, dynamic> toJsonForCreate() {
    return {
      'borrower_name': borrowerName,
      'borrower_phone': mobile,
      'borrower_aadhar': aadhar,
      'amount': amount, // Fixed: Sends explicit rupees to backend
      'interest_rate': interestRate,
      'duration_months': durationMonths,
      'type': type,
      'documentId': documentId,
    };
  }

  // --- Presentation Helpers ---

  double get amount => amountPaise / 100;
  double get emiAmount => emiAmountPaise / 100;
  double get totalPayableAmount => totalPayablePaise / 100;
  
  // 4F-4 Presentation-derived total
  int get totalOutstandingPaise => principalOutstandingPaise + interestOutstandingPaise + feesOutstandingPaise;
  double get totalOutstandingAmount => totalOutstandingPaise / 100;
  double get paidAmount => paidAmountPaise / 100;

  
  String? get otp => id.length >= 6 ? id.substring(0, 6) : null;
  LoanStatus get loanStatus => LoanStatus.fromString(status);
  double? get totalPayable => totalPayablePaise > 0 ? totalPayableAmount : null;
  Color get statusColor {
    switch (status) {
      case 'pending_approval':
      case 'pending_otp':
        return const Color(0xFFF59E0B);
      case 'active':
      case 'completed':
      case 'closed':
        return const Color(0xFF10B981);
      case 'due_soon':
        return const Color(0xFFF59E0B);
      case 'overdue':
      case 'defaulted':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF10B981);
    }
  }

  double get remainingAmount {
    return (totalPayablePaise - paidAmountPaise) / 100;
  }

  String get displayCounterpartyName {
    if (lenderName != null && lenderName!.isNotEmpty) return lenderName!;
    return borrowerName;
  }

  String get displayType {
    final t = type.toLowerCase();
    if (t == 'personal' || t == 'hand_credit') return 'Hand Credit';
    if (t == 'business' || t == 'business_credit') return 'Business Credit';
    if (t == 'home' || t == 'interest_credit') return 'Interest Credit';
    if (t == 'chitfund') return 'Chit Funds';
    return type.toUpperCase();
  }

  String get displayAmount {
    if (amountPaise == 0) return '-';
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
    return NumberFormat('#,##,##0', 'en_IN').format(number);
  }

  String get statusDisplay {
    switch (status) {
      case 'pending_approval': return 'Pending Approval';
      case 'pending_otp': return 'Pending Setup';
      case 'active': return 'On Track';
      case 'due_soon': return 'Due Soon';
      case 'overdue': return 'Overdue';
      case 'completed':
      case 'closed': return 'Completed';
      case 'defaulted': return 'Defaulted';
      default: return 'Active';
    }
  }

  @override
  List<Object?> get props => [
    id, lenderId, userId, borrowerName, lenderName, lenderPhone,
    amountPaise, status, progress, startDate, type, emiAmountPaise,
    totalPayablePaise, documentId, paidAmountPaise, transactions, monthsTracking
  ];
}


