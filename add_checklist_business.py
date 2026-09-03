checklist_code = """
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

with open('lib/features/loans/presentation/pages/business_loan_details_page.dart', 'r', encoding='utf-8') as f:
    c = f.read()

c = c.replace(
    "          body: SingleChildScrollView(\n            padding: EdgeInsets.all(16.w),",
    "          body: RefreshIndicator(\n            onRefresh: () async => context.read<LoanCubit>().fetchLoans(),\n            child: SingleChildScrollView(\n              padding: EdgeInsets.all(16.w),"
)

c = c.replace(
    "                  _statsCard(activeLoan),\n                  SizedBox(height: 16.h),",
    "                  _statsCard(activeLoan),\n                  SizedBox(height: 16.h),\n                  _repaymentChecklist(activeLoan),\n                  SizedBox(height: 16.h),"
)

old_end = "                  _proofDocumentSection(context, activeLoan),\n                  SizedBox(height: 16.h),\n                ],\n              ),\n            ),\n          );\n        },\n      );\n    }"
new_end = "                  _proofDocumentSection(context, activeLoan),\n                  SizedBox(height: 16.h),\n                ],\n              ),\n            ),\n            ),\n          );\n        },\n      );\n    }"

c = c.replace(old_end, new_end)

if "_repaymentChecklist" not in c[c.find("Widget _txItem"):]:
    c = c.rstrip()[:-1] + "\n" + checklist_code + "\n}\n"

with open('lib/features/loans/presentation/pages/business_loan_details_page.dart', 'w', encoding='utf-8') as f:
    f.write(c)
    print("Fixed business")
