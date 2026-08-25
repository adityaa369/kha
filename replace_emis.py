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
    
    # 1. Add import
    if 'repayment_timeline_widget.dart' not in content:
        content = content.replace("import '../../../../core/blocs/loans/loan_cubit.dart';", "import '../../../../core/blocs/loans/loan_cubit.dart';\nimport '../widgets/repayment_timeline_widget.dart';")
    
    # 2. Replace the usages in the main Column
    content = re.sub(
        r'_emiOverviewCard\(activeLoan\),\s*SizedBox\(height: 16\.h\),\s*_paymentChecklist\(activeLoan\),',
        r'RepaymentTimelineWidget(loanId: activeLoan.id),\n                  SizedBox(height: 16.h),\n                  _creditOverviewCard(activeLoan),',
        content
    )
    
    # Wait, _emiOverviewCard had the remaining balance. If I delete it, where does the user see remaining balance?
    # I will rename _emiOverviewCard to _creditOverviewCard and REMOVE the paidMonths/fake timeline logic from it.
    
    # Let's fix _statsCard to remove 'Paid Months'
    stats_replacement = r"""
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _stat('Progress', '${(progress * 100).toStringAsFixed(0)}%'),
                      ),
                      SizedBox(width: 12.w),
                      const Expanded(child: SizedBox()),
                    ],
                  ),"""
    content = re.sub(
        r'Row\(\s*crossAxisAlignment: CrossAxisAlignment\.start,\s*children: \[\s*Expanded\(\s*child: _stat\(\'Paid Months\',.*?\]\s*\),',
        stats_replacement.strip(),
        content,
        flags=re.DOTALL
    )

    # Let's completely remove paidMonths variable from _statsCard
    content = re.sub(r'final paidMonths = \(duration \* progress\)\.round\(\);\s*', '', content)

    # Now let's fix _emiOverviewCard -> _creditOverviewCard
    content = content.replace('Widget _emiOverviewCard(LoanModel loan)', 'Widget _creditOverviewCard(LoanModel loan)')
    content = re.sub(r'final paidMonths = \(duration \* progress\)\.round\(\);\s*', '', content)
    content = re.sub(
        r'Row\(\s*crossAxisAlignment: CrossAxisAlignment\.start,\s*children: \[\s*Expanded\(\s*child: _gradientStat\(\'Paid Months\',.*?\]\s*\),',
        '',
        content,
        flags=re.DOTALL
    )

    # And completely remove _paymentChecklist
    content = re.sub(
        r'// ─── Payment Checklist ───.*?Widget _paymentChecklist\(LoanModel loan\).*?}\n\n',
        '',
        content,
        flags=re.DOTALL
    )

    with open(file, 'w', encoding='utf-8') as f:
        f.write(content)

print("Done replacing fake EMIs!")
