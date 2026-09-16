
with open("lib/features/loans/presentation/pages/loan_approval_page.dart", "r") as f:
    code = f.read()

code = code.replace("DialogUtils.showErrorDialog(context, 'Failed to initialize acceptance process.');", """final state = context.read<LoanCubit>().state;
        final errorMsg = state is LoanError ? state.message : 'Failed to initialize acceptance process.';
        DialogUtils.showErrorDialog(context, errorMsg);""")

with open("lib/features/loans/presentation/pages/loan_approval_page.dart", "w") as f:
    f.write(code)

