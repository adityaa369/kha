import os
import glob

pages_dir = 'lib/features/loans/presentation/pages'
target_files = [
    'business_loan_details_page.dart',
    'hand_loan_details_page.dart'
]

old_block = """          Row(
            children: [
              Expanded(
                child: _gradientStat(
                  'Next Credit',
                  emi > 0 ? '₹${_fmt(emi)}' : '-',
                ),
              ),
              Expanded(
                child: _gradientStat(
                  'Total Payable',
                  totalPayable > 0 ? '₹${_fmt(totalPayable)}' : '-',
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _gradientStat('Amount Paid', '₹${_fmt(amountPaid)}'),
              ),
              Expanded(
                child: _gradientStat(
                  'Amount Pending',
                  pendingAmount > 0 ? '₹${_fmt(pendingAmount)}' : '-',
                ),
              ),
            ],
          ),"""

new_block = """          Row(
            children: [
              Expanded(
                child: _gradientStat(
                  'Total Payable',
                  totalPayable > 0 ? '₹${_fmt(totalPayable)}' : '-',
                ),
              ),
              Expanded(
                child: _gradientStat('Amount Paid', '₹${_fmt(amountPaid)}'),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _gradientStat(
                  'Amount Pending',
                  pendingAmount > 0 ? '₹${_fmt(pendingAmount)}' : '-',
                ),
              ),
              Expanded(child: const SizedBox()),
            ],
          ),"""

for fname in target_files:
    f_path = os.path.join(pages_dir, fname)
    with open(f_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    if old_block in content:
        content = content.replace(old_block, new_block)
        with open(f_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print('Updated', f_path)
    else:
        print('Block not found in', f_path)
