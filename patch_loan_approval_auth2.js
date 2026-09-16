const fs = require("fs");
let code = fs.readFileSync("lib/features/loans/presentation/pages/loan_approval_page.dart", "utf8");

let target = `      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: KhaataTheme.textDark,
        ),
        body: const Center(child: Text('Loan not found.')),
      );
    }

    return Scaffold(`;

let replacement = `      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: KhaataTheme.textDark,
        ),
        body: const Center(child: Text('Loan not found.')),
      );
    }

    final authState = context.read<AuthCubit>().state;
    final currentUserId = authState is Authenticated ? authState.user.id : null;
    final isBorrower = loan.userId != null && currentUserId != null && loan.userId == currentUserId;

    return Scaffold(`;

code = code.replace(target, replacement);
fs.writeFileSync("lib/features/loans/presentation/pages/loan_approval_page.dart", code);

