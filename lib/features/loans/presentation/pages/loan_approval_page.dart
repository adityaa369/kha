import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/blocs/loans/loan_cubit.dart';
import '../../../../core/blocs/loans/loan_state.dart';
import '../../../../data/models/loan_model.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/biometric_auth_service.dart';
import '../../../../config/constants.dart';

class LoanApprovalPage extends StatefulWidget {
  final LoanModel loan;

  const LoanApprovalPage({super.key, required this.loan});

  @override
  State<LoanApprovalPage> createState() => _LoanApprovalPageState();
}

class _LoanApprovalPageState extends State<LoanApprovalPage> {
  bool _isApproving = false;

  void _approveLoan() async {
    final authenticated = await BiometricAuthService.authenticate();
    if (!authenticated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric signature required to accept loan.', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isApproving = true);
    
    final success = await context.read<LoanCubit>().verifyLoan(widget.loan.id);
    
    setState(() => _isApproving = false);
    
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to accept agreement. Try again.', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoanCubit, LoanState>(
      listener: (context, state) {
        if (state is LoanVerificationSuccess) {
          context.go(AppConstants.loanSuccess);
        }
      },
      child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Review Agreement'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: KhaataTheme.textDark,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time_filled, color: const Color(0xFFF59E0B), size: 20.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Pending Your Approval',
                      style: TextStyle(
                        color: const Color(0xFFF59E0B),
                        fontWeight: FontWeight.w700,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),

            // Header Section
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 30.r,
                    backgroundColor: KhaataTheme.primaryBlue.withOpacity(0.1),
                    child: Icon(Icons.person, color: KhaataTheme.primaryBlue, size: 30.sp),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    widget.loan.lenderName ?? 'Unknown Lender',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: KhaataTheme.textDark,
                    ),
                  ),
                  Text(
                    'Lender',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: KhaataTheme.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32.h),

            // Amount Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Text(
                    'Loan Amount',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: KhaataTheme.textGrey,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '₹${NumberFormat('#,##0').format(widget.loan.amount)}',
                    style: TextStyle(
                      fontSize: 32.sp,
                      fontWeight: FontWeight.w800,
                      color: KhaataTheme.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),

            // Details Section
            Text(
              'Agreement Details',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: KhaataTheme.textDark,
              ),
            ),
            SizedBox(height: 16.h),
            _DetailRow(label: 'Interest Rate', value: (widget.loan.interestRate ?? 0) > 0 ? '${widget.loan.interestRate}% PM' : '0% (Interest Free)'),
            _DetailRow(label: 'Duration', value: '${widget.loan.durationMonths} Months'),
            _DetailRow(label: 'Loan Type', value: widget.loan.type.toUpperCase()),
            _DetailRow(label: 'Date Issued', value: DateFormat('dd MMM, yyyy').format(widget.loan.createdAt ?? DateTime.now())),

            SizedBox(height: 40.h),

            // Action Buttons
            PrimaryButton(
              text: 'Accept Agreement',
              isLoading: _isApproving,
              onPressed: _approveLoan,
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isApproving ? null : () => context.pop(),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  side: BorderSide(color: Colors.red.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'Decline / Go Back',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: KhaataTheme.textGrey,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: KhaataTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
