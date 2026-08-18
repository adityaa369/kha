import re
import os
import glob

def process_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content

    # 1. Replace _stat function
    stat_func_pattern = re.compile(
        r'Widget _stat\(String label, String value, \{Color\? valueColor\}\)\s*\{.*?\n\s*\}\n', 
        re.DOTALL
    )
    
    new_stat_func = """Widget _stat(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w400,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 3.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.black87,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
"""

    if '_stat(' in content:
        # manual replace since the regex might be tricky to catch the exact end
        content = re.sub(
            r'Widget _stat\(String label, String value, \{Color\? valueColor\}\) \{[\s\S]*?    \n  \}', 
            new_stat_func, 
            content
        )
        content = re.sub(
            r'Widget _stat\(String label, String value, \{Color\? valueColor\}\) \{[\s\S]*?\n  \}\n', 
            new_stat_func, 
            content
        )

    # 2. Add crossAxisAlignment: CrossAxisAlignment.start to Row with Expanded children
    # We'll look for Row( \n children: [ \n Expanded( \n child: _stat( ... )
    
    # We will use regex to find Rows with two Expanded children for stats.
    # Pattern: Row(\n\s*children: \[\n\s*Expanded(\n\s*child: _stat|\s*child: _interestStat|\s*child: _gradientStat)
    row_pattern = re.compile(
        r'(Row\(\s*children: \[\s*)(Expanded\(\s*child: (_stat|_gradientStat|_interestStat|Text|Column).*?\),\s*)(Expanded\(\s*child:.*?)\],)',
        re.DOTALL
    )
    
    def repl_row(m):
        start = m.group(1)
        if 'crossAxisAlignment' not in start:
            start = start.replace('Row(', 'Row(\n                  crossAxisAlignment: CrossAxisAlignment.start,')
        exp1 = m.group(2)
        exp2 = m.group(4)
        # Add SizedBox(width: 12.w) between exp1 and exp2 if not present
        if 'SizedBox' not in exp1 and 'SizedBox' not in exp2:
            exp1 = exp1 + '                  SizedBox(width: 12.w),\n'
        return start + exp1 + exp2

    content = row_pattern.sub(repl_row, content)

    # Special handling for Rows with 3 Expanded children in lender_loan_details_page.dart
    row_pattern_3 = re.compile(
        r'(Row\(\s*children: \[\s*)(Expanded\(\s*child: (_stat|_gradientStat|_interestStat).*?\),\s*)(Expanded\(\s*child: (_stat|_gradientStat|_interestStat).*?\),\s*)(Expanded\(\s*child:.*?)\],)',
        re.DOTALL
    )
    def repl_row_3(m):
        start = m.group(1)
        if 'crossAxisAlignment' not in start:
            start = start.replace('Row(', 'Row(\n                  crossAxisAlignment: CrossAxisAlignment.start,')
        exp1 = m.group(2)
        exp2 = m.group(4)
        exp3 = m.group(6)
        return start + exp1 + '                  SizedBox(width: 12.w),\n' + exp2 + '                  SizedBox(width: 12.w),\n' + exp3

    content = row_pattern_3.sub(repl_row_3, content)

    # 3. Replace 4.h with 3.h in _stat, _gradientStat, _interestStat manually
    # Just replace SizedBox(height: 4.h) with SizedBox(height: 3.h) within the stat functions
    def replace_h(func_name, content_str):
        # find the function definition
        start_idx = content_str.find(func_name)
        if start_idx == -1: return content_str
        end_idx = content_str.find('}', start_idx)
        if end_idx == -1: return content_str
        
        func_body = content_str[start_idx:end_idx]
        new_func_body = func_body.replace('SizedBox(height: 4.h)', 'SizedBox(height: 3.h)')
        return content_str[:start_idx] + new_func_body + content_str[end_idx:]

    content = replace_h('Widget _gradientStat', content)
    content = replace_h('Widget _interestStat', content)

    # 4. For any Card/Container headers, ensure: padding: EdgeInsets.all(14.w) (not 8.w or 10.w or 16.w)
    # This is applied to Padding(padding: EdgeInsets.all(16.w), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween
    header_pad_pattern = re.compile(
        r'Padding\(\s*padding: EdgeInsets\.all\((16|10|8)\.w\),\s*child: Row\(\s*mainAxisAlignment: MainAxisAlignment\.spaceBetween'
    )
    content = header_pad_pattern.sub(r'Padding(\n            padding: EdgeInsets.all(14.w),\n            child: Row(\n              mainAxisAlignment: MainAxisAlignment.spaceBetween', content)

    if content != original_content:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f'Updated {path}')
    else:
        print(f'No changes for {path}')

files = glob.glob(r'lib/features/loans/presentation/pages/*.dart')
targets = [
    'business_loan_details_page.dart',
    'hand_loan_details_page.dart',
    'interest_loan_details_page.dart',
    'lender_loan_details_page.dart',
    'loan_approval_page.dart',
    'loan_confirmation_page.dart'
]

for f in files:
    if any(t in f for t in targets):
        process_file(f)
