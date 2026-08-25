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

    # Find the index of _paymentChecklist and delete everything from it to _proofDocumentSection
    start_idx = content.find('Widget _paymentChecklist')
    if start_idx != -1:
        end_idx = content.find('Widget _proofDocumentSection')
        if end_idx != -1:
            # We also need to remove the comment block above _paymentChecklist
            comment_idx = content.rfind('//', 0, start_idx)
            if comment_idx != -1 and (start_idx - comment_idx) < 100:
                start_idx = comment_idx
            
            content = content[:start_idx] + content[end_idx:]

    with open(file, 'w', encoding='utf-8') as f:
        f.write(content)

print("Removed _paymentChecklist completely!")
