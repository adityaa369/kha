import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/theme.dart';
import '../../../../config/constants.dart';
import '../../../../data/models/loan_model.dart';
import '../../../../core/blocs/loans/loan_cubit.dart';
import '../../../../core/blocs/loans/loan_state.dart';
import '../../../../core/blocs/auth/auth_cubit.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoanDetailsPage extends StatelessWidget {
  final LoanModel loan;

  const LoanDetailsPage({super.key, required this.loan});

  _ThemeConfig _getThemeConfig(LoanModel loan) {
    final type = loan.type.toLowerCase().replaceAll('_', '');
    if (type == 'businesscredit' || type == 'business') {
      return const _ThemeConfig(
        title: 'Business Credit Details',
        primary: Color(0xFF0D47A1), // Dark Blue
        bg: Color(0xFFE3F2FD), // Light Blue
        accent: Color(0xFF1976D2),
        badgeText: 'Business Credit',
        statusText: 'Active Account',
        avatarBg: Color(0xFFE3F2FD),
        avatarText: Color(0xFF0D47A1),
      );
    } else if (type == 'interestcredit' || type == 'home') {
      return const _ThemeConfig(
        title: 'Interest Credit Details',
        primary: Color(0xFF4A148C), // Dark Purple
        bg: Color(0xFFF3E5F5), // Light Purple
        accent: Color(0xFF7B1FA2),
        badgeText: 'Interest Credit',
        statusText: 'Active Loan',
        avatarBg: Color(0xFFF3E5F5),
        avatarText: Color(0xFF4A148C),
      );
    } else if (type == 'chitfund' || type == 'chitfunds') {
      return const _ThemeConfig(
        title: 'Chit Fund Details',
        primary: Color(0xFF880E4F), // Dark Pinkish
        bg: Color(0xFFFCE8F3), // Light Pink
        accent: Color(0xFFC2185B),
        badgeText: 'Chit Fund',
        statusText: 'Active Subscription',
        avatarBg: Color(0xFFFCE8F3),
        avatarText: Color(0xFF880E4F),
      );
    } else {
      // Default: Hand Credit
      return const _ThemeConfig(
        title: 'Hand Credit Details',
        primary: Color(0xFF1B5E20), // Dark Green
        bg: Color(0xFFE8F5E9), // Light Green
        accent: Color(0xFF388E3C),
        badgeText: 'Hand Credit',
        statusText: 'Active Loan',
        avatarBg: Color(0xFFE8F5E9),
        avatarText: Color(0xFF1B5E20),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoanCubit, LoanState>(
      builder: (context, state) {
        // Resolve active loan from Bloc state if available, so UI updates live
        final activeLoan = state is LoansLoaded
            ? (state.myLoans + state.givenLoans).firstWhere(
                (l) => l.id == loan.id,
                orElse: () => loan,
              )
            : loan;

        final config = _getThemeConfig(activeLoan);
        final endDateStr = activeLoan.endDate != null 
            ? '${activeLoan.endDate!.day} ${_getMonthName(activeLoan.endDate!.month)} ${activeLoan.endDate!.year}'
            : '-';

        final isPending = activeLoan.status == 'pending_otp' || activeLoan.status == 'pending_approval';

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
              config.title,
              style: TextStyle(
                color: config.primary,
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.black87),
                onPressed: () {},
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Profile Header Box
                _buildProfileHeader(context, config, activeLoan),
                SizedBox(height: 16.h),

                // 2. Badge Status Row
                _buildBadgeStatusRow(config, activeLoan),
                SizedBox(height: 16.h),

                // 3. Stats Grid (Adapts based on type)
                _buildStatsGrid(config, activeLoan, endDateStr),
                SizedBox(height: 16.h),

                if (!isPending) ...[
                  // 4. Monthly Payment Checklist Block
                  _buildMonthlyChecklist(context, config, activeLoan),
                  SizedBox(height: 16.h),

                  // 5. Loan Progress / Account Summary Block
                  _buildSummaryBlock(context, config, activeLoan),
                  SizedBox(height: 16.h),

                  // 6. Recent Transactions Block
                  _buildRecentTransactions(config, activeLoan),
                  SizedBox(height: 24.h),
                ] else ...[
                  // Pending Status Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.access_time_filled, color: const Color(0xFFD97706), size: 24.sp),
                        SizedBox(height: 8.h),
                        Text(
                          activeLoan.status == 'pending_otp'
                              ? 'Pending OTP Verification'
                              : 'Pending Digital Signature',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp, color: const Color(0xFF92400E)),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          activeLoan.status == 'pending_otp'
                              ? 'The borrower has been issued a verification OTP. The lender must verify the OTP to activate the signature step.'
                              : 'The borrower must review and accept the agreement using their biometric signature.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12.sp, color: const Color(0xFFB45309)),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),
                ],

                // 7. Actions Button Row
                _buildActionsRow(context, config, activeLoan),
                SizedBox(height: 16.h),

                // 8. Proof Document Section
                _buildProofDocumentSection(context, config, activeLoan),
                SizedBox(height: 16.h),
              ],
            ),
          ),
        );
      },
    );
  }

  // 1. Profile Header (Re-architected column layout to prevent any horizontal overflow)
  Widget _buildProfileHeader(BuildContext context, _ThemeConfig config, LoanModel loan) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Initials Avatar
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: config.avatarBg,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                alignment: Alignment.center,
                child: Text(
                  loan.initials ?? (loan.borrowerName.isNotEmpty ? loan.borrowerName[0].toUpperCase() : 'L'),
                  style: TextStyle(
                    color: config.avatarText,
                    fontWeight: FontWeight.w800,
                    fontSize: 16.sp,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              
              // Name and Phone
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loan.displayCounterpartyName,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(Icons.phone_outlined, size: 14.sp, color: Colors.grey),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            loan.mobile ?? '-',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _ContactButton(
                  icon: Icons.phone,
                  label: 'Call',
                  color: Colors.blue.shade600,
                  onPressed: () {
                    if (loan.mobile != null && loan.mobile!.isNotEmpty) {
                      Clipboard.setData(ClipboardData(text: loan.mobile!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: config.primary,
                          content: Text('Phone number ${loan.mobile} copied to clipboard!'),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No phone number available.')),
                      );
                    }
                  },
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _ContactButton(
                  icon: Icons.chat_bubble_outline,
                  label: 'WhatsApp',
                  color: Colors.green.shade600,
                  onPressed: () {
                    if (loan.mobile != null && loan.mobile!.isNotEmpty) {
                      Clipboard.setData(ClipboardData(text: loan.mobile!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.green.shade700,
                          content: Text('WhatsApp contact ${loan.mobile} copied to clipboard!'),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No phone number available.')),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. Badge Status Row
  Widget _buildBadgeStatusRow(_ThemeConfig config, LoanModel loan) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: config.avatarBg,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Row(
            children: [
              Icon(
                loan.type.toLowerCase().contains('business') 
                    ? Icons.storefront 
                    : (loan.type.toLowerCase().contains('interest') ? Icons.percent : Icons.volunteer_activism),
                size: 14.sp,
                color: config.primary,
              ),
              SizedBox(width: 6.w),
              Text(
                config.badgeText,
                style: TextStyle(
                  color: config.primary,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Text(
          loan.statusDisplay,
          style: TextStyle(
            color: loan.statusColor,
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // 3. Stats Grid
  Widget _buildStatsGrid(_ThemeConfig config, LoanModel loan, String endDateStr) {
    final type = loan.type.toLowerCase().replaceAll('_', '');

    if (type == 'businesscredit' || type == 'business') {
      return _GridContainer(
        children: [
          _GridItem(
            label: 'Total Credit',
            value: '₹${_formatCurrency(loan.amount)}',
            valueColor: config.primary,
          ),
          _GridItem(
            label: 'Total Received',
            value: '₹${_formatCurrency(loan.amount * _getSafeProgress(loan))}',
            valueColor: config.primary,
          ),
          _GridItem(
            label: 'Balance Amount',
            value: '₹${_formatCurrency(loan.remainingAmount)}',
            valueColor: Colors.red.shade700,
          ),
          _GridItem(
            label: 'Start Date',
            value: '${loan.startDate.day} ${_getMonthName(loan.startDate.month)} ${loan.startDate.year}',
          ),
          _GridItem(
            label: 'Duration',
            value: '-',
          ),
          _GridItem(
            label: 'Last Transaction',
            value: loan.updatedAt != null 
                ? '${loan.updatedAt!.day} ${_getMonthName(loan.updatedAt!.month)} ${loan.updatedAt!.year}'
                : '${loan.startDate.day} ${_getMonthName(loan.startDate.month)} ${loan.startDate.year}',
          ),
        ],
      );
    } else if (type == 'interestcredit' || type == 'home') {
      final monthlyInterestRate = loan.interestRate ?? 0.0;
      final monthlyInterestAmount = loan.amount * monthlyInterestRate / 100;
      return _GridContainer(
        children: [
          _GridItem(
            label: 'Principal Amount',
            value: '₹${_formatCurrency(loan.amount)}',
            valueColor: config.primary,
          ),
          _GridItem(
            label: 'Monthly Interest',
            value: '${monthlyInterestRate.toStringAsFixed(1)}%',
            valueColor: config.primary,
          ),
          _GridItem(
            label: 'Monthly Interest Amount',
            value: '₹${_formatCurrency(monthlyInterestAmount)}',
            valueColor: config.primary,
          ),
          _GridItem(
            label: 'Start Date',
            value: '${loan.startDate.day} ${_getMonthName(loan.startDate.month)} ${loan.startDate.year}',
          ),
          _GridItem(
            label: 'Duration',
            value: loan.durationMonths != null && loan.durationMonths != 0 ? '${loan.durationMonths} Months' : '-',
          ),
          _GridItem(
            label: 'End Date',
            value: endDateStr,
          ),
        ],
      );
    } else if (type == 'chitfund' || type == 'chitfunds') {
      final monthlySub = loan.emi ?? (loan.amount / (loan.durationMonths ?? 1));
      return _GridContainer(
        children: [
          _GridItem(
            label: 'Chit Value',
            value: '₹${_formatCurrency(loan.amount)}',
            valueColor: config.primary,
          ),
          _GridItem(
            label: 'Paid Installments',
            value: '₹${_formatCurrency(loan.amount * _getSafeProgress(loan))}',
            valueColor: config.primary,
          ),
          _GridItem(
            label: 'Remaining Value',
            value: '₹${_formatCurrency(loan.remainingAmount)}',
            valueColor: Colors.red.shade700,
          ),
          _GridItem(
            label: 'Monthly Payment',
            value: '₹${_formatCurrency(monthlySub)}',
            valueColor: config.primary,
          ),
          _GridItem(
            label: 'Start Date',
            value: '${loan.startDate.day} ${_getMonthName(loan.startDate.month)} ${loan.startDate.year}',
          ),
          _GridItem(
            label: 'Duration',
            value: loan.durationMonths != null && loan.durationMonths != 0 ? '${loan.durationMonths} Months' : '-',
          ),
        ],
      );
    } else {
      // Hand Credit
      return _GridContainer(
        children: [
          _GridItem(
            label: 'Given Amount',
            value: '₹${_formatCurrency(loan.amount)}',
            valueColor: config.primary,
          ),
          _GridItem(
            label: 'Received Amount',
            value: '₹${_formatCurrency(loan.amount * _getSafeProgress(loan))}',
            valueColor: config.primary,
          ),
          _GridItem(
            label: 'Remaining Amount',
            value: '₹${_formatCurrency(loan.remainingAmount)}',
            valueColor: Colors.red.shade700,
          ),
          _GridItem(
            label: 'Start Date',
            value: '${loan.startDate.day} ${_getMonthName(loan.startDate.month)} ${loan.startDate.year}',
          ),
          _GridItem(
            label: 'Duration',
            value: loan.durationMonths != null && loan.durationMonths != 0 ? '${loan.durationMonths} Months' : '-',
          ),
          _GridItem(
            label: 'End Date',
            value: endDateStr,
          ),
        ],
      );
    }
  }

  // 4. Monthly Payment Checklist Block
  Widget _buildMonthlyChecklist(BuildContext context, _ThemeConfig config, LoanModel loan) {
    final type = loan.type.toLowerCase().replaceAll('_', '');
    if (type == 'businesscredit' || type == 'business') {
      return const SizedBox.shrink();
    }
    // Defensive check: default duration to 6 if null or 0, preventing division by 0
    final duration = (loan.durationMonths == null || loan.durationMonths == 0) ? 6 : loan.durationMonths!;
    final progressVal = _getSafeProgress(loan);
    
    // Generate months checklist dynamically based on startDate
    final monthItems = <_MonthCheckItem>[];
    var currentMonth = loan.startDate.month;
    var currentYear = loan.startDate.year;
    
    // Calculate how many months are checked based on progress fraction
    final checkedCount = (duration * progressVal).round();

    for (var i = 0; i < duration; i++) {
      final name = '${_getMonthName(currentMonth)} $currentYear';
      final isPaid = i < checkedCount;
      
      // Calculate monthly payment value dynamically
      double monthlyPayment = 0;
      if (type == 'interestcredit' || type == 'home') {
        monthlyPayment = loan.amount * (loan.interestRate ?? 0) / 100;
      } else {
        monthlyPayment = loan.amount / duration;
      }

      monthItems.add(_MonthCheckItem(
        name: name, 
        amount: '₹${_formatCurrency(monthlyPayment)}', 
        isPaid: isPaid,
        monthIndex: i,
      ));

      currentMonth++;
      if (currentMonth > 12) {
        currentMonth = 1;
        currentYear++;
      }
    }

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
            type == 'interestcredit' || type == 'home' ? 'Monthly Interest Overview' : 'Monthly Payment Overview',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: monthItems.map((item) => Padding(
                padding: EdgeInsets.only(right: 12.w),
                child: InkWell(
                  onTap: type == 'chitfund' || type == 'chitfunds'
                      ? null
                      : () {
                          _showUpdateProgressChecklistDialog(context, loan, item.monthIndex + 1, item.name, config);
                        },
                  borderRadius: BorderRadius.circular(8.r),
                  child: Container(
                    width: 76.w,
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Column(
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                        ),
                        SizedBox(height: 6.h),
                        Icon(
                          item.isPaid ? Icons.check_box_outlined : Icons.indeterminate_check_box_outlined,
                          color: item.isPaid ? config.primary : Colors.red.shade400,
                          size: 20.sp,
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          item.amount,
                          style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ),
              )).toList(),
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Icon(Icons.info_outline, size: 12.sp, color: Colors.grey.shade600),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  'Tap a checklist item to directly update payment status.',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 5. Summary Block
  Widget _buildSummaryBlock(BuildContext context, _ThemeConfig config, LoanModel loan) {
    final type = loan.type.toLowerCase().replaceAll('_', '');

    if (type == 'businesscredit' || type == 'business') {
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
              'Account Summary',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _SummaryStat(
                  label: 'Total Transactions',
                  value: '2',
                ),
                _SummaryStat(
                  label: 'Last Credit',
                  value: '₹${_formatCurrency(loan.amount)}',
                  subtitle: '${loan.startDate.day} ${_getMonthName(loan.startDate.month)}',
                ),
                _SummaryStat(
                  label: 'Last Payment',
                  value: _getSafeProgress(loan) > 0 
                      ? '₹${_formatCurrency(loan.amount * _getSafeProgress(loan))}'
                      : '-',
                  subtitle: _getSafeProgress(loan) > 0 && loan.updatedAt != null
                      ? '${loan.updatedAt!.day} ${_getMonthName(loan.updatedAt!.month)}'
                      : (_getSafeProgress(loan) > 0 ? '${loan.startDate.day} ${_getMonthName(loan.startDate.month)}' : null),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      // Hand or Interest Credit
      // Defensive check: default duration to 6 if null or 0, preventing division by 0
      final duration = (loan.durationMonths == null || loan.durationMonths == 0) ? 6 : loan.durationMonths!;
      final progressVal = _getSafeProgress(loan);
      final completedMonths = (duration * progressVal).round();
      final nextDueDate = loan.startDate.add(Duration(days: (completedMonths + 1) * 30));
      final nextDueStr = '${nextDueDate.day} ${_getMonthName(nextDueDate.month)} ${nextDueDate.year}';

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Loan Progress',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  '$completedMonths of $duration months completed',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(4.r),
              child: LinearProgressIndicator(
                value: progressVal,
                backgroundColor: Colors.grey.shade100,
                valueColor: AlwaysStoppedAnimation<Color>(config.primary),
                minHeight: 6.h,
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type == 'interestcredit' || type == 'home' ? 'Next Interest Due Date' : 'Next Payment Due Date',
                        style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        nextDueStr,
                        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                OutlinedButton.icon(
                  onPressed: () => _showPaymentScheduleDialog(context, loan, config),
                  icon: Icon(Icons.calendar_today_outlined, size: 12.sp, color: config.primary),
                  label: Text('View Schedule', style: TextStyle(fontSize: 11.sp, color: config.primary, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: config.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  // 6. Recent Transactions
  Widget _buildRecentTransactions(_ThemeConfig config, LoanModel loan) {
    final type = loan.type.toLowerCase().replaceAll('_', '');
    
    // Dynamically generate transactions list based on backend models
    final txs = <_TransactionItem>[];
    
    txs.add(_TransactionItem(
      title: type == 'businesscredit' || type == 'business' ? 'Credit Added' : (type == 'interestcredit' || type == 'home' ? 'Principal Amount Given' : 'Given Amount'),
      subtitle: type == 'businesscredit' || type == 'business' ? 'Grocery Items' : 'Given Amount',
      amount: '₹${_formatCurrency(loan.amount)}',
      date: '${loan.startDate.day} ${_getMonthName(loan.startDate.month)} ${loan.startDate.year}',
      isCredit: false,
    ));

    if (_getSafeProgress(loan) > 0) {
      txs.insert(0, _TransactionItem(
        title: type == 'interestcredit' || type == 'home' ? 'Interest Payment Received' : 'Payment Received',
        subtitle: type == 'businesscredit' || type == 'business' ? 'By Cash' : 'Repayment Installment',
        amount: '₹${_formatCurrency(loan.amount * _getSafeProgress(loan))}',
        date: loan.updatedAt != null 
            ? '${loan.updatedAt!.day} ${_getMonthName(loan.updatedAt!.month)} ${loan.updatedAt!.year}'
            : '${loan.startDate.day} ${_getMonthName(loan.startDate.month)} ${loan.startDate.year}',
        isCredit: true,
      ));
    }

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Filter',
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(width: 4.w),
                  Icon(Icons.filter_list_rounded, size: 14.sp, color: Colors.grey.shade600),
                ],
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Column(
            children: List.generate(txs.length, (index) {
              final tx = txs[index];
              return Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: tx.isCredit ? Colors.green.shade50 : Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          tx.isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                          color: tx.isCredit ? Colors.green.shade700 : Colors.red.shade700,
                          size: 16.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.title,
                              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: Colors.black87),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              tx.subtitle,
                              style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            (tx.isCredit ? '+' : '-') + tx.amount,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: tx.isCredit ? Colors.green.shade700 : Colors.red.shade700,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            tx.date,
                            style: TextStyle(fontSize: 9.sp, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (index < txs.length - 1)
                    Divider(color: Colors.grey.shade100, height: 16.h),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  // 7. Actions Button Row
  Widget _buildActionsRow(BuildContext context, _ThemeConfig config, LoanModel loan) {
    final authState = context.read<AuthCubit>().state;
    String? currentUserId;
    if (authState is AuthenticatedFull) currentUserId = authState.user.id;
    if (authState is AuthenticatedUnverified) currentUserId = authState.user.id;

    final isLender = loan.lenderId == currentUserId;
    final isPending = loan.status == 'pending_otp' || loan.status == 'pending_approval';

    if (isPending) {
      if (!isLender) {
        // Borrower actions
        return SizedBox(
          width: double.infinity,
          height: 48.h,
          child: ElevatedButton.icon(
            onPressed: () {
              context.push(
                AppConstants.loanApproval,
                extra: loan,
              );
            },
            icon: const Icon(Icons.rate_review_outlined, color: Colors.white),
            label: Text(
              'Review & Approve Agreement',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: config.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
          ),
        );
      } else {
        // Lender actions
        if (loan.status == 'pending_otp') {
          return Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showVerifyOtpDialog(context, loan, config),
                  icon: const Icon(Icons.vpn_key_outlined, color: Colors.white),
                  label: Text('Verify Borrower OTP', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: config.primary,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const Center(child: CircularProgressIndicator()),
                    );
                    final success = await context.read<LoanCubit>().resendOtp(loan.id);
                    if (context.mounted) {
                      Navigator.pop(context); // pop loader
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: success ? Colors.green : Colors.red,
                          content: Text(success ? 'OTP resent successfully!' : 'Failed to resend OTP.'),
                        ),
                      );
                    }
                  },
                  icon: Icon(Icons.refresh, size: 16.sp, color: config.primary),
                  label: Text('Resend OTP', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: config.primary)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: config.primary),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                ),
              ),
            ],
          );
        } else {
          return SizedBox(
            width: double.infinity,
            height: 48.h,
            child: OutlinedButton.icon(
              onPressed: null, // Disabled
              icon: Icon(Icons.hourglass_empty, color: Colors.amber.shade700),
              label: Text(
                'Waiting for Borrower Signature...',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.amber.shade700),
              ),
              style: OutlinedButton.styleFrom(
                disabledForegroundColor: Colors.amber.shade700,
                side: BorderSide(color: Colors.amber.shade300),
                backgroundColor: Colors.amber.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
            ),
          );
        }
      }
    }

    final type = loan.type.toLowerCase().replaceAll('_', '');

    if (type == 'businesscredit' || type == 'business') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showAddCreditDialog(context, loan, config),
              icon: Icon(Icons.add, size: 16.sp, color: Colors.white),
              label: Text('Add Credit', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: config.primary,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                elevation: 0,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showRecordPaymentDialog(context, loan, config),
              icon: Icon(Icons.currency_rupee, size: 16.sp, color: Colors.white),
              label: Text('Record Payment', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                elevation: 0,
              ),
            ),
          ),
        ],
      );
    } else if (type == 'interestcredit' || type == 'home') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showRecordInterestDialog(context, loan, config),
              icon: Icon(Icons.percent, size: 14.sp, color: Colors.white),
              label: Text('Record Interest\nPayment', textAlign: TextAlign.center, style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w700, color: Colors.white, height: 1.1)),
              style: ElevatedButton.styleFrom(
                backgroundColor: config.primary,
                padding: EdgeInsets.symmetric(vertical: 10.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                elevation: 0,
              ),
            ),
          ),
          SizedBox(width: 6.w),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showRecordPrincipalDialog(context, loan, config),
              icon: Icon(Icons.description, size: 14.sp, color: Colors.white),
              label: Text('Record Principal\nPayment', textAlign: TextAlign.center, style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w700, color: Colors.white, height: 1.1)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                padding: EdgeInsets.symmetric(vertical: 10.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                elevation: 0,
              ),
            ),
          ),
          SizedBox(width: 6.w),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _handleCloseLoan(context, loan, config),
              icon: Icon(Icons.delete, size: 14.sp, color: Colors.white),
              label: Text('Close Loan', textAlign: TextAlign.center, style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w700, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                elevation: 0,
              ),
            ),
          ),
        ],
      );
    } else if (type == 'chitfund' || type == 'chitfunds') {
      return const SizedBox.shrink();
    } else {
      // Hand Credit
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showRecordPaymentDialog(context, loan, config),
              icon: Icon(Icons.currency_rupee, size: 16.sp, color: Colors.white),
              label: Text('Record Payment', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: config.primary,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                elevation: 0,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _handleCloseLoan(context, loan, config),
              icon: Icon(Icons.delete_outline, size: 16.sp, color: Colors.red.shade700),
              label: Text('Close Loan', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: Colors.red.shade700)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.red.shade200),
                backgroundColor: Colors.red.shade50,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
            ),
          ),
        ],
      );
    }
  }

  // Dialog & Flow Helpers

  // Progress Checklist Dialog
  void _showUpdateProgressChecklistDialog(
    BuildContext context, 
    LoanModel loan, 
    int selectedMonthsCount, 
    String monthName, 
    _ThemeConfig config
  ) {
    // Defensive check: default duration to 6 if null or 0, preventing division by 0
    final duration = (loan.durationMonths == null || loan.durationMonths == 0) ? 6 : loan.durationMonths!;
    final newProgress = selectedMonthsCount / duration;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text(
          'Update Progress',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
        ),
        content: Text(
          'Do you want to set progress to $selectedMonthsCount out of $duration months (up to $monthName)?\n\nThis will update the overall progress to ${(newProgress * 100).toStringAsFixed(0)}%.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: config.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator()),
              );
              
              await context.read<LoanCubit>().updateProgress(loan.id, newProgress);
              
              if (context.mounted) {
                Navigator.pop(context); // pop loader
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: config.primary,
                    content: const Text('Progress updated successfully!'),
                  ),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  // Payment Schedule Dialog
  void _showPaymentScheduleDialog(BuildContext context, LoanModel loan, _ThemeConfig config) {
    // Defensive check: default duration to 6 if null or 0, preventing division by 0
    final duration = (loan.durationMonths == null || loan.durationMonths == 0) ? 6 : loan.durationMonths!;
    final type = loan.type.toLowerCase().replaceAll('_', '');
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: Text('Payment Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp, color: config.primary)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: duration,
              itemBuilder: (context, index) {
                final dueDate = loan.startDate.add(Duration(days: (index + 1) * 30));
                final dueDateStr = '${dueDate.day} ${_getMonthName(dueDate.month)} ${dueDate.year}';
                final progressVal = _getSafeProgress(loan);
                final isPaid = index < (duration * progressVal).round();
                
                double amount = 0;
                if (type == 'interestcredit' || type == 'home') {
                  amount = loan.amount * (loan.interestRate ?? 0) / 100;
                } else {
                  amount = loan.amount / duration;
                }

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: isPaid ? config.avatarBg : Colors.grey.shade100,
                    radius: 14.r,
                    child: Icon(
                      isPaid ? Icons.check : Icons.calendar_today,
                      size: 14.sp,
                      color: isPaid ? config.primary : Colors.grey,
                    ),
                  ),
                  title: Text(
                    'Month ${index + 1} - ${_getMonthName(dueDate.month)} ${dueDate.year}',
                    style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Due: $dueDateStr',
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                  ),
                  trailing: Text(
                    '₹${_formatCurrency(amount)}',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: isPaid ? Colors.green.shade700 : Colors.black87,
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Close', style: TextStyle(color: config.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // Record Payment Dialog
  void _showRecordPaymentDialog(BuildContext context, LoanModel loan, _ThemeConfig config) {
    final controller = TextEditingController();
    final remaining = loan.remainingAmount;
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: Text('Record Repayment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp, color: config.primary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Enter the repayment amount received from the borrower.', style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600)),
              SizedBox(height: 8.h),
              Text('Outstanding Balance: ₹${_formatCurrency(remaining)}', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
              SizedBox(height: 16.h),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  hintText: '0.00',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
              onPressed: () async {
                final amtStr = controller.text.trim();
                if (amtStr.isEmpty) return;
                final amt = double.tryParse(amtStr);
                if (amt == null || amt <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid positive amount.')),
                  );
                  return;
                }
                if (amt > remaining + 0.01) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Payment amount cannot exceed the remaining balance of ₹${_formatCurrency(remaining)}.')),
                  );
                  return;
                }
                
                Navigator.pop(dialogContext); // Close dialog
                
                // Show loader
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(child: CircularProgressIndicator()),
                );
                
                final double newPaid = loan.amount * _getSafeProgress(loan) + amt;
                final double newProgress = (newPaid / loan.amount).clamp(0.0, 1.0);
                
                await context.read<LoanCubit>().updateProgress(loan.id, newProgress);
                
                if (context.mounted) {
                  Navigator.pop(context); // Close loader
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Colors.green,
                      content: Text('Payment recorded successfully!'),
                    ),
                  );
                }
              },
              child: const Text('Record'),
            ),
          ],
        );
      },
    );
  }

  // Add Credit Dialog (Business Credit)
  void _showAddCreditDialog(BuildContext context, LoanModel loan, _ThemeConfig config) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: Text('Add Business Credit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp, color: config.primary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Enter the new credit purchase/bill amount to add to this account.', style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600)),
              SizedBox(height: 16.h),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  hintText: '0.00',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: config.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
              onPressed: () async {
                final amtStr = controller.text.trim();
                if (amtStr.isEmpty) return;
                final amt = double.tryParse(amtStr);
                if (amt == null || amt <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid positive amount.')),
                  );
                  return;
                }
                
                Navigator.pop(dialogContext); // Close dialog
                
                // Show loader
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(child: CircularProgressIndicator()),
                );
                
                final double currentPaid = loan.amount * _getSafeProgress(loan);
                final double newProgress = (currentPaid / (loan.amount + amt)).clamp(0.0, 1.0);
                
                await context.read<LoanCubit>().updateProgress(loan.id, newProgress);
                
                if (context.mounted) {
                  Navigator.pop(context); // Close loader
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: config.primary,
                      content: Text('Added credit of ₹${_formatCurrency(amt)} successfully!'),
                    ),
                  );
                }
              },
              child: const Text('Add Credit'),
            ),
          ],
        );
      },
    );
  }

  // Record Interest Dialog (Interest Credit)
  void _showRecordInterestDialog(BuildContext context, LoanModel loan, _ThemeConfig config) {
    // Defensive check: default duration to 6 if null or 0, preventing division by 0
    final duration = (loan.durationMonths == null || loan.durationMonths == 0) ? 6 : loan.durationMonths!;
    final monthlyInterestRate = loan.interestRate ?? 0.0;
    final monthlyInterestAmount = loan.amount * monthlyInterestRate / 100;
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: Text('Record Interest Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp, color: config.primary)),
          content: Text(
            'Confirm receipt of this month\'s interest payment:\n\nInterest Amount: ₹${_formatCurrency(monthlyInterestAmount)}\nInterest Rate: ${monthlyInterestRate.toStringAsFixed(1)}%\n\nThis will mark the next installment in the checklist as Paid.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: config.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
              onPressed: () async {
                Navigator.pop(dialogContext); // Close dialog
                
                // Show loader
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(child: CircularProgressIndicator()),
                );
                
                final double newProgress = (_getSafeProgress(loan) + 1.0 / duration).clamp(0.0, 1.0);
                
                await context.read<LoanCubit>().updateProgress(loan.id, newProgress);
                
                if (context.mounted) {
                  Navigator.pop(context); // Close loader
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: config.primary,
                      content: const Text('Interest payment recorded successfully!'),
                    ),
                  );
                }
              },
              child: const Text('Record'),
            ),
          ],
        );
      },
    );
  }

  // Record Principal Dialog (Interest Credit)
  void _showRecordPrincipalDialog(BuildContext context, LoanModel loan, _ThemeConfig config) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: Text('Record Principal Repayment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp, color: config.primary)),
          content: Text(
            'Confirm repayment of the entire principal amount of ₹${_formatCurrency(loan.amount)}?\n\nRecording this will mark the loan as fully paid and initiate the mutual closure process.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
              onPressed: () {
                Navigator.pop(dialogContext); // Close dialog
                _handleCloseLoan(context, loan, config);
              },
              child: const Text('Repay Principal'),
            ),
          ],
        );
      },
    );
  }

  // Close Loan mutual OTP flow
  void _handleCloseLoan(BuildContext context, LoanModel loan, _ThemeConfig config) async {
    final navigator = Navigator.of(context);
    final sm = ScaffoldMessenger.of(context);
    final loanCubit = context.read<LoanCubit>();
    
    // Show loading spinner while requesting OTP
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      final phone = loan.mobile;
      if (phone == null || phone.isEmpty) {
        throw 'Borrower phone number is missing';
      }
      final formattedPhone = phone.startsWith('+') ? phone : '+91$phone';
      
      String? verificationId;

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) {},
        verificationFailed: (FirebaseAuthException e) {
          navigator.pop(); // Pop loader
          sm.showSnackBar(SnackBar(
            backgroundColor: Colors.red,
            content: Text('Firebase SMS OTP failed: ${e.message}'),
          ));
        },
        codeSent: (String vId, int? resendToken) {
          navigator.pop(); // Pop loader
          verificationId = vId;

          final otpController = TextEditingController();
          if (!context.mounted) return;
          
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              title: const Text('Finalize Closure', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('An OTP has been sent securely via Firebase SMS to the borrower (${formattedPhone}). Enter it below to mutually confirm the agreement closure.'),
                  SizedBox(height: 16.h),
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      hintText: '6-digit OTP',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      counterText: '',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                  ),
                  onPressed: () async {
                    if (otpController.text.length != 6) return;
                    
                    Navigator.pop(dialogContext); // Hide dialog
                    
                    // Show loader
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const Center(child: CircularProgressIndicator()),
                    );
                    
                    final success = await loanCubit.closeLoan(
                      loan.id,
                      otpController.text,
                      verificationId!,
                    );
                    
                    if (context.mounted) {
                      Navigator.pop(context); // Pop loader
                      
                      if (success) {
                        GoRouter.of(context).push(AppConstants.loanCloseSuccess);
                      } else {
                        final state = loanCubit.state;
                        final String errorMsg = state is LoanError ? state.message : 'Invalid Authentication OTP.';
                        sm.showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.red,
                            content: Text(errorMsg),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Confirm'),
                ),
              ],
            ),
          );
        },
        codeAutoRetrievalTimeout: (String vId) {
          verificationId = vId;
        },
      );
    } catch (e) {
      navigator.pop(); // Pop loader
      sm.showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        content: Text('Failed to initiate closure OTP: $e'),
      ));
    }
  }

  // Formatting currency helper
  String _formatCurrency(double amount) {
    if (amount.isNaN || amount.isInfinite) return '0';
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  // Month name helper (Defends against index out of range)
  String _getMonthName(int month) {
    if (month < 1 || month > 12) return 'Jan';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  // Safe progress helper (Defends against NaN, infinite, or range errors)
  double _getSafeProgress(LoanModel loan) {
    if (loan.progress.isNaN || loan.progress.isInfinite) return 0.0;
    return loan.progress.clamp(0.0, 1.0);
  }  // Verify Borrower OTP Dialog (Lender side)
  void _showVerifyOtpDialog(BuildContext context, LoanModel loan, _ThemeConfig config) async {
    final sm = ScaffoldMessenger.of(context);
    final loanCubit = context.read<LoanCubit>();
    
    // Show loading spinner while requesting Firebase OTP
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      final phone = loan.mobile;
      if (phone == null || phone.isEmpty) {
        throw 'Borrower phone number is missing';
      }
      final formattedPhone = phone.startsWith('+') ? phone : '+91$phone';
      
      String? verificationId;

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) {},
        verificationFailed: (FirebaseAuthException e) {
          Navigator.pop(context); // Pop loader
          sm.showSnackBar(SnackBar(
            backgroundColor: Colors.red,
            content: Text('Firebase SMS OTP failed: ${e.message}'),
          ));
        },
        codeSent: (String vId, int? resendToken) {
          Navigator.pop(context); // Pop loader
          verificationId = vId;

          final controller = TextEditingController();
          showDialog(
            context: context,
            builder: (dialogContext) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              title: Text('Verify Borrower OTP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp, color: config.primary)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Enter the 6-digit OTP sent to the borrower (${formattedPhone}).', style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600)),
                  SizedBox(height: 16.h),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      hintText: 'Enter 6-digit OTP',
                      counterText: '',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: config.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                  ),
                  onPressed: () async {
                    final otp = controller.text.trim();
                    if (otp.length != 6) return;
                    
                    Navigator.pop(dialogContext); // Pop dialog
                    
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const Center(child: CircularProgressIndicator()),
                    );
                    
                    final success = await loanCubit.verifyLenderOtp(
                      loan.id,
                      otp,
                      verificationId!,
                    );
                    
                    if (context.mounted) {
                      Navigator.pop(context); // pop loader
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.green,
                            content: Text(
                              loan.type == 'interest_credit' || loan.type == 'interestcredit'
                                  ? 'Interest setup confirmed!'
                                  : 'Loan setup confirmed!',
                            ),
                          ),
                        );
                      } else {
                        final state = loanCubit.state;
                        final String errorMsg = state is LoanError ? state.message : 'Invalid OTP. Please try again.';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.red,
                            content: Text(errorMsg),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Confirm'),
                ),
              ],
            ),
          );
        },
        codeAutoRetrievalTimeout: (String vId) {
          verificationId = vId;
        },
      );
    } catch (e) {
      Navigator.pop(context); // Pop loader
      sm.showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        content: Text('Failed to initiate Firebase OTP: $e'),
      ));
    }
  }
  Widget _buildProofDocumentSection(BuildContext context, _ThemeConfig config, LoanModel loan) {
    if (loan.documentUrl == null || loan.documentUrl!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

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
            onTap: () async {
              final uri = Uri.parse(loan.documentUrl!);
              try {
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  throw 'Could not open URL';
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.red,
                      content: Text('Could not open document: $e'),
                    ),
                  );
                }
              }
            },
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: config.bg.withOpacity(0.4),
                border: Border.all(color: config.primary.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: config.avatarBg,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      Icons.picture_as_pdf,
                      color: config.primary,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Signed_Agreement_${loan.displayType.replaceAll(" ", "_")}.pdf',
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
                          'Click to view digital signature & proof',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.open_in_new,
                    color: config.primary,
                    size: 18.sp,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------
// Helper Mini Widgets
// -------------------

class _ThemeConfig {
  final String title;
  final Color primary;
  final Color bg;
  final Color accent;
  final String badgeText;
  final String statusText;
  final Color avatarBg;
  final Color avatarText;

  const _ThemeConfig({
    required this.title,
    required this.primary,
    required this.bg,
    required this.accent,
    required this.badgeText,
    required this.statusText,
    required this.avatarBg,
    required this.avatarText,
  });
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ContactButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16.sp, color: color),
            SizedBox(width: 4.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridContainer extends StatelessWidget {
  final List<Widget> children;
  const _GridContainer({required this.children});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 3) {
      final rowChildren = <Widget>[];
      for (var j = 0; j < 3; j++) {
        if (i + j < children.length) {
          rowChildren.add(Expanded(child: children[i + j]));
        } else {
          rowChildren.add(const Expanded(child: SizedBox()));
        }
        if (j < 2) {
          rowChildren.add(SizedBox(width: 12.w));
        }
      }
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rowChildren,
      ));
      if (i + 3 < children.length) {
        rows.add(SizedBox(height: 16.h));
      }
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: rows,
      ),
    );
  }
}

class _GridItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _GridItem({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 6.h),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

class _MonthCheckItem {
  final String name;
  final String amount;
  final bool isPaid;
  final int monthIndex;
  const _MonthCheckItem({
    required this.name, 
    required this.amount, 
    required this.isPaid,
    required this.monthIndex,
  });
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;

  const _SummaryStat({required this.label, required this.value, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 6.h),
          Text(
            value,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          if (subtitle != null) ...[
            SizedBox(height: 2.h),
            Text(
              subtitle!,
              style: TextStyle(fontSize: 9.sp, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }
}

class _TransactionItem {
  final String title;
  final String subtitle;
  final String amount;
  final String date;
  final bool isCredit;

  const _TransactionItem({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
    required this.isCredit,
  });
}
