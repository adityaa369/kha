const fs = require('fs');
let content = fs.readFileSync('lib/features/loans/presentation/pages/lender_loan_details_page.dart', 'utf8');

// Replace amounts row
const regex = /\/\/ Amounts Row[\s\S]*?\/\/ Dates Row/;

const replacement = \// Amounts Row
          Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _stat(
                        'Total Payable',
                        '₹' + _fmt(loan.totalPayablePaise / 100.0),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _stat(
                        'Received Amount',
                        '₹' + _fmt(loan.paidAmountPaise / 100.0),
                        valueColor: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _stat(
                        'Principal Outstanding',
                        '₹' + _fmt((loan.principalOutstandingPaise ?? (loan.totalPayablePaise - loan.paidAmountPaise)) / 100.0),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _stat(
                        'Interest Outstanding',
                        '₹' + _fmt(loan.interestOutstandingPaise / 100.0),
                        valueColor: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          // Dates Row\;

content = content.replace(regex, replacement);
fs.writeFileSync('lib/features/loans/presentation/pages/lender_loan_details_page.dart', content);
console.log('Replaced Amounts Row');
