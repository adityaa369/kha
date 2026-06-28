import re

path = 'lib/features/loans/presentation/pages/hand_loan_details_page.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Fix the calculation in _buildRecentTransactions
content = re.sub(
    r"'₹\$\{\_formatCurrency\(loan\.amount \* \(loan\.interestRate \?\? 0\) / 100 \* \(loan\.durationMonths \?\? 6\) \* \_getSafeProgress\(loan\)\)\}'",
    r"'₹${_formatCurrency(loan.amount * _getSafeProgress(loan))}'",
    content
)

# 2. Change 'Principal Amount Given' to 'Given Amount'
content = content.replace("'Principal Amount Given'", "'Given Amount'")

# 3. Delete _showRecordInterestDialog completely
# We know it starts around 'void _showRecordInterestDialog'
# Find the next method and delete up to it. 
# The next method is usually `_showRecordPrincipalDialog` or `_showUpdateProgressChecklistDialog`
start_idx = content.find('void _showRecordInterestDialog(')
if start_idx != -1:
    end_idx = content.find('void _showRecordPrincipalDialog(', start_idx)
    if end_idx != -1:
        content = content[:start_idx] + content[end_idx:]

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
