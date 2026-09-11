const fs = require('fs');
let code = fs.readFileSync('lib/features/loans/presentation/pages/loan_confirmation_page.dart', 'utf8');

code = "import '../../../../core/utils/error_handler.dart';\n" + code;

code = code.replace('Widget build(BuildContext context) {', 
`Widget build(BuildContext context) {
    if (loanData['amountPaise'] == null || loanData['amountPaise'] is! int) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ErrorHandler.showError(context, 'Contract Error: Missing or invalid amountPaise');
        context.pop();
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }`);

code = code.replace(/\(loanData\['amountPaise'\] \?\? 0\) \/ 100/g, "loanData['amountPaise'] / 100");

fs.writeFileSync('lib/features/loans/presentation/pages/loan_confirmation_page.dart', code);
