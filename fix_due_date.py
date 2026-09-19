import re
import glob

for file_path in glob.glob('lib/features/loans/presentation/pages/*_loan_details_page.dart'):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    replacement = '''
                        TextSpan(
                          text: isFinished ? 'Loan Status: ' : 'Next Payment Due Date: ',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        TextSpan(
                          text: isFinished ? 'Fully Settled' : _dateStr(nextDue),
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: isFinished ? Colors.blue.shade700 : Colors.black87,
                          ),
                        ),
'''
    
    # replace the exact block
    pattern = r'''TextSpan\(\s*text: 'Next Payment Due Date: ',\s*style: TextStyle\(\s*fontSize: 11\.sp,\s*color: Colors\.grey\.shade600,\s*\),\s*\),\s*TextSpan\(\s*text: _dateStr\(nextDue\),\s*style: TextStyle\(\s*fontSize: 11\.sp,\s*fontWeight: FontWeight\.w700,\s*color: Colors\.black87,\s*\),\s*\),'''
    
    new_content = re.sub(pattern, replacement.strip() + ',', content)
    
    if new_content != content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
