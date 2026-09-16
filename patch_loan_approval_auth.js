const fs = require("fs");
let code = fs.readFileSync("lib/features/loans/presentation/pages/loan_approval_page.dart", "utf8");

let target = `    if (loan == null) {
      return const Scaffold(
        body: Center(child: Text('Loan not found')),
      );
    }

    return Scaffold(`;

let replacement = `    if (loan == null) {
      return const Scaffold(
        body: Center(child: Text('Loan not found')),
      );
    }

    final authState = context.read<AuthCubit>().state;
    final currentUserId = authState is Authenticated ? authState.user.id : null;
    final isBorrower = loan.userId != null && currentUserId != null && loan.userId == currentUserId;

    return Scaffold(`;

code = code.replace(target, replacement);

code = code.replace("if (loan.status == 'pending_approval')", "if (loan.status == 'pending_approval' && isBorrower)");
code = code.replace("if (loan.status == 'pending_approval')", "if (loan.status == 'pending_approval' && isBorrower)");
code = code.replace("if (loan.status == 'pending_approval')", "if (loan.status == 'pending_approval' && isBorrower)"); // in case there are 3

fs.writeFileSync("lib/features/loans/presentation/pages/loan_approval_page.dart", code);

