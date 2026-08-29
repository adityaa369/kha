import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/theme.dart';
import '../../../../data/models/loan_model.dart';
import '../../../../core/blocs/loans/loan_cubit.dart';
import '../widgets/repayment_timeline_widget.dart';
import '../../../../core/blocs/loans/loan_state.dart';
import '../../../../core/blocs/auth/auth_cubit.dart';

class HandLoanDetailsPage extends StatelessWidget {
  final LoanModel loan;
  const HandLoanDetailsPage({super.key, required this.loan});

  static const _primary = Color(0xFF1B5E20);
  static const _bg = Color(0xFFE8F5E9);
  static const _accent = Color(0xFF388E3C);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoanCubit, LoanState>(
      builder: (context, state) {
        final activeLoan = state is LoansLoaded
            ? (state.myLoans + state.givenLoans).firstWhere(
                (l) => l.id == loan.id,
                orElse: () => loan,
              )
            : loan;

        return Scaffold(
          backgroundColor: KhaataTheme.backgroundGrey,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => context.pop(),
            ),
            title: Text(
              'Hand Credit Details',
              style: TextStyle(
                color: _primary,
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            centerTitle: true,
          ),
          body: RefreshIndicator(
            onRefresh: () async => context.read<LoanCubit>().fetchLoans(),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _profileCard(context, activeLoan),
                  SizedBox(height: 16.h),
                  _statsCard(activeLoan),
                  SizedBox(height: 16.h),
                  _repaymentChecklist(activeLoan),
                  SizedBox(height: 16.h),
                  _recentTransactions(activeLoan),
                  SizedBox(height: 16.h),
                  _creditOverviewCard(activeLoan),
                  SizedBox(height: 16.h),
                  _proofDocumentSection(context, activeLoan),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ———————————————————————————————————————————————————————————————————————————

  Widget _profileCard(BuildContext context, LoanModel loan) {
    String? currentUserId;
    try {
      final authState = context.read<AuthCubit>().state;
      if (authState is AuthenticatedFull) currentUserId = authState.user.id;
      if (authState is AuthenticatedUnverified) {
        currentUserId = authState.user.id;
      }
    } catch (_) {}

    final isLender = loan.lenderId == currentUserId;
    final phone = isLender ? (loan.mobile ?? '') : (loan.lenderPhone ?? '');
    final name = isLender
        ? (loan.borrowerName.isNotEmpty ? loan.borrowerName : 'Borrower')
        : (loan.lenderName?.isNotEmpty == true ? loan.lenderName! : 'Lender');
    final role = isLender ? 'Borrower' : 'Lender';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 52.w,
            height: 52.w,
            decoration: const BoxDecoration(color: _bg, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: TextStyle(
                color: _primary,
                fontWeight: FontWeight.w800,
                fontSize: 18.sp,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  role,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: _accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (phone.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        size: 12.sp,
                        color: Colors.grey,
                      ),
                      SizedBox(width: 4.w),
                      Flexible(
                        child: Text(
                          phone,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (phone.isNotEmpty)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _iconAction(
                  icon: Icons.phone,
                  color: Colors.blue.shade600,
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: phone));
                  },
                ),
                SizedBox(width: 12.w),
                _iconAction(
                  icon: Icons.chat_bubble_outline,
                  color: Colors.green.shade600,
                  onTap: () async {
                    final uri = Uri.parse('https://wa.me/91$phone');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _iconAction({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, size: 20.sp, color: color),
          ),
          SizedBox(height: 4.h),
          Text(
            icon == Icons.phone ? 'Call' : 'WhatsApp',
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€â”€ Stats Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _statsCard(LoanModel loan) {
    final actualStart = loan.startDate ?? loan.activatedAt ?? loan.createdAt ?? DateTime.now();
    final startStr = _dateStr(actualStart);
    final endStr = loan.endDate != null ? _dateStr(loan.endDate!) : _dateStr(actualStart.add(Duration(days: (loan.durationMonths ?? 0) * 30)));
    final duration = loan.durationMonths ?? 0;
    final progress = loan.progress.clamp(0.0, 1.0);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(14.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 5.h,
                  ),
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.handshake_outlined,
                        size: 14.sp,
                        color: _primary,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'Hand Credit',
                        style: TextStyle(
                          color: _primary,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(child: _statusChip(loan.status)),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _stat('Principal Amount', '₹${_fmt(loan.amount)}'),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(child: _stat('Duration', '$duration Months')),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _stat('Start Date', startStr)),
                    SizedBox(width: 12.w),
                    Expanded(child: _stat('End Date', endStr)),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    Expanded(
                      child: _stat(
                        'Progress',
                        '${(progress * 100).toStringAsFixed(0)}%',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: const AlwaysStoppedAnimation<Color>(_primary),
                    minHeight: 10.h,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w400,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 3.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.black87,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _statusChip(String status) {
    final color = _statusColor(status);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // â”€â”€â”€ Credit Overview Card (gradient) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _creditOverviewCard(LoanModel loan) {
    final duration = loan.durationMonths ?? 0;
    final emi = loan.emiAmount ?? 0.0;
    final totalPayable = loan.totalPayableAmount ?? (emi * duration);
    final progress = loan.progress.clamp(0.0, 1.0);
    final amountPaid = loan.paidAmount;
    final amountPending = loan.remainingAmount;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primary, _accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.white70,
                size: 16.sp,
              ),
              SizedBox(width: 6.w),
              Text(
                'Credit Overview',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _gradientStat(
                  'Total Payable',
                  totalPayable > 0 ? '₹${_fmt(totalPayable)}' : '-',
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _gradientStat('Amount Paid', '₹${_fmt(amountPaid)}'),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _gradientStat(
                  'Amount Pending',
                  '₹${_fmt(amountPending)}',
                ),
              ),
              SizedBox(width: 12.w),
              const Expanded(child: SizedBox()),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _gradientStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white60, fontSize: 11.sp, fontWeight: FontWeight.w400),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 3.h),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // â”€â”€â”€ Payment Checklist â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _proofDocumentSection(BuildContext context, LoanModel loan) {
    if (loan.documentUrl == null || loan.documentUrl!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final url = loan.documentUrl!;
    final isPdf = url.toLowerCase().contains('.pdf');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Agreement & Proof Document',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12.h),
          InkWell(
            onTap: () => _showDocumentDialog(context, url, isPdf),
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: _bg,
                border: Border.all(color: _primary.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: isPdf
                        ? const Icon(
                            Icons.picture_as_pdf,
                            color: Color(0xFFDC2626),
                            size: 22,
                          )
                        : Image.network(
                            url,
                            fit: BoxFit.cover,
                            cacheWidth: 200,
                            loadingBuilder: (_, child, p) => p == null
                                ? child
                                : const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.image,
                              color: _primary,
                              size: 22,
                            ),
                          ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPdf
                              ? 'Signed_Agreement_Hand_Credit.pdf'
                              : 'Proof_Document_Hand_Credit.jpg',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Tap to view proof document',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.visibility_outlined, color: _primary, size: 18.sp),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDocumentDialog(BuildContext context, String url, bool isPdf) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        backgroundColor: Colors.white,
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      isPdf ? 'Agreement & Signature' : 'Proof Document',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black54),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Container(
                color: Colors.grey.shade50,
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                child: isPdf ? _pdfPreview() : _imagePreview(url),
              ),
            ),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse(url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                      icon: Icon(Icons.open_in_new, size: 16.sp),
                      label: Text(
                        'Open External',
                        style: TextStyle(fontSize: 13.sp),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primary,
                        side: const BorderSide(color: _primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: Text(
                        'Close',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePreview(String url) {
    return SizedBox(
      width: double.infinity,
      height: 300.h,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            url,
            fit: BoxFit.contain,
            cacheWidth: 1080,
            loadingBuilder: (_, child, p) => p == null
                ? child
                : const Center(
                    child: CircularProgressIndicator(color: _primary),
                  ),
            errorBuilder: (_, __, ___) => const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.broken_image, color: Colors.grey, size: 48),
                  SizedBox(height: 8),
                  Text(
                    'Failed to load image',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pdfPreview() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFFEE2E2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.picture_as_pdf,
              color: Color(0xFFDC2626),
              size: 48,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'PDF Document',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Tap "Open External" to view in your browser or PDF reader.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€â”€ Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  String _fmt(double v) {
    if (v.isNaN || v.isInfinite) return '0';
    return NumberFormat('#,##,##0', 'en_IN').format(v);
  }

  String _dateStr(DateTime d) => '${d.day} ${_month(d.month)} ${d.year}';

  String _month(int m) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (m < 1 || m > 12) return 'Jan';
    return months[m - 1];
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'active':
        return Colors.green.shade700;
      case 'closed':
      case 'completed':
        return Colors.grey.shade600;
      case 'pending_otp':
      case 'pending_approval':
        return const Color(0xFFD97706);
      default:
        return Colors.blueGrey;
    }
  }

  String _statusLabel(String s) {
    switch (s.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'closed':
        return 'Closed';
      case 'completed':
        return 'Completed';
      case 'pending_otp':
        return 'Pending OTP';
      case 'pending_approval':
        return 'Pending Approval';
      default:
        return s;
    }
  }

  Widget _recentTransactions(LoanModel loan) {
    final txns = loan.transactions.reversed.toList(); // newest first
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: Colors.black87),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                '${txns.length} records',
                style: TextStyle(fontSize: 11.sp, color: _primary, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        if (txns.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.receipt_long_outlined, color: Colors.grey.shade400, size: 32.sp),
                SizedBox(height: 8.h),
                Text('No transactions recorded yet', style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
                SizedBox(height: 4.h),
                Text('Use Record Payment below to log payments', style: TextStyle(color: Colors.grey.shade400, fontSize: 11.sp)),
              ],
            ),
          )
        else
          ...txns.map((tx) => _txItem(
            _txIcon(tx.type as String? ?? ''),
            _txColor(tx.type as String? ?? ''),
            _txTitle(tx.type as String? ?? ''),
            tx.note as String? ?? '',
            _txAmountStr(tx.type as String? ?? '', (tx.amount as num?)?.toDouble() ?? 0),
            _txDateStr(tx.recordedAt),
            _txIsPositive(tx.type as String? ?? ''),
          )),
      ],
    );
  }

  IconData _txIcon(String type) {
    switch (type) {
      case 'payment': return Icons.arrow_downward;
      case 'interest_payment': return Icons.percent;
      case 'credit_added': return Icons.add_circle_outline;
      case 'loan_given': return Icons.arrow_upward;
      default: return Icons.swap_horiz;
    }
  }

  Color _txColor(String type) {
    switch (type) {
      case 'payment': return Colors.green.shade600;
      case 'interest_payment': return Colors.teal.shade600;
      case 'credit_added': return Colors.orange.shade600;
      case 'loan_given': return Colors.red.shade400;
      default: return Colors.grey;
    }
  }

  String _txTitle(String type) {
    switch (type) {
      case 'payment': return 'Payment Received';
      case 'interest_payment': return 'Interest Received';
      case 'credit_added': return 'Credit Added';
      case 'loan_given': return 'Loan Disbursed';
      default: return 'Transaction';
    }
  }

  String _txAmountStr(String type, double amount) {
    final sign = type == 'loan_given' ? '-' : '+';
    return '$sign₹${_fmt(amount)}';
  }

  bool _txIsPositive(String type) => type != 'loan_given';

  String _txDateStr(dynamic rawDate) {
    if (rawDate == null) return '';
    try {
      final dt = DateTime.parse(rawDate.toString()).toLocal();
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return '';
    }
  }

  Widget _txItem(IconData icon, Color color, String title, String subtitle, String amount, String date, bool isPositive) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 16.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp, color: Colors.black87)),
                SizedBox(height: 2.h),
                Text(subtitle, style: TextStyle(color: Colors.grey, fontSize: 11.sp)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp, color: isPositive ? Colors.green.shade700 : Colors.red.shade600)),
              SizedBox(height: 2.h),
              Text(date, style: TextStyle(color: Colors.grey, fontSize: 11.sp)),
            ],
          ),
        ],
      ),
    );
  }



  Widget _repaymentChecklist(LoanModel loan) {
    final duration = loan.durationMonths ?? 0;
    final progress = loan.progress.clamp(0.0, 1.0);
    final paidMonths = (duration * progress).round();

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loan.type.toLowerCase().contains('interest') || loan.type.toLowerCase().contains('home')
                ? 'Monthly Interest Overview'
                : 'Monthly Payment Overview',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: Colors.black87),
          ),
          SizedBox(height: 12.h),
          if (duration > 0)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: List.generate(duration, (index) {
                  final isPaid = index < paidMonths;
                  final dueDate = (loan.startDate ?? loan.activatedAt ?? loan.createdAt ?? DateTime.now()).add(Duration(days: (index + 1) * 30));

                  return Container(
                    margin: EdgeInsets.only(right: 12.w),
                    child: Column(
                      children: [
                        Text(
                          '${_monthName(dueDate.month)} ${dueDate.year}',
                          style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade600),
                        ),
                        SizedBox(height: 6.h),
                        Container(
                          width: 50.w,
                          height: 55.h,
                          decoration: BoxDecoration(
                            color: isPaid ? Colors.green.shade50 : Colors.white,
                            border: Border.all(color: isPaid ? Colors.green : Colors.red.shade200, width: 1.5),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            isPaid ? Icons.check : Icons.close,
                            color: isPaid ? Colors.green : Colors.red.shade300,
                            size: 20.sp,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  String _monthName(int m) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[m - 1];
  }

}
