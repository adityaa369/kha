import re
import os

def insert_checklist(filepath, is_lender):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    click_action = "context.read<LoanCubit>().toggleMonthStatus(loan.id, month.monthIndex, isPaid ? 'unpaid' : 'paid');" if is_lender else ""

    checklist_widget = f'''
  Widget _buildMonthTrackingChecklist(BuildContext context, LoanModel loan) {{
    if (loan.monthsTracking.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.only(top: 24.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Repayment Checklist', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
          SizedBox(height: 12.h),
          ...loan.monthsTracking.map((month) {{
            final isPaid = month.status == 'paid';
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {{
                      {click_action}
                    }},
                    child: Container(
                      width: 24.w,
                      height: 24.w,
                      decoration: BoxDecoration(
                        color: isPaid ? Colors.green.shade500 : Colors.white,
                        border: Border.all(color: isPaid ? Colors.green.shade500 : Colors.grey.shade400, width: 2),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: isPaid ? Icon(Icons.check, size: 16.sp, color: Colors.white) : null,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Month ${{month.monthIndex}}', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: Colors.black87)),
                        if (isPaid && month.markedPaidAt != null)
                          Text('Marked paid on ${{DateFormat('MMM d, yyyy').format(month.markedPaidAt!)}}', style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: isPaid ? Colors.green.shade50 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      isPaid ? 'Paid' : 'Unpaid',
                      style: TextStyle(
                        color: isPaid ? Colors.green.shade700 : Colors.orange.shade700,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }}).toList(),
        ],
      ),
    );
  }}
'''

    if '_buildMonthTrackingChecklist' not in content:
        content = re.sub(r'\n}\n?$', '\n' + checklist_widget + '\n}\n', content)

    if '_buildMonthTrackingChecklist(context, loan),' not in content:
        if '_txList(' in content:
            content = content.replace('_txList(loan.transactions, theme),', '_buildMonthTrackingChecklist(context, loan),\n                      SizedBox(height: 16.h),\n                      _txList(loan.transactions, theme),')
        else:
            content = content.replace('_statsCard(loan),', '_statsCard(loan),\n                      SizedBox(height: 16.h),\n                      _buildMonthTrackingChecklist(context, loan),')

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

pages = [
    ('lib/features/loans/presentation/pages/lender_loan_details_page.dart', True),
    ('lib/features/loans/presentation/pages/hand_loan_details_page.dart', False),
    ('lib/features/loans/presentation/pages/interest_loan_details_page.dart', False),
    ('lib/features/loans/presentation/pages/business_loan_details_page.dart', False),
]

for page, is_lender in pages:
    if os.path.exists(page):
        insert_checklist(page, is_lender)
        print("Updated " + page)
