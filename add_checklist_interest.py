checklist_code = """
  Widget _recentTransactions(LoanModel loan) {
    final txns = loan.transactions.reversed.toList(); // newest first
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: Colors.black87),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                '${txns.length} records',
                style: TextStyle(fontSize: 11.sp, color: _primary, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        if (txns.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.receipt_long_outlined, color: Colors.grey.shade400, size: 32.sp),
                SizedBox(height: 8.h),
                Text('No transactions recorded yet', style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
                SizedBox(height: 4.h),
                Text('Use Record Payment below to log payments', style: TextStyle(color: Colors.grey.shade400, fontSize: 11.sp)),
              ],
            ),
          )
        else
          ...txns.map((tx) => _txItem(
            _txIcon(tx.type as String? ?? ''),
            _txColor(tx.type as String? ?? ''),
            _txTitle(tx.type as String? ?? ''),
            tx.note as String? ?? '',
            _txAmountStr(tx.type as String? ?? '', (tx.amount as num?)?.toDouble() ?? 0),
            _txDateStr(tx.recordedAt),
            _txIsPositive(tx.type as String? ?? ''),
          )),
      ],
    );
  }

  IconData _txIcon(String type) {
    switch (type) {
      case 'payment': return Icons.arrow_downward;
      case 'interest_payment': return Icons.percent;
      case 'credit_added': return Icons.add_circle_outline;
      case 'loan_given': return Icons.arrow_upward;
      default: return Icons.swap_horiz;
    }
  }

  Color _txColor(String type) {
    switch (type) {
      case 'payment': return Colors.green.shade600;
      case 'interest_payment': return Colors.teal.shade600;
      case 'credit_added': return Colors.orange.shade600;
      case 'loan_given': return Colors.red.shade400;
      default: return Colors.grey;
    }
  }

  String _txTitle(String type) {
    switch (type) {
      case 'payment': return 'Payment Received';
      case 'interest_payment': return 'Interest Received';
      case 'credit_added': return 'Credit Added';
      case 'loan_given': return 'Loan Disbursed';
      default: return 'Transaction';
    }
  }

  String _txAmountStr(String type, double amount) {
    final sign = type == 'loan_given' ? '-' : '+';
    return '$sign?${_fmt(amount)}';
  }

  bool _txIsPositive(String type) => type != 'loan_given';

  String _txDateStr(dynamic rawDate) {
    if (rawDate == null) return '';
    try {
      final dt = DateTime.parse(rawDate.toString()).toLocal();
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return '';
    }
  }

  Widget _txItem(IconData icon, Color color, String title, String subtitle, String amount, String date, bool isPositive) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 16.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp, color: Colors.black87)),
                SizedBox(height: 2.h),
                Text(subtitle, style: TextStyle(color: Colors.grey, fontSize: 11.sp)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp, color: isPositive ? Colors.green.shade700 : Colors.red.shade600)),
              SizedBox(height: 2.h),
              Text(date, style: TextStyle(color: Colors.grey, fontSize: 11.sp)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _repaymentChecklist(LoanModel loan) {
    final duration = loan.durationMonths ?? 0;
    final progress = loan.progress.clamp(0.0, 1.0);
    final paidMonths = (duration * progress).round();

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loan.type.toLowerCase().contains('interest') || loan.type.toLowerCase().contains('home')
                ? 'Monthly Interest Overview'
                : 'Monthly Payment Overview',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: Colors.black87),
          ),
          SizedBox(height: 12.h),
          if (duration > 0)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: List.generate(duration, (index) {
                  final isPaid = index < paidMonths;
                  final dueDate = (loan.startDate ?? loan.activatedAt ?? loan.createdAt ?? DateTime.now()).add(Duration(days: (index + 1) * 30));

                  return Container(
                    margin: EdgeInsets.only(right: 12.w),
                    child: Column(
                      children: [
                        Text(
                          '${_monthName(dueDate.month)} ${dueDate.year}',
                          style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade600),
                        ),
                        SizedBox(height: 6.h),
                        Container(
                          width: 50.w,
                          height: 55.h,
                          decoration: BoxDecoration(
                            color: isPaid ? Colors.green.shade50 : Colors.white,
                            border: Border.all(color: isPaid ? Colors.green : Colors.red.shade200, width: 1.5),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            isPaid ? Icons.check : Icons.close,
                            color: isPaid ? Colors.green : Colors.red.shade300,
                            size: 20.sp,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  String _monthName(int m) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[m - 1];
  }
"""

with open('lib/features/loans/presentation/pages/interest_loan_details_page.dart', 'r', encoding='utf-8') as f:
    c = f.read()

c = c.replace(
    "          body: SingleChildScrollView(\n            padding: EdgeInsets.all(16.w),",
    "          body: RefreshIndicator(\n            onRefresh: () async => context.read<LoanCubit>().fetchLoans(),\n            child: SingleChildScrollView(\n              padding: EdgeInsets.all(16.w),"
)

c = c.replace(
    "                  _statsCard(activeLoan),\n                  SizedBox(height: 16.h),\n                  _interestInfoCard(activeLoan),",
    "                  _statsCard(activeLoan),\n                  SizedBox(height: 16.h),\n                  _repaymentChecklist(activeLoan),\n                  SizedBox(height: 16.h),\n                  _recentTransactions(activeLoan),\n                  SizedBox(height: 16.h),\n                  _interestInfoCard(activeLoan),"
)

old_end = "                  _proofDocumentSection(context, activeLoan),\n                  SizedBox(height: 16.h),\n                  SizedBox(height: 8.h),\n                ],\n              ),\n            ),\n          );\n        },\n      );\n    }"
new_end = "                  _proofDocumentSection(context, activeLoan),\n                  SizedBox(height: 16.h),\n                  SizedBox(height: 8.h),\n                ],\n              ),\n            ),\n            ),\n          );\n        },\n      );\n    }"

c = c.replace(old_end, new_end)

if "_repaymentChecklist" not in c[c.find("Widget _paymentProgressCard"):]:
    c = c.rstrip()[:-1] + "\n" + checklist_code + "\n}\n"

with open('lib/features/loans/presentation/pages/interest_loan_details_page.dart', 'w', encoding='utf-8') as f:
    f.write(c)
    print("Fixed interest")
