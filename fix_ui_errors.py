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

    # Remove all leftover "Paid Months" stats which were causing compilation errors
    content = re.sub(
        r'Expanded\(\s*child:\s*_stat\(\'Paid Months\',\s*\'\$paidMonths / \$duration\'\),\s*\),\s*SizedBox\(width: 12\.w\),',
        '',
        content,
        flags=re.DOTALL
    )
    content = re.sub(
        r'Expanded\(\s*child:\s*_gradientStat\(\'Paid Months\',\s*\'\$paidMonths / \$duration\'\),\s*\),\s*SizedBox\(width: 12\.w\),',
        '',
        content,
        flags=re.DOTALL
    )
    content = re.sub(
        r'Expanded\(\s*child:\s*_gradientStat\(\s*\'Remaining\',\s*\'\$\{duration - paidMonths\} months\',\s*\),\s*\),',
        r'const Expanded(child: SizedBox()),',
        content,
        flags=re.DOTALL
    )

    # Some pages had remaining horizontal scroll generators using paidMonths
    content = re.sub(
        r'if \(duration > 0\).*?List\.generate\(duration, \(index\) \{.*?final isPaid = index < paidMonths;.*?\}\),\s*\),\s*\),',
        '',
        content,
        flags=re.DOTALL
    )

    # Remove any leftover `paidMonths` variable declarations
    content = re.sub(r'final paidMonths = \(duration \* progress\)\.round\(\);\s*', '', content)

    # Fix DateTime type mismatch error
    content = content.replace('_dateStr(loan.startDate)', 'loan.startDate != null ? _dateStr(loan.startDate!) : \'-\'')
    
    with open(file, 'w', encoding='utf-8') as f:
        f.write(content)

print("Fixed compile errors!")
