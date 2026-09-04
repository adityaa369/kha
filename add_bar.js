const fs = require('fs');
const code = 
  // --- Bottom Bar ------------------------------------------------------------

  Widget _bottomBar(BuildContext context, LoanModel loan) {
    if (loan.status.isClosed || loan.status.isPending) return const SizedBox.shrink();
    
    String? currentUserId;
    try {
      final authState = context.read<AuthCubit>().state;
      if (authState is AuthenticatedKycComplete) currentUserId = authState.user.id;
      if (authState is AuthenticatedEmailVerifiedKycIncomplete) currentUserId = authState.user.id;
    } catch (_) {}

    final isLender = loan.lenderId == currentUserId;
    if (!isLender) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => FlexiblePaymentSheet.show(context, loan, 'Record Payment', 'record_payment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade50,
                  foregroundColor: Colors.green.shade700,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 4.w),
                ),
                child: Text('?? Record Payment', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => CloseLoanSheet.show(context, loan),
                icon: Icon(Icons.check_circle_outline, size: 16.sp),
                label: Text('Close Loan', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red.shade700,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
;
let content = fs.readFileSync('lib/features/loans/presentation/pages/hand_loan_details_page.dart', 'utf-8');
content = content.replace('Widget _profileCard', code + '\n  Widget _profileCard');
content = content.replace('appBar: _buildAppBar(context, loan),', 'appBar: _buildAppBar(context, loan),\n          bottomNavigationBar: _bottomBar(context, activeLoan),');
content = "import '../widgets/flexible_payment_sheet.dart';\nimport '../widgets/close_loan_sheet.dart';\n" + content;
fs.writeFileSync('lib/features/loans/presentation/pages/hand_loan_details_page.dart', content);
