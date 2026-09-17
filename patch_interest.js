const fs = require('fs');
let code = fs.readFileSync('lib/features/loans/presentation/pages/interest_loan_details_page.dart', 'utf8');

// 1. Rename class
code = code.replace(/class LenderLoanDetailsPage/g, 'class InterestLoanDetailsPage');
code = code.replace(/LenderLoanDetailsPage\(/g, 'InterestLoanDetailsPage(');

// 2. Fix title
code = code.replace(/title: Text\([\s\S]*?theme\.label[\s\S]*?Lender View['"]\s*,/m, 'title: Text(theme.label,');
code = code.replace(/title: Text\(\s*'\$\{theme\.label\}[^']*Lender View',\s*/, 'title: Text(theme.label,');

// 3. Fix borrower card
code = code.replace(
    /final name = loan\.borrowerName\.isNotEmpty \? loan\.borrowerName : 'Borrower';\s*final initial = name\[0\]\.toUpperCase\(\);\s*final phone = loan\.mobile \?\? '';/g,
    inal name = loan.lenderName?.isNotEmpty == true ? loan.lenderName! : 'Lender';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'L';
    final phone = loan.lenderPhone ?? '';
);
code = code.replace(/Pending Borrower Signature/g, 'Pending Lender Signature');
code = code.replace(/An OTP was sent to the borrower/g, 'An OTP was sent to the lender');
code = code.replace(/The borrower must accept/g, 'The lender must accept');

// 4. Hide action buttons
// Just replace if (canEdit) with if (false) inside the build method.
// Wait, canEdit isn't defined here, it's just if (!isPending) ...[ somewhere?
// Let's find how the buttons are wrapped.
// In lender_loan_details_page.dart (which we copied), let's see what wraps the buttons.
