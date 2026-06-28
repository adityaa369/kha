import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/constants.dart';
import '../../../../config/theme.dart';
import '../../../../data/models/loan_model.dart';
import '../../../../core/blocs/loans/loan_cubit.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/blocs/loans/loan_state.dart';
import '../widgets/flexible_payment_sheet.dart';

class LenderLoanDetailsPage extends StatelessWidget {
  final LoanModel loan;
  const LenderLoanDetailsPage({super.key, required this.loan});

  // ─── Theme by loan type ──────────────────────────────────────────────────

  static const _typeColors = {
    'hand_credit':     _TypeTheme(Color(0xFF1B5E20), Color(0xFFE8F5E9), 'Hand Credit'),
    'business_credit': _TypeTheme(Color(0xFF1565C0), Color(0xFFE3F2FD), 'Business Credit'),
    'interest_credit': _TypeTheme(Color(0xFFE65100), Color(0xFFFFF3E0), 'Interest Credit'),
  };

  _TypeTheme _theme(String type) =>
      _typeColors[type] ?? const _TypeTheme(Color(0xFF37474F), Color(0xFFECEFF1), 'Loan');

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoanCubit, LoanState>(
      listener: (context, state) {
        if (state is LoanError) {
          ErrorHandler.showError(context, state.message);
        }
      },
      builder: (context, state) {
        final activeLoan = state is LoansLoaded
            ? (state.myLoans + state.givenLoans)
                .firstWhere((l) => l.id == loan.id, orElse: () => loan)
            : loan;

        final theme      = _theme(activeLoan.type);
        final duration   = activeLoan.durationMonths ?? 1;
        final progress   = activeLoan.progress.clamp(0.0, 1.0);
        final paidMonths = (duration * progress).round();
        final isClosed   = activeLoan.status == 'closed' || activeLoan.status == 'completed';
        final isPending  = activeLoan.status == 'pending_otp' || activeLoan.status == 'pending_approval';
        final isLoading  = state is LoanLoading;

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
              '${theme.label} — Lender View',
              style: TextStyle(color: theme.primary, fontSize: 15.sp, fontWeight: FontWeight.w700),
            ),
            centerTitle: true,
          ),
          bottomNavigationBar: _bottomBar(context, activeLoan, theme, isClosed, isPending),
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _borrowerCard(activeLoan, theme),
                    SizedBox(height: 14.h),
                    _summaryCard(activeLoan, theme, duration, paidMonths, progress),
                    SizedBox(height: 14.h),
                    if (!isPending) ...[
                      _repaymentChecklist(context, activeLoan, theme, duration, paidMonths),
                      if (activeLoan.documentUrl != null && activeLoan.documentUrl!.isNotEmpty) ...[
                        _documentSection(context, activeLoan, theme),
                        SizedBox(height: 16.h),
                      ],
                      if (!isClosed && !isPending) ...[
                        _transactionButtons(context, activeLoan, theme, isLoading),
                        SizedBox(height: 24.h),
                      ],
                    ],
                    if (isPending) _pendingCard(activeLoan),
                    SizedBox(height: 80.h), // space for bottom bar
                  ],
                ),
              ),
              if (isLoading)
                Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        );
      },
    );
  }

  // ─── Borrower Card ────────────────────────────────────────────────────────

  Widget _borrowerCard(LoanModel loan, _TypeTheme theme) {
    final name    = loan.borrowerName.isNotEmpty ? loan.borrowerName : 'Borrower';
    final initial = name[0].toUpperCase();
    final phone   = loan.mobile ?? '';

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
            decoration: BoxDecoration(color: theme.bg, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: TextStyle(color: theme.primary, fontWeight: FontWeight.w800, fontSize: 18.sp),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: Colors.black87)),
                SizedBox(height: 2.h),
                Text('Borrower', style: TextStyle(fontSize: 11.sp, color: theme.primary, fontWeight: FontWeight.w600)),
                if (phone.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Row(children: [
                    Icon(Icons.phone_outlined, size: 12.sp, color: Colors.grey),
                    SizedBox(width: 4.w),
                    Text(phone, style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600)),
                  ]),
                ],
              ],
            ),
          ),
          if (phone.isNotEmpty)
            Row(mainAxisSize: MainAxisSize.min, children: [
              _iconBtn(Icons.phone, Colors.blue.shade600, () {
                Clipboard.setData(ClipboardData(text: phone));
              }),
              SizedBox(width: 10.w),
              _iconBtn(Icons.chat_bubble_outline, Colors.green.shade600, () async {
                final uri = Uri.parse('https://wa.me/91$phone');
                if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
              }),
            ]),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8.r)),
        child: Icon(icon, size: 20.sp, color: color),
      ),
    );
  }

  // ─── Summary Card ─────────────────────────────────────────────────────────

  Widget _summaryCard(LoanModel loan, _TypeTheme theme, int duration, int paidMonths, double progress) {
    final start = _dateStr(loan.startDate);
    final end   = loan.endDate != null ? _dateStr(loan.endDate!) : '-';
    final rate  = loan.interestRate ?? 0.0;
    final monthly = rate > 0 ? loan.amount * rate / 100 : (loan.emiAmount ?? 0.0);
    final totalPayable = (loan.totalPayableAmount ?? 0.0) > 0
        ? loan.totalPayableAmount!
        : loan.amount + (monthly * duration);
    final collected = monthly * paidMonths;
    final remaining = totalPayable - collected;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Badge row
          Padding(
            padding: EdgeInsets.all(14.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _badge(theme, loan.type),
                _statusChip(loan.status),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade100),

          Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              children: [
                Row(children: [
                  Expanded(child: _stat('Principal', '₹${_fmt(loan.amount)}')),
                  Expanded(child: _stat('Duration', '$duration months')),
                ]),
                SizedBox(height: 12.h),
                Row(children: [
                  Expanded(child: _stat('Start Date', start)),
                  Expanded(child: _stat('End Date', end)),
                ]),
                SizedBox(height: 12.h),
                Row(children: [
                  Expanded(child: _stat('Paid Months', '$paidMonths / $duration')),
                  Expanded(child: _stat('Progress', '${(progress * 100).toStringAsFixed(0)}%')),
                ]),
                if (monthly > 0) ...[
                  SizedBox(height: 12.h),
                  Row(children: [
                    Expanded(child: _stat('Collected', '₹${_fmt(collected)}', valueColor: Colors.green.shade700)),
                    Expanded(child: _stat('Remaining', '₹${_fmt(remaining)}', valueColor: Colors.red.shade600)),
                  ]),
                ],
                SizedBox(height: 16.h),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
                    minHeight: 8.h,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(_TypeTheme theme, String type) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(color: theme.bg, borderRadius: BorderRadius.circular(20.r)),
      child: Text(theme.label, style: TextStyle(color: theme.primary, fontSize: 11.sp, fontWeight: FontWeight.w700)),
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
      child: Text(_statusLabel(status),
          style: TextStyle(color: color, fontSize: 11.sp, fontWeight: FontWeight.w700)),
    );
  }

  Widget _stat(String label, String value, {Color? valueColor}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade500)),
      SizedBox(height: 3.h),
      Text(value,
          style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: valueColor ?? Colors.black87)),
    ]);
  }

  // ─── Repayment Checklist ──────────────────────────────────────────────────

  Widget _repaymentChecklist(
      BuildContext context, LoanModel loan, _TypeTheme theme, int duration, int paidMonths) {
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
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Monthly Repayment',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: Colors.black87)),
            Text('$paidMonths of $duration paid',
                style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade500)),
          ]),
          SizedBox(height: 4.h),
          Text('Tap a month to toggle paid / unpaid',
              style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade400)),
          SizedBox(height: 12.h),
          if (duration > 0)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: duration,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (context, index) {
                final isPaid  = index < paidMonths;
                final dueDate = loan.startDate.add(Duration(days: (index + 1) * 30));
                final rate    = loan.interestRate ?? 0.0;
                final monthly = rate > 0 ? loan.amount * rate / 100 : (loan.emiAmount ?? 0.0);

                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  child: Row(
                    children: [
                      // Tap to toggle checkbox
                      GestureDetector(
                        onTap: () => _toggleMonth(context, loan, index, paidMonths, duration),
                        child: Container(
                          width: 30.w,
                          height: 30.w,
                          decoration: BoxDecoration(
                            color: isPaid ? theme.primary : Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            isPaid ? Icons.check : Icons.radio_button_unchecked,
                            size: 16.sp,
                            color: isPaid ? Colors.white : Colors.grey.shade400,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(
                            'Month ${index + 1} — ${_monthName(dueDate.month)} ${dueDate.year}',
                            style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: isPaid ? Colors.black87 : Colors.black54),
                          ),
                          Text(
                            'Due: ${dueDate.day} ${_monthName(dueDate.month)} ${dueDate.year}',
                            style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade400),
                          ),
                        ]),
                      ),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(
                          monthly > 0 ? '₹${_fmt(monthly)}' : '-',
                          style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: isPaid ? Colors.green.shade700 : Colors.black54),
                        ),
                        Text(
                          isPaid ? 'Received' : 'Pending',
                          style: TextStyle(
                              fontSize: 9.sp,
                              color: isPaid ? Colors.green.shade600 : Colors.grey),
                        ),
                      ]),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _toggleMonth(BuildContext context, LoanModel loan, int monthIndex, int currentPaid, int duration) {
    final loanCubit = context.read<LoanCubit>();
    double newProgress;

    if (monthIndex < currentPaid) {
      // Mark this month and all after it as unpaid → set progress to monthIndex/duration
      newProgress = monthIndex / duration;
    } else {
      // Mark up to and including this month as paid
      newProgress = (monthIndex + 1) / duration;
    }

    newProgress = newProgress.clamp(0.0, 1.0);
    loanCubit.updateProgress(loan.id, newProgress);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: newProgress > loan.progress ? Colors.green.shade700 : Colors.orange.shade700,
      content: Text(newProgress > loan.progress
          ? 'Month ${monthIndex + 1} marked as paid ✓'
          : 'Month ${monthIndex + 1} marked as unpaid'),
      duration: const Duration(seconds: 2),
    ));
  }

  // ─── Document Section ─────────────────────────────────────────────────────

  Widget _documentSection(BuildContext context, LoanModel loan, _TypeTheme theme) {
    if (loan.documentUrl == null || loan.documentUrl!.trim().isEmpty) {
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(children: [
          Icon(Icons.description_outlined, color: Colors.grey.shade300, size: 28.sp),
          SizedBox(width: 12.w),
          Text('No document was uploaded', style: TextStyle(color: Colors.grey, fontSize: 13.sp)),
        ]),
      );
    }

    final url = loan.documentUrl!;
    final isPdf = url.toLowerCase().contains('.pdf');

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Agreement & Proof Document',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: Colors.black87)),
        SizedBox(height: 12.h),
        InkWell(
          onTap: () => _showDocumentDialog(context, url, isPdf, theme),
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: theme.bg,
              border: Border.all(color: theme.primary.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(color: theme.bg, borderRadius: BorderRadius.circular(8.r)),
                clipBehavior: Clip.antiAlias,
                child: isPdf
                    ? const Icon(Icons.picture_as_pdf, color: Color(0xFFDC2626), size: 22)
                    : Image.network(url, fit: BoxFit.cover,
                        loadingBuilder: (ctx, child, p) =>
                            p == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        errorBuilder: (_, __, ___) => Icon(Icons.image, color: theme.primary, size: 22)),
              ),
              SizedBox(width: 12.w),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  isPdf ? 'Signed_Agreement.pdf' : 'Proof_Document.jpg',
                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text('Tap to view uploaded document',
                    style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade600)),
              ])),
              Icon(Icons.visibility_outlined, color: theme.primary, size: 18.sp),
            ]),
          ),
        ),
      ]),
    );
  }

  void _showDocumentDialog(BuildContext context, String url, bool isPdf, _TypeTheme theme) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        backgroundColor: Colors.white,
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
              decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(isPdf ? 'Agreement & Signature' : 'Proof Document',
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black54),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ]),
            ),
            // Body
            Flexible(
              child: Container(
                color: Colors.grey.shade50,
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                child: isPdf ? _pdfWidget(context, url, theme) : _imageWidget(url),
              ),
            ),
            // Footer
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey.shade100))),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                    icon: Icon(Icons.open_in_new, size: 15.sp),
                    label: Text('Open External', style: TextStyle(fontSize: 12.sp)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.primary,
                      side: BorderSide(color: theme.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    child: Text('Close', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageWidget(String url) {
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
            loadingBuilder: (_, child, p) =>
                p == null ? child : const Center(child: CircularProgressIndicator()),
            errorBuilder: (_, __, ___) => const Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.broken_image, size: 48, color: Colors.grey),
                Text('Failed to load image', style: TextStyle(color: Colors.grey)),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pdfWidget(BuildContext context, String url, _TypeTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(color: Color(0xFFFEE2E2), shape: BoxShape.circle),
          child: const Icon(Icons.picture_as_pdf, color: Color(0xFFDC2626), size: 48),
        ),
        const SizedBox(height: 20),
        const Text('PDF Document', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Tap "Open External" to view in browser or PDF reader.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4)),
      ]),
    );
  }

  // ─── Transaction Buttons ──────────────────────────────────────────────────

  Widget _transactionButtons(BuildContext context, LoanModel loan, _TypeTheme theme, bool isLoading) {
    final t = loan.type.toLowerCase();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Manage Payments', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: Colors.black87)),
        SizedBox(height: 12.h),
        
        // Hand Credit
        if (t.contains('personal') || t.contains('hand')) ...[
          _actionButton(context, loan, 'Record Payment', Icons.payment, theme.primary, 'record_payment', isLoading),
        ],

        // Business Credit
        if (t.contains('business')) ...[
          _actionButton(context, loan, 'Record Payment', Icons.payment, theme.primary, 'record_payment', isLoading),
          SizedBox(height: 12.h),
          _actionButton(context, loan, 'Add Credit', Icons.add_card, theme.primary, 'add_credit', isLoading),
        ],

        // Interest Credit
        if (t.contains('interest') || t.contains('home')) ...[
          _actionButton(context, loan, 'Record Payment', Icons.payment, theme.primary, 'record_payment', isLoading),
          SizedBox(height: 12.h),
          _actionButton(context, loan, 'Record Interest Payment', Icons.percent, theme.primary, 'record_interest', isLoading),
        ],
      ],
    );
  }

  Widget _actionButton(BuildContext context, LoanModel loan, String label, IconData icon, Color color, String actionType, bool isLoading) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : () => FlexiblePaymentSheet.show(context, loan, label, actionType),
      icon: Icon(icon, size: 18.sp),
      label: Text(label, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        padding: EdgeInsets.symmetric(vertical: 14.h),
        alignment: Alignment.centerLeft,
      ),
    );
  }



  // ─── Pending Card ─────────────────────────────────────────────────────────

  Widget _pendingCard(LoanModel loan) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(children: [
        Icon(Icons.access_time_filled, color: const Color(0xFFD97706), size: 24.sp),
        SizedBox(height: 8.h),
        Text(
          loan.status == 'pending_otp' ? 'Pending OTP Verification' : 'Pending Borrower Signature',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp, color: const Color(0xFF92400E)),
        ),
        SizedBox(height: 6.h),
        Text(
          loan.status == 'pending_otp'
              ? 'An OTP was sent to the borrower. They must verify it to activate the loan.'
              : 'The borrower must accept and sign the agreement.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.sp, color: const Color(0xFFB45309)),
        ),
      ]),
    );
  }

  // ─── Bottom Bar ───────────────────────────────────────────────────────────

  Widget _bottomBar(BuildContext context, LoanModel loan, _TypeTheme theme, bool isClosed, bool isPending) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => context.pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black54,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                padding: EdgeInsets.symmetric(vertical: 14.h),
              ),
              child: Text('Back', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
            ),
          ),
          if (!isClosed && !isPending) ...[
            SizedBox(width: 12.w),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () => _initiateLoanClose(context, loan),
                icon: Icon(Icons.lock_outline, size: 16.sp),
                label: Text('Close Loan', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  // ─── Close Loan (OTP) ─────────────────────────────────────────────────────

  void _initiateLoanClose(BuildContext context, LoanModel loan) {
    final loanCubit    = context.read<LoanCubit>();
    final sm           = ScaffoldMessenger.of(context);
    final phone        = loan.mobile ?? '';
    if (phone.isEmpty) {
      sm.showSnackBar(const SnackBar(
          backgroundColor: Colors.red, content: Text('Borrower phone number missing')));
      return;
    }

    final formatted = phone.startsWith('+') ? phone : '+91$phone';

    // Show loading
    showDialog(context: context, barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()));

    FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: formatted,
      verificationCompleted: (_) {},
      verificationFailed: (e) {
        if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
        sm.showSnackBar(SnackBar(
            backgroundColor: Colors.red, content: Text('OTP failed: ${e.message}')));
      },
      codeSent: (String vId, int? _) {
        if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
        _showOtpDialog(context, loan, loanCubit, vId, formatted, sm);
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  void _showOtpDialog(BuildContext context, LoanModel loan, LoanCubit loanCubit,
      String vId, String phone, ScaffoldMessengerState sm) {
    final otpCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Closure', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('An OTP has been sent to the borrower ($phone). Enter it to confirm closure.'),
          const SizedBox(height: 16),
          TextField(
            controller: otpCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: InputDecoration(
              hintText: '6-digit OTP',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[100],
              counterText: '',
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              if (otpCtrl.text.length != 6) return;
              Navigator.pop(dialogContext);
              showDialog(context: context, barrierDismissible: false,
                  builder: (_) => const Center(child: CircularProgressIndicator()));

              final success = await loanCubit.closeLoan(loan.id, otpCtrl.text, vId);
              if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

              if (success && context.mounted) {
                context.go(AppConstants.loanCloseSuccess);
              } else {
                sm.showSnackBar(const SnackBar(
                    backgroundColor: Colors.red, content: Text('Invalid OTP. Closure failed.')));
              }
            },
            child: const Text('Confirm Close'),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _fmt(double v) {
    if (v.isNaN || v.isInfinite) return '0';
    return v.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  String _dateStr(DateTime d) => '${d.day} ${_monthName(d.month)} ${d.year}';

  String _monthName(int m) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    if (m < 1 || m > 12) return 'Jan';
    return months[m - 1];
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'active':   return Colors.green.shade700;
      case 'closed':
      case 'completed': return Colors.grey.shade600;
      case 'pending_otp':
      case 'pending_approval': return const Color(0xFFD97706);
      default: return Colors.blueGrey;
    }
  }

  String _statusLabel(String s) {
    switch (s.toLowerCase()) {
      case 'active':           return 'Active';
      case 'closed':           return 'Closed';
      case 'completed':        return 'Completed';
      case 'pending_otp':      return 'Pending OTP';
      case 'pending_approval': return 'Pending Approval';
      default:                 return s;
    }
  }
}

// ─── Theme helper class ───────────────────────────────────────────────────────

class _TypeTheme {
  final Color primary;
  final Color bg;
  final String label;
  const _TypeTheme(this.primary, this.bg, this.label);
}
