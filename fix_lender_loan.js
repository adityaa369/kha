const fs = require('fs');
let content = fs.readFileSync('lib/features/loans/presentation/pages/lender_loan_details_page.dart', 'utf8');

const mathBlock = `    final actualStart =
        loan.startDate ?? loan.activatedAt ?? loan.createdAt ?? DateTime.now();
    final start = _dateStr(actualStart);
    final end = loan.endDate != null
        ? _dateStr(loan.endDate!)
        : _dateStr(
            actualStart.add(
              Duration(days: (loan.durationMonths ?? duration) * 30),
            ),
          );

    final originalTotalPaise = loan.amountPaise;
    final remainingPaise = loan.totalOutstandingPaise;
    final collectedPaise = loan.paidAmountPaise;

    final isInterest =
        loan.type.toLowerCase().contains('interest') ||
        loan.type.toLowerCase().contains('home');`;

const regexMath = /final actualStart =[\s\S]*?final isInterest =[\s\S]*?contains\('home'\);/m;
content = content.replace(regexMath, mathBlock);

const statBlock = `                Expanded(
                  child: _stat(
                    isInterest ? 'Principal' : 'Given Amount',
                    '₹${_fmt(originalTotalPaise / 100)}',
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _stat(
                    'Collected',
                    '₹${_fmt(collectedPaise / 100)}',
                    color: KhaataTheme.successGreen,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _stat(
                    'Outstanding',
                    '₹${_fmt(remainingPaise / 100)}',
                    color: KhaataTheme.primaryBlue,
                  ),
                ),`;

const regexStat = /Expanded\(\s*child: _stat\(\s*isInterest \? 'Principal' : 'Given Amount',\s*'₹\$\{_fmt\(loan\.amount\)\}',\s*\),\s*\),\s*SizedBox\(width: 12\.w\),\s*Expanded\(\s*child: _stat\(\s*'Collected',\s*'₹\$\{_fmt\(collected\)\}',\s*color: KhaataTheme\.successGreen,\s*\),\s*\),\s*SizedBox\(width: 12\.w\),\s*Expanded\(\s*child: _stat\(\s*'Outstanding',\s*'₹\$\{_fmt\(remaining\)\}',\s*color: KhaataTheme\.primaryBlue,\s*\),\s*\),/m;
content = content.replace(regexStat, statBlock);

fs.writeFileSync('lib/features/loans/presentation/pages/lender_loan_details_page.dart', content);
console.log('Successfully updated lender_loan_details_page.dart');
