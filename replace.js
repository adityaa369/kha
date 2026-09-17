const fs = require('fs');
let content = fs.readFileSync('lib/features/loans/presentation/pages/interest_loan_details_page.dart', 'utf8');

const regex = /Widget _buildAuthoritativeBalances[\s\S]*?    \);\n  \}\n/m;

const newMethod = \Widget _buildAuthoritativeBalances(Color primary, Color bg) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: Colors.white70,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Authoritative Ledger Balances',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Divider(height: 24.h, color: Colors.white24),
          Row(
            children: [
              Expanded(
                child: _statBox(
                  'Total Payable',
                  '₹' + _fmt(loan.totalPayablePaise / 100.0),
                  Colors.white,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _statBox(
                  'Amount Paid',
                  '₹' + _fmt(loan.paidAmountPaise / 100.0),
                  Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _statBox(
                  'Principal Outstanding',
                  '₹' + _fmt((loan.principalOutstandingPaise ?? (loan.totalPayablePaise - loan.paidAmountPaise)) / 100.0),
                  Colors.white,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _statBox(
                  'Interest Outstanding',
                  '₹' + _fmt(loan.interestOutstandingPaise / 100.0),
                  Colors.orange.shade200,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
\;

content = content.replace(regex, newMethod);
fs.writeFileSync('lib/features/loans/presentation/pages/interest_loan_details_page.dart', content);
console.log('Replaced _buildAuthoritativeBalances');
