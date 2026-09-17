const fs = require('fs');
let code = fs.readFileSync('lib/features/loans/presentation/pages/interest_loan_details_page.dart', 'utf8');

// 4. Hide action buttons
code = code.replace(
    /Widget _actionButtons\([\s\S]*?if \(isClosed \|\| isPending\) return const SizedBox\.shrink\(\);[\s\S]*?final t = loan\.type\.toLowerCase\(\);/m,
    Widget _actionButtons(
    BuildContext context,
    LoanModel loan,
    _TypeTheme theme,
    bool isClosed,
    bool isPending,
  ) {
    return const SizedBox.shrink();
    // original: final t = loan.type.toLowerCase();
);

fs.writeFileSync('lib/features/loans/presentation/pages/interest_loan_details_page.dart', code);
console.log('Fixed action buttons');
