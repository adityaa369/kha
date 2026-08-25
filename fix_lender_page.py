import os
import re

file_path = 'lib/features/loans/presentation/pages/lender_loan_details_page.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add RepaymentTimelineWidget import
if 'repayment_timeline_widget.dart' not in content:
    content = content.replace("import '../../../../core/blocs/system/system_state_cubit.dart';", "import '../../../../core/blocs/system/system_state_cubit.dart';\nimport '../widgets/repayment_timeline_widget.dart';")

# 2. Fix _dateStr(loan.startDate)
content = content.replace('_dateStr(loan.startDate)', 'loan.startDate != null ? _dateStr(loan.startDate!) : \'-\'')

# 3. Replace the usage of _repaymentChecklist with RepaymentTimelineWidget
content = re.sub(
    r'if \(!isPending\) \.\.\.\[\s*_repaymentChecklist\(\s*context,\s*activeLoan,\s*theme,\s*duration,\s*paidMonths,\s*progress,\s*\),\s*SizedBox\(height: 14\.h\),\s*\]',
    r'if (!isPending) ...[\n                        RepaymentTimelineWidget(loan: activeLoan),\n                        SizedBox(height: 14.h),\n                      ]',
    content
)

# 4. Remove the definition of _repaymentChecklist completely to fix all those [] operator errors
start_idx = content.find('Widget _repaymentChecklist')
if start_idx != -1:
    end_idx = content.find('Widget _bottomActionRow', start_idx)
    if end_idx == -1:
        end_idx = content.find('Widget _actionButtons', start_idx)
    
    if end_idx != -1:
        # Also remove comment before it
        comment_idx = content.rfind('//', 0, start_idx)
        if comment_idx != -1 and (start_idx - comment_idx) < 150:
            start_idx = comment_idx
        
        content = content[:start_idx] + content[end_idx:]

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Fixed lender page compile errors!")
