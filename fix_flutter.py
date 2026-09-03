import re
import os

# 1. Update Repository
repo_path = 'lib/data/repositories/loan_repository.dart'
with open(repo_path, 'r', encoding='utf-8') as f:
    content = f.read()

if "Future<void> deleteLoan" not in content:
    delete_fn = """  Future<void> deleteLoan(String loanId) async {
    final response = await _apiClient.delete('/loans/$loanId');
    if (response.statusCode != 200) {
      throw Exception('Failed to delete loan');
    }
  }\n"""
    content = content.replace("Future<bool> verifyLenderOtp", delete_fn + "\n  Future<bool> verifyLenderOtp")
    with open(repo_path, 'w', encoding='utf-8') as f:
        f.write(content)


# 2. Update Cubit
cubit_path = 'lib/core/blocs/loans/loan_cubit.dart'
with open(cubit_path, 'r', encoding='utf-8') as f:
    content = f.read()

if "Future<bool> deleteLoan" not in content:
    delete_cubit_fn = """
  Future<bool> deleteLoan(String loanId) async {
    try {
      await _repository.deleteLoan(loanId);
      
      if (state is LoansLoaded) {
        final current = state as LoansLoaded;
        final myLoans = current.myLoans.where((l) => l.id != loanId).toList();
        final givenLoans = current.givenLoans.where((l) => l.id != loanId).toList();
        emit(LoansLoaded(
          myLoans: myLoans,
          givenLoans: givenLoans,
          portfolio: current.portfolio,
        ));
      } else {
        loadLoans(); // Refresh if we were in some other state
      }
      return true;
    } catch (e) {
      ErrorHandler.logError('deleteLoan', e);
      rethrow;
    }
  }
"""
    content = content.replace("Future<bool> verifyLenderOtp", delete_cubit_fn + "\n  Future<bool> verifyLenderOtp")
    with open(cubit_path, 'w', encoding='utf-8') as f:
        f.write(content)


# 3. Update lender_loan_details_page.dart
ui_path = 'lib/features/loans/presentation/pages/lender_loan_details_page.dart'
with open(ui_path, 'r', encoding='utf-8') as f:
    content = f.read()

if "_confirmCancel" not in content:
    # We need to change `Widget _pendingCard(LoanModel loan)` to `Widget _pendingCard(BuildContext context, LoanModel loan)`
    # And call it correctly in build.
    content = content.replace("_pendingCard(activeLoan)", "_pendingCard(context, activeLoan)")
    
    confirm_fn = """  void _confirmCancel(BuildContext context, LoanModel loan) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Request'),
        content: const Text('Are you sure you want to cancel this pending loan request? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('No')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await context.read<LoanCubit>().deleteLoan(loan.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Request cancelled successfully')),
                  );
                  context.pop();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to cancel: $e')),
                  );
                }
              }
            },
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _pendingCard(BuildContext context, LoanModel loan) {"""
    
    content = content.replace("Widget _pendingCard(LoanModel loan) {", confirm_fn)
    
    new_buttons = """            Text(
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
            ),"""
            
    content = re.sub(
        r"Text\([^)]*loan\.status == 'pending_otp'[^)]*style:[^)]*\),", 
        new_buttons, 
        content, 
        flags=re.DOTALL
    )

    with open(ui_path, 'w', encoding='utf-8') as f:
        f.write(content)

print("Flutter updated.")
