import re
import glob

for file_path in glob.glob('lib/features/loans/presentation/pages/*_loan_details_page.dart'):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    replacement = '''
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: loan.loanStatus.isFinished ? Colors.blue.shade50 : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      loan.status.toUpperCase(),
                      style: TextStyle(
                        color: loan.loanStatus.isFinished ? Colors.blue.shade700 : Colors.green.shade700,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
'''
    
    # regex to replace exactly the Active Loan container
    pattern = r'Container\(\s*padding: EdgeInsets\.symmetric\(\s*horizontal: 12\.w,\s*vertical: 6\.h,\s*\),\s*decoration: BoxDecoration\(\s*color: Colors\.green\.shade50,\s*borderRadius: BorderRadius\.circular\(20\.r\),\s*\),\s*child: Text\(\s*\'Active Loan\',\s*style: TextStyle\(\s*color: Colors\.green\.shade700,\s*fontSize: 12\.sp,\s*fontWeight: FontWeight\.bold,\s*\),\s*\),\s*\),'
    
    new_content = re.sub(pattern, replacement.strip() + ',', content)
    
    if new_content != content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
