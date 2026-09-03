import re

for path in ['lib/features/home/presentation/pages/home_page.dart', 'lib/features/loans/presentation/pages/loans_given_page.dart']:
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    new_fn = """  String _formatAmount(double amount) {
    if (amount == 0) return '\\u20B9 0';
    return '\\u20B9 ' + NumberFormat('#,##,##0', 'en_IN').format(amount);
  }"""
    
    content = re.sub(r'String _formatAmount\(double amount\) \{.*?\}', lambda m: new_fn, content, flags=re.DOTALL)
    
    if "import 'package:intl/intl.dart';" not in content:
        content = "import 'package:intl/intl.dart';\n" + content
        
    content = content.replace(",1", "\u20B9")
    content = content.replace("₹", "\u20B9")
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
