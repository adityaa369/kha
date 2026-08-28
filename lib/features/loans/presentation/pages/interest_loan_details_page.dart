import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/theme.dart';
import '../../../../data/models/loan_model.dart';
import '../../../../core/blocs/loans/loan_cubit.dart';
import '../widgets/repayment_timeline_widget.dart';
import '../../../../core/blocs/loans/loan_state.dart';
import '../../../../core/blocs/auth/auth_cubit.dart';

class InterestLoanDetailsPage extends StatelessWidget {
  final LoanModel loan;

  const InterestLoanDetailsPage({super.key, required this.loan});

  // â”€â”€â”€ Theme â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static const _primary = Color(0xFFE65100);
  static const _bg = Color(0xFFFFF3E0);
  static const _accent = Color(0xFFEF6C00);

  // â”€â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
              'Interest Credit Details',
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
                _interestInfoCard(activeLoan),
                SizedBox(height: 16.h),
                _paymentProgressCard(activeLoan),
                SizedBox(height: 16.h),
                _proofDocumentSection(context, activeLoan),
                SizedBox(height: 16.h),
                SizedBox(height: 8.h),
              ],
            ),
          ),
        );
      },
    );
  }

  // â”€â”€â”€ Profile Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    final roleLabel = isLender ? 'Borrower' : 'Lender';

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 52.w,
            height: 52.w,
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(26.r),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: TextStyle(
                color: _primary,
                fontWeight: FontWeight.w800,
                fontSize: 18.sp,
              ),
            ),
          ),
          SizedBox(width: 12.w),

          // Name + role + phone
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
                  roleLabel,
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

          // Call & WhatsApp icons
          if (phone.isNotEmpty)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _iconAction(
                  icon: Icons.phone,
                  color: Colors.blue.shade600,
                  tooltip: 'Call',
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: phone));
                  },
                ),
                SizedBox(width: 12.w),
                _iconAction(
                  icon: Icons.chat_bubble_outline,
                  color: Colors.green.shade600,
                  tooltip: 'WhatsApp',
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
    required String tooltip,
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
            tooltip,
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
    final startStr =
        '${(loan.startDate ?? DateTime.now()).day} ${_month((loan.startDate ?? DateTime.now()).month)} ${(loan.startDate ?? DateTime.now()).year}';
    final endStr = loan.endDate != null
        ? '${loan.endDate!.day} ${_month(loan.endDate!.month)} ${loan.endDate!.year}'
        : '-';
    final duration = loan.durationMonths ?? 0;
    final progress = loan.progress.clamp(0.0, 1.0);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header badge
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.percent, size: 14.sp, color: _primary),
                      SizedBox(width: 6.w),
                      Text(
                        'Interest Credit',
                        style: TextStyle(
                          color: _primary,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(loan.status).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      _statusLabel(loan.status),
                      style: TextStyle(
                        color: _statusColor(loan.status),
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey.shade100),

          // Key stats grid
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _statItem(
                        'Principal Amount',
                        '₹${_fmt(loan.amount)}',
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(child: _statItem('Duration', '$duration Months')),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _statItem('Start Date', startStr)),
                    SizedBox(width: 12.w),
                    Expanded(child: _statItem('End Date', endStr)),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _statItem(
                        'Paid Months',
                        '0 / $duration',
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _statItem(
                        'Progress',
                        '${(progress * 100).toStringAsFixed(0)}%',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
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
            color: Colors.black87,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // â”€â”€â”€ Interest Info Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _interestInfoCard(LoanModel loan) {
    final rate = loan.interestRate ?? 0.0;
    final duration = loan.durationMonths ?? 0;
    final monthly = rate > 0
        ? loan.amount * rate / 100
        : (loan.emiAmount ?? 0.0);
    final totalInterest = monthly * duration;
    final totalPayable = loan.amount + totalInterest;
    final progress = loan.progress.clamp(0.0, 1.0);
    final received = monthly * (duration * progress).floor();

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
              Icon(Icons.trending_up, color: Colors.white70, size: 16.sp),
              SizedBox(width: 6.w),
              Text(
                'Interest Overview',
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
                child: _interestStat(
                  'Interest Rate',
                  '${rate.toStringAsFixed(1)}% / month',
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _interestStat('Monthly Interest', '₹${_fmt(monthly)}'),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _interestStat(
                  'Total Interest',
                  '₹${_fmt(totalInterest)}',
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _interestStat('Total Payable', '₹${_fmt(totalPayable)}'),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _interestStat('Interest Paid', '₹${_fmt(received)}'),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _interestStat(
                  'Interest Pending',
                  '₹${_fmt(totalInterest - received)}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _interestStat(String label, String value) {
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

  // â”€â”€â”€ Payment Progress Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _paymentProgressCard(LoanModel loan) {
    final duration = loan.durationMonths ?? 0;
    final progress = loan.progress.clamp(0.0, 1.0);
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
            '0 of $duration months paid',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade500),
          ),
          SizedBox(height: 12.h),

          // Progress bar
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

          // Month checklist
          
        ],
      ),
    );
  }

  // â”€â”€â”€ Proof Document Section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _proofDocumentSection(BuildContext context, LoanModel loan) {
    if (loan.documentUrl == null || loan.documentUrl!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final url = loan.documentUrl!;
    final lowercaseUrl = url.toLowerCase();
    final isPdf =
        lowercaseUrl.contains('.pdf') ||
        lowercaseUrl.split('?').first.endsWith('.pdf');

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
                color: const Color(0xFFFFF3E0),
                border: Border.all(color: _primary.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  // Thumbnail
                  Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
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
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Center(
                                child: SizedBox(
                                  width: 16.w,
                                  height: 16.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: _primary,
                                  ),
                                ),
                              );
                            },
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
                              ? 'Signed_Agreement_Interest_Credit.pdf'
                              : 'Proof_Document_Interest_Credit.jpg',
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
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
          backgroundColor: Colors.white,
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade100),
                  ),
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
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              // Body
              Flexible(
                child: Container(
                  color: Colors.grey.shade50,
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  child: isPdf
                      ? _pdfPreview(context, url)
                      : _imagePreview(context, url),
                ),
              ),
              // Footer
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
        );
      },
    );
  }

  Widget _imagePreview(BuildContext context, String url) {
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
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(
                child: CircularProgressIndicator(color: _primary),
              );
            },
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

  Widget _pdfPreview(BuildContext context, String url) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
            'This document is in PDF format. Tap "Open External" to view it in your browser or PDF reader.',
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

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green.shade700;
      case 'closed':
        return Colors.grey.shade600;
      case 'pending_otp':
      case 'pending_approval':
        return const Color(0xFFD97706);
      default:
        return Colors.blueGrey;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'closed':
        return 'Closed';
      case 'pending_otp':
        return 'Pending OTP';
      case 'pending_approval':
        return 'Pending Approval';
      default:
        return status;
    }
  }
}




