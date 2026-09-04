const fs = require('fs');
let code = fs.readFileSync('lib/features/loans/presentation/pages/hand_loan_details_page.dart', 'utf-8');

code = code.replace(
  'final totalPayable = loan.totalPayableAmount ?? (emi * duration);',
  'final totalPayable = (loan.totalPayableAmount != null && loan.totalPayableAmount > 0) ? loan.totalPayableAmount : loan.amount;'
);

code = code.replace(
  'final amountPending = loan.remainingAmount;',
  'final amountPending = loan.remainingAmount > 0 ? loan.remainingAmount : (loan.amount - loan.paidAmount);'
);

code = code.replace(
  'return Container(\n                    margin: EdgeInsets.only(right: 12.w),\n                    child: Column(',
  eturn GestureDetector(
                    onTap: () => _toggleMonth(context, loan, index, paidMonths, duration),
                    child: Container(
                      margin: EdgeInsets.only(right: 12.w),
                      child: Column(
);

code = code.replace(
  '                        ),\n                      ],\n                    ),\n                  );',
  '                        ),\n                      ],\n                    ),\n                  ),\n                  );'
);

const toggleMonthFn = 
  void _toggleMonth(
    BuildContext context,
    LoanModel loan,
    int monthIndex,
    int currentPaid,
    int duration,
  ) async {
    final loanCubit = context.read<LoanCubit>();
    double newProgress;

    if (monthIndex < currentPaid) {
      newProgress = monthIndex / duration;
    } else {
      newProgress = (monthIndex + 1) / duration;
    }

    newProgress = newProgress.clamp(0.0, 1.0);
    final success = await loanCubit.updateProgress(loan.id, newProgress);

    if (context.mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: newProgress > loan.progress
              ? Colors.green.shade700
              : Colors.orange.shade700,
          content: Text(
            newProgress > loan.progress
                ? 'Month \ marked as paid \u2705'
                : 'Month \ marked as unpaid \u274C',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
;

code = code.replace('Widget _profileCard', toggleMonthFn + '\n  Widget _profileCard');

fs.writeFileSync('lib/features/loans/presentation/pages/hand_loan_details_page.dart', code);
