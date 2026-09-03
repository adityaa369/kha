import re

file_path = 'lib/data/models/loan_model.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

new_display_amount = "String get displayAmount {\n    if (amountPaise == 0) return '-';\n    return '\\u20B9 ${NumberFormat(\\'#,##,##0\\', \\'en_IN\\').format(amount)}';\n  }"
content = re.sub(r"String get displayAmount \{.*?\}", lambda x: new_display_amount, content, flags=re.DOTALL)

content = re.sub(r"static String _formatNumber\(double number\) \{.*?\);?\n\s*\}", "", content, flags=re.DOTALL)

if "import 'package:intl/intl.dart';" not in content:
    content = "import 'package:intl/intl.dart';\n" + content

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
