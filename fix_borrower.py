import glob
import re

lender_path = 'lib/features/loans/presentation/pages/lender_loan_details_page.dart'
with open(lender_path, 'r', encoding='utf-8') as f:
    lender_content = f.read()

# Extract recentTransactions and helpers
match = re.search(r'(  Widget _recentTransactions\(.*?Widget _txItem.*?}\n)', lender_content, re.DOTALL)
if match:
    recent_transactions_code = match.group(1)
else:
    print("Could not find recentTransactions in lender file")
    exit(1)

def fix_borrower_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        c = f.read()
    
    if "_recentTransactions" not in c:
        # Insert before the last closing brace
        c = c.rstrip()[:-1] + "\n" + recent_transactions_code + "\n}\n"
        
        # Replace RepaymentTimelineWidget
        c = re.sub(r'RepaymentTimelineWidget\(loan: \w+\),', r'_recentTransactions(activeLoan, theme),', c)
        
        with open(path, 'w', encoding='utf-8') as f:
            f.write(c)

for p in ['hand_loan_details_page.dart', 'business_loan_details_page.dart', 'interest_loan_details_page.dart']:
    fix_borrower_file(f'lib/features/loans/presentation/pages/{p}')

print("Fixed borrower transaction lists")
