import os
import re

files = [
    'lib/features/loans/presentation/pages/hand_loan_details_page.dart',
    'lib/features/loans/presentation/pages/business_loan_details_page.dart',
    'lib/features/loans/presentation/pages/interest_loan_details_page.dart'
]

for file in files:
    with open(file, 'r', encoding='utf-8') as f:
        content = f.read()

    content = content.replace('RepaymentTimelineWidget(loanId: activeLoan.id)', 'RepaymentTimelineWidget(loan: activeLoan)')

    with open(file, 'w', encoding='utf-8') as f:
        f.write(content)

print("Updated widget instantiations!")
