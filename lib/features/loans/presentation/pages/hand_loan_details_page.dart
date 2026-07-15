import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/theme.dart';
import '../../../../data/models/loan_model.dart';
import '../../../../core/blocs/loans/loan_cubit.dart';
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
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _profileCard(context, activeLoan),
                SizedBox(height: 16.h),
                _statsCard(activeLoan),
                SizedBox(height: 16.h),
                _emiOverviewCard(activeLoan),
                SizedBox(height: 16.h),
                _paymentChecklist(activeLoan),
                SizedBox(height: 16.h),
                _proofDocumentSection(context, activeLoan),
                SizedBox(height: 16.h),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Profile Card ─────────────────────────────────────────────────────────

  Widget _profileCard(BuildContext context, LoanModel loan) {
    String? currentUserId;
    try {
      final authState = context.read<AuthCubit>().state;
      if (authState is AuthenticatedFull) currentUserId = authState.user.id;
      if (authState is AuthenticatedUnverified)
        currentUserId = authState.user.id;
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
                    if (await canLaunchUrl(uri))
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
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

  // ─── Stats Card ───────────────────────────────────────────────────────────

  Widget _statsCard(LoanModel loan) {
    final startStr = _dateStr(loan.startDate);
    final endStr = loan.endDate != null ? _dateStr(loan.endDate!) : '-';
    final duration = loan.durationMonths ?? 0;
    final progress = loan.progress.clamp(0.0, 1.0);
    final paidMonths = (duration * progress).round();

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
                _statusChip(loan.status),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _stat('Principal Amount', '₹${_fmt(loan.amount)}'),
                    ),
                    Expanded(child: _stat('Duration', '$duration Months')),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(child: _stat('Start Date', startStr)),
                    Expanded(child: _stat('End Date', endStr)),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: _stat('Paid Months', '$paidMonths / $duration'),
                    ),
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
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade500),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: valueColor ?? Colors.black87,
          ),
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

  // ─── Credit Overview Card (gradient) ─────────────────────────────────────────

  Widget _emiOverviewCard(LoanModel loan) {
    final duration = loan.durationMonths ?? 0;
    final emi = loan.emiAmount ?? 0.0;
    final totalPayable = loan.totalPayableAmount ?? (emi * duration);
    final progress = loan.progress.clamp(0.0, 1.0);
    final paidMonths = (duration * progress).round();
    final amountPaid = emi * paidMonths;
    final amountPending = totalPayable - amountPaid;

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
            children: [
              Expanded(
                child: _gradientStat(
                  'Total Payable',
                  totalPayable > 0 ? '₹${_fmt(totalPayable)}' : '-',
                ),
              ),
              Expanded(
                child: _gradientStat('Amount Paid', '₹${_fmt(amountPaid)}'),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _gradientStat(
                  'Amount Pending',
                  '₹${_fmt(amountPending)}',
                ),
              ),
              Expanded(child: const SizedBox()),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _gradientStat('Paid Months', '$paidMonths / $duration'),
              ),
              Expanded(
                child: _gradientStat(
                  'Remaining',
                  '${duration - paidMonths} months',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _gradientStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white60, fontSize: 10.sp),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  // ─── Payment Checklist ────────────────────────────────────────────────────

  Widget _paymentChecklist(LoanModel loan) {
    final duration = loan.durationMonths ?? 0;
    final progress = loan.progress.clamp(0.0, 1.0);
    final paidMonths = (duration * progress).round();
    final emi = loan.emiAmount ?? 0.0;

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
            'Monthly Payments',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '$paidMonths of $duration months paid',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade500),
          ),
          SizedBox(height: 12.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade100,
              valueColor: const AlwaysStoppedAnimation<Color>(_primary),
              minHeight: 10.h,
            ),
          ),
          SizedBox(height: 16.h),
          if (duration > 0)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: List.generate(duration, (index) {
                  final isPaid = index < paidMonths;
                  final dueDate = loan.startDate.add(
                    Duration(days: (index + 1) * 30),
                  );
                  return Container(
                    width: 140.w,
                    margin: EdgeInsets.only(right: 12.w, bottom: 8.h),
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: isPaid ? _bg.withOpacity(0.5) : Colors.white,
                      border: Border.all(
                        color: isPaid
                            ? _primary.withOpacity(0.3)
                            : Colors.grey.shade200,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Month ${index + 1}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: isPaid ? _primary : Colors.grey.shade700,
                              ),
                            ),
                            Icon(
                              isPaid
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              size: 16.sp,
                              color: isPaid ? _primary : Colors.grey.shade400,
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          '${_month(dueDate.month)} ${dueDate.year}',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Due: ${dueDate.day}',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.grey.shade400,
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

  // ─── Proof Document Section ───────────────────────────────────────────────

  Widget _proofDocumentSection(BuildContext context, LoanModel loan) {
    if (loan.documentUrl == null || loan.documentUrl!.trim().isEmpty)
      return const SizedBox.shrink();

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
                        if (await canLaunchUrl(uri))
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
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

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _fmt(double v) {
    if (v.isNaN || v.isInfinite) return '0';
    return v
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
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
}
