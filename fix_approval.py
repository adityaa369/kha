import sys
filepath = 'lib/features/loans/presentation/pages/loan_approval_page.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

target = """                    _DetailRow(
                      icon: Icons.percent,
                      label: 'Interest',
                      value: (loan.interestRate ?? 0) > 0
                          ? '% PM'
                          : loan.type.toLowerCase() == 'hand_loan'
                              ? '0% (Hand Loan)'
                              : '0%',
                    ),
                    SizedBox(height: 12.h),"""

replacement = """                    if (loan.type.toLowerCase() != 'business_credit' && loan.type.toLowerCase() != 'business') ...[
                      _DetailRow(
                        icon: Icons.percent,
                        label: 'Interest',
                        value: (loan.interestRate ?? 0) > 0
                            ? '% PM'
                            : loan.type.toLowerCase().contains('hand')
                                ? '0% (Hand Credit)'
                                : '0%',
                      ),
                      SizedBox(height: 12.h),
                    ],"""

if target in content:
    content = content.replace(target, replacement)
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Fixed loan approval page.")
else:
    print("Target not found.")
