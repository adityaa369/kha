import os
import re

file_path = 'lib/features/loans/presentation/pages/lender_loan_details_page.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Insert the function definitions right before the last closing brace (or before `Widget _actionButtons`)
insertion_point = content.find('Widget _actionButtons')
if insertion_point != -1:
    with open('nudge_widget.dart', 'r', encoding='utf-8') as nw:
        nudge_code = nw.read()
    
    content = content[:insertion_point] + nudge_code + '\n  ' + content[insertion_point:]

# Add it to the body
body_replacement = """                      _summaryCard(
                        activeLoan,
                        theme,
                        duration,
                        paidMonths,
                        progress,
                      ),
                      if (activeLoan.loanType != 'chit' && !isClosed && !isPending) ...[
                        SizedBox(height: 14.h),
                        _nudgeCard(context, activeLoan),
                      ],"""

content = content.replace(
    "_summaryCard(\n                        activeLoan,\n                        theme,\n                        duration,\n                        paidMonths,\n                        progress,\n                      ),",
    body_replacement
)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Injected nudge UI!")
