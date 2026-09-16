const fs = require("fs");
let code = fs.readFileSync("lib/features/loans/presentation/pages/loan_approval_page.dart", "utf8");

let replacementCode = `final state = context.read<LoanCubit>().state;
        if (state is LoanError && state.message.contains("Email verification is required")) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: const Text("Email verification required"),
              content: const Text("Please verify your email address before accepting this agreement."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx); // close dialog
                    context.push("/security-hub"); // Route to security hub
                  },
                  child: const Text("Verify Email"),
                ),
              ],
            )
          );
        } else {
          final errorMsg = state is LoanError ? state.message : "Failed to initialize acceptance process.";
          DialogUtils.showErrorDialog(context, errorMsg);
        }`;

code = code.replace(`final state = context.read<LoanCubit>().state;
        final errorMsg = state is LoanError ? state.message : 'Failed to initialize acceptance process.';
        DialogUtils.showErrorDialog(context, errorMsg);`, replacementCode);

fs.writeFileSync("lib/features/loans/presentation/pages/loan_approval_page.dart", code);

