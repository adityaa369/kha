import re

ui_path = 'lib/features/loans/presentation/pages/lender_loan_details_page.dart'
with open(ui_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace the whole pendingCard body
new_pending = """  Widget _pendingCard(BuildContext context, LoanModel loan) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.access_time_filled,
            color: const Color(0xFFD97706),
            size: 24.sp,
          ),
          SizedBox(height: 8.h),
          Text(
            loan.status == 'pending_otp'
                ? 'Pending OTP Verification'
                : 'Pending Borrower Signature',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14.sp,
              color: const Color(0xFF92400E),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            loan.status == 'pending_otp'
                ? 'An OTP was sent to the borrower. They must verify it to activate the loan.'
                : 'The borrower must accept and sign the agreement.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.sp, color: const Color(0xFFB45309)),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              if (loan.status == 'pending_otp') ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.push(AppConstants.loanConfirmation, extra: loan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      minimumSize: Size(0, 40.h),
                    ),
                    child: const Text('Verify OTP Now'),
                  ),
                ),
                SizedBox(width: 8.w),
              ],
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _confirmCancel(context, loan),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade300),
                    minimumSize: Size(0, 40.h),
                  ),
                  child: const Text('Cancel Request'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }"""

# Replace anything from "Widget _pendingCard(BuildContext context, LoanModel loan) {" to the end of the method
content = re.sub(
    r"Widget _pendingCard\(BuildContext context, LoanModel loan\) \{.*?(?=\n  // |\Z)",
    new_pending + "\n\n",
    content,
    flags=re.DOTALL
)

with open(ui_path, 'w', encoding='utf-8') as f:
    f.write(content)
