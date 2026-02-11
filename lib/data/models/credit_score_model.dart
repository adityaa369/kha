import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class CreditScoreModel extends Equatable {
  final String? id;
  final String userId;
  final int cibilScore;
  final int experianScore;
  final String status;
  final int cibilDaysLeft;
  final int experianDaysLeft;
  final DateTime? cibilUpdatedAt;
  final DateTime? experianUpdatedAt;
  final DateTime? createdAt;
  final List<CreditFactor> factors;

  const CreditScoreModel({
    this.id,
    required this.userId,
    required this.cibilScore,
    required this.experianScore,
    required this.status,
    required this.cibilDaysLeft,
    required this.experianDaysLeft,
    this.cibilUpdatedAt,
    this.experianUpdatedAt,
    this.createdAt,
    required this.factors,
  });

  factory CreditScoreModel.fromJson(Map<String, dynamic> json) {
    return CreditScoreModel(
      id: json['id']?.toString(),
      userId: json['user_id'] ?? '',
      cibilScore: json['cibil_score'] ?? 0,
      experianScore: json['experian_score'] ?? 0,
      status: json['status'] ?? 'Processing',
      cibilDaysLeft: _calculateDaysLeft(json['cibil_updated_at']),
      experianDaysLeft: _calculateDaysLeft(json['experian_updated_at']),
      cibilUpdatedAt: json['cibil_updated_at'] != null
          ? DateTime.parse(json['cibil_updated_at'])
          : null,
      experianUpdatedAt: json['experian_updated_at'] != null
          ? DateTime.parse(json['experian_updated_at'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      factors: (json['factors'] as List?)
          ?.map((e) => CreditFactor.fromJson(e))
          .toList() ?? [],
    );
  }

  // For Supabase insert/update
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'cibil_score': cibilScore,
      'experian_score': experianScore,
      'status': status,
      'cibil_updated_at': cibilUpdatedAt?.toIso8601String(),
      'experian_updated_at': experianUpdatedAt?.toIso8601String(),
    };
  }

  // Calculate days until next update (typically 30 days from last update)
  static int _calculateDaysLeft(String? lastUpdated) {
    if (lastUpdated == null) return 30;

    final lastUpdate = DateTime.parse(lastUpdated);
    final nextUpdate = lastUpdate.add(const Duration(days: 30));
    final daysLeft = nextUpdate.difference(DateTime.now()).inDays;

    return daysLeft > 0 ? daysLeft : 0;
  }

  // Get overall score (average of both)
  int get overallScore => ((cibilScore + experianScore) / 2).round();

  // Get color based on score
  Color getScoreColor() {
    final score = overallScore;
    if (score >= 750) return const Color(0xFF10B981); // Green
    if (score >= 650) return const Color(0xFFF59E0B); // Yellow
    if (score >= 550) return const Color(0xFFF97316); // Orange
    return const Color(0xFFEF4444); // Red
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    cibilScore,
    experianScore,
    status,
    cibilDaysLeft,
    experianDaysLeft,
    factors,
  ];
}

class CreditFactor extends Equatable {
  final String? id;
  final String title;
  final String subtitle;
  final String value;
  final String detailLabel;
  final String status; // 'good', 'bad', 'neutral'
  final String? impactLevel; // 'high', 'medium', 'low'
  final IconData icon;

  const CreditFactor({
    this.id,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.detailLabel,
    required this.status,
    this.impactLevel,
    required this.icon,
  });

  factory CreditFactor.fromJson(Map<String, dynamic> json) {
    return CreditFactor(
      id: json['id']?.toString(),
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      value: json['value'] ?? '',
      detailLabel: json['detail_label'] ?? '',
      status: json['status'] ?? 'neutral',
      impactLevel: json['impact_level'],
      icon: _getIconFromString(json['icon'] ?? json['title'] ?? 'info'),
    );
  }

  // For Supabase insert
  Map<String, dynamic> toJson(String userId) {
    return {
      'user_id': userId,
      'title': title,
      'subtitle': subtitle,
      'value': value,
      'detail_label': detailLabel,
      'status': status,
      'impact_level': impactLevel,
      'icon': _getStringFromIcon(icon),
    };
  }

  static IconData _getIconFromString(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'payments':
      case 'payment':
        return Icons.access_time;
      case 'limit':
      case 'credit utilization':
        return Icons.show_chart;
      case 'age':
      case 'account age':
        return Icons.calendar_today;
      case 'accounts':
      case 'total accounts':
        return Icons.account_balance_wallet;
      case 'inquiries':
        return Icons.search;
      case 'mix':
      case 'credit mix':
        return Icons.account_tree;
      default:
        return Icons.info;
    }
  }

  static String _getStringFromIcon(IconData icon) {
    if (icon == Icons.access_time) return 'payments';
    if (icon == Icons.show_chart) return 'limit';
    if (icon == Icons.calendar_today) return 'age';
    if (icon == Icons.account_balance_wallet) return 'accounts';
    if (icon == Icons.search) return 'inquiries';
    if (icon == Icons.account_tree) return 'mix';
    return 'info';
  }

  Color getStatusColor() {
    switch (status) {
      case 'good':
        return const Color(0xFF10B981);
      case 'bad':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  List<Object?> get props => [id, title, subtitle, value, status];
}