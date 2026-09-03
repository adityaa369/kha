import glob

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

def fix_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        c = f.read()

    if "_repaymentChecklist" in c:
        return

    # Add RefreshIndicator top wrapper
    c = c.replace(
        "body: SingleChildScrollView(",
        "body: RefreshIndicator(\n            onRefresh: () async => context.read<LoanCubit>().fetchLoans(),\n            child: SingleChildScrollView("
    )
    
    # Add RefreshIndicator bottom parenthesis
    # For hand_loan and business_loan:
    old_end = "                  _proofDocumentSection(context, activeLoan),\n                  SizedBox(height: 16.h),\n                ],\n              ),\n            ),\n          );"
    new_end = "                  _proofDocumentSection(context, activeLoan),\n                  SizedBox(height: 16.h),\n                ],\n              ),\n            ),\n            ),\n          );"
    c = c.replace(old_end, new_end)
    
    # For interest_loan (has different body layout end):
    old_end2 = "                        padding: EdgeInsets.zero,\n                      ),\n                  ],\n                  ),\n                ),\n                // Body\n                Flexible(\n                  child: Container(\n                    decoration: BoxDecoration(\n                      color: Colors.white,\n                      borderRadius: BorderRadius.only(\n                        topLeft: Radius.circular(24.r),\n                        topRight: Radius.circular(24.r),\n                      ),\n                    ),\n                    child: SingleChildScrollView(\n                      padding: EdgeInsets.all(16.w),\n                      child: Column(\n                        crossAxisAlignment: CrossAxisAlignment.start,\n                        children: [\n                          _borrowerCard(context, activeLoan),\n                          SizedBox(height: 16.h),\n                          _statsCard(activeLoan),\n                          SizedBox(height: 16.h),\n                          _recentTransactions(activeLoan),\n                          SizedBox(height: 16.h),\n                          _interestInfoCard(activeLoan),\n                          SizedBox(height: 16.h),\n                          _proofDocumentSection(context, activeLoan),\n                          SizedBox(height: 80.h),\n                        ],\n                      ),\n                    ),\n                  ),\n                ),\n            ],\n            ),\n          );"
    new_end2 = old_end2.replace("            ],\n            ),\n          );", "            ],\n            ),\n            ),\n          );")
    c = c.replace(old_end2, new_end2)

    # Insert into build layout (hand and business)
    c = c.replace(
        "_statsCard(activeLoan),\n                  SizedBox(height: 16.h),",
        "_statsCard(activeLoan),\n                  SizedBox(height: 16.h),\n                  _repaymentChecklist(activeLoan),\n                  SizedBox(height: 16.h),"
    )
    # Insert into build layout (interest)
    c = c.replace(
        "_statsCard(activeLoan),\n                          SizedBox(height: 16.h),",
        "_statsCard(activeLoan),\n                          SizedBox(height: 16.h),\n                          _repaymentChecklist(activeLoan),\n                          SizedBox(height: 16.h),"
    )

    # Append to bottom of class
    c = c.rstrip()[:-1] + "\n" + checklist_code + "\n}\n"
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(c)

for path in [
    'lib/features/loans/presentation/pages/hand_loan_details_page.dart',
    'lib/features/loans/presentation/pages/business_loan_details_page.dart',
    'lib/features/loans/presentation/pages/interest_loan_details_page.dart',
]:
    fix_file(path)

print("Applied fix cleanly")
