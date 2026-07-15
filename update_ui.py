import os
import re

files = [
    'lib/features/loans/presentation/pages/business_loan_details_page.dart',
    'lib/features/loans/presentation/pages/hand_loan_details_page.dart',
    'lib/features/loans/presentation/pages/interest_loan_details_page.dart',
    'lib/features/loans/presentation/pages/lender_loan_details_page.dart'
]

# We will replace the ListView.separated(...) completely in each file.
for file in files:
    with open(file, 'r', encoding='utf-8') as f:
        content = f.read()

    # The ListView.separated starts with `ListView.separated(` and ends with `          ),` right before `      ]),`
    
    if "lender_loan" in file:
        # lender_loan_details_page has slightly different variables and gesture detector
        start_idx = content.find("ListView.separated(")
        if start_idx == -1: continue
        end_idx = content.find("            ),", start_idx)
        # Find the next closing parenthesis of the ListView
        while True:
            end_idx = content.find("          ),", end_idx + 1)
            if end_idx == -1: break
            # check if what follows is       ]),
            if content[end_idx:end_idx+30].find("      ]),") != -1 or content[end_idx:end_idx+30].find("        ],") != -1:
                break
        
        replacement = """SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: List.generate(duration, (index) {
                  final isPaid  = index < paidMonths;
                  final dueDate = loan.startDate.add(Duration(days: (index + 1) * 30));
                  final rate    = loan.interestRate ?? 0.0;
                  final monthly = rate > 0 ? loan.amount * rate / 100 : (loan.emiAmount ?? 0.0);

                  return GestureDetector(
                    onTap: () => _toggleMonth(context, loan, index, paidMonths, duration),
                    child: Container(
                      width: 140.w,
                      margin: EdgeInsets.only(right: 12.w, bottom: 8.h),
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: isPaid ? theme.primary.withOpacity(0.08) : Colors.white,
                        border: Border.all(color: isPaid ? theme.primary.withOpacity(0.3) : Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Month ${index + 1}', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: isPaid ? theme.primary : Colors.grey.shade700)),
                              Icon(isPaid ? Icons.check_circle : Icons.radio_button_unchecked, size: 16.sp, color: isPaid ? theme.primary : Colors.grey.shade400),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Text('${_monthName(dueDate.month)} ${dueDate.year}', style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600)),
                          SizedBox(height: 2.h),
                          Text('Due: ${dueDate.day}', style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade400)),
                          SizedBox(height: 6.h),
                          Text(monthly > 0 ? '₹${_fmt(monthly)}' : '-', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: isPaid ? Colors.green.shade700 : Colors.black87)),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            )"""
            
        old_block = content[start_idx:end_idx+12]
        content = content.replace(old_block, replacement)

    elif "interest_loan" in file:
        start_idx = content.find("ListView.separated(")
        if start_idx == -1: continue
        end_idx = content.find("          ),", start_idx)
        while True:
            if content[end_idx:end_idx+30].find("      ]),") != -1:
                break
            end_idx = content.find("          ),", end_idx + 1)
            if end_idx == -1: break
            
        replacement = """SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: List.generate(duration, (index) {
                  final isPaid   = index < paidMonths;
                  final dueDate  = loan.startDate.add(Duration(days: (index + 1) * 30));
                  return Container(
                    width: 140.w,
                    margin: EdgeInsets.only(right: 12.w, bottom: 8.h),
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: isPaid ? _bg.withOpacity(0.5) : Colors.white,
                      border: Border.all(color: isPaid ? _primary.withOpacity(0.3) : Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Month ${index + 1}', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: isPaid ? _primary : Colors.grey.shade700)),
                            Icon(isPaid ? Icons.check_circle : Icons.radio_button_unchecked, size: 16.sp, color: isPaid ? _primary : Colors.grey.shade400),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Text('${_month(dueDate.month)} ${dueDate.year}', style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600)),
                        SizedBox(height: 2.h),
                        Text('Due: ${dueDate.day}', style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade400)),
                        SizedBox(height: 6.h),
                        Text('₹${_fmt(monthly)}', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: isPaid ? Colors.green.shade700 : Colors.black87)),
                      ],
                    ),
                  );
                }),
              ),
            )"""
            
        old_block = content[start_idx:end_idx+12]
        content = content.replace(old_block, replacement)
        
    else: # business or hand loan
        start_idx = content.find("ListView.separated(")
        if start_idx == -1: continue
        end_idx = content.find("          ),", start_idx)
        while True:
            if content[end_idx:end_idx+30].find("      ]),") != -1:
                break
            end_idx = content.find("          ),", end_idx + 1)
            if end_idx == -1: break
            
        replacement = """SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: List.generate(duration, (index) {
                final isPaid   = index < paidMonths;
                final dueDate  = loan.startDate.add(Duration(days: (index + 1) * 30));
                return Container(
                  width: 140.w,
                  margin: EdgeInsets.only(right: 12.w, bottom: 8.h),
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: isPaid ? _bg.withOpacity(0.5) : Colors.white,
                    border: Border.all(color: isPaid ? _primary.withOpacity(0.3) : Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Month ${index + 1}', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: isPaid ? _primary : Colors.grey.shade700)),
                          Icon(isPaid ? Icons.check_circle : Icons.radio_button_unchecked, size: 16.sp, color: isPaid ? _primary : Colors.grey.shade400),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text('${_month(dueDate.month)} ${dueDate.year}', style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600)),
                      SizedBox(height: 2.h),
                      Text('Due: ${dueDate.day}', style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade400)),
                      SizedBox(height: 6.h),
                      Text(emi > 0 ? '₹${_fmt(emi)}' : '-', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: isPaid ? Colors.green.shade700 : Colors.black87)),
                    ],
                  ),
                );
              }),
            ),
          )"""
            
        old_block = content[start_idx:end_idx+12]
        content = content.replace(old_block, replacement)

    with open(file, 'w', encoding='utf-8') as f:
        f.write(content)

print("UI updated.")
