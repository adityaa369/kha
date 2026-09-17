import re

with open('lib/features/loans/presentation/pages/interest_loan_details_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Rename class
content = content.replace('class LenderLoanDetailsPage', 'class InterestLoanDetailsPage')
content = content.replace('LenderLoanDetailsPage(', 'InterestLoanDetailsPage(')

# 2. Fix title
content = re.sub(r'title:\s*Text\(\s*\'\$\{theme\.label\}[^\']*Lender View\',\s*', 'title: Text(theme.label, ', content)

# 3. Fix borrower card
old_card = '''final name = loan.borrowerName.isNotEmpty ? loan.borrowerName : 'Borrower';
    final initial = name[0].toUpperCase();
    final phone = loan.mobile ?? '';'''
new_card = '''final name = loan.lenderName?.isNotEmpty == true ? loan.lenderName! : 'Lender';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'L';
    final phone = loan.lenderPhone ?? '';'''
content = content.replace(old_card, new_card)

content = content.replace('Pending Borrower Signature', 'Pending Lender Signature')
content = content.replace('An OTP was sent to the borrower. They must verify it to activate the loan.', 'An OTP was sent to the lender. They must verify it to activate the loan.')
content = content.replace('The borrower must accept and sign the agreement.', 'The lender must accept and sign the agreement.')

# 4. Hide action buttons
# Find Widget _actionButtons and replace it with return SizedBox.shrink()
action_regex = r'Widget _actionButtons\([\s\S]*?Widget _txItem'
new_action = '''Widget _actionButtons(
    BuildContext context,
    LoanModel loan,
    _TypeTheme theme,
    bool isClosed,
    bool isPending,
  ) {
    return const SizedBox.shrink();
  }

  Widget _txItem'''
content = re.sub(action_regex, new_action, content, flags=re.DOTALL)

with open('lib/features/loans/presentation/pages/interest_loan_details_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print('Patched successfully!')
