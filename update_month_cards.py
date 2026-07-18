import os
import glob
import re

pages_dir = 'lib/features/loans/presentation/pages'

for f_path in glob.glob(os.path.join(pages_dir, '*.dart')):
    if 'approval' in f_path or 'confirmation' in f_path or 'create' in f_path:
        continue
    with open(f_path, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content
    
    # 1. Inject isOverdue logic
    # Find: final dueDate = loan.startDate.add(\n                    Duration(days: (index + 1) * 30),\n                  );
    pattern_duedate = r"(final dueDate = loan\.startDate\.add\(\s*Duration\(days: \(index \+ 1\) \* 30\),\s*\);)"
    replacement_duedate = r"\1\n                  final isOverdue = !isPaid && dueDate.isBefore(DateTime.now());"
    content = re.sub(pattern_duedate, replacement_duedate, content)
    
    # 2. Update background color
    # Color depends on whether the file uses `_bg` or `theme.primary` for paid color.
    # In lender page: theme.primary.withOpacity(0.08)
    # In others: _bg.withOpacity(0.5)
    
    # Replace: color: isPaid ? _bg.withOpacity(0.5) : Colors.white,
    content = content.replace("color: isPaid ? _bg.withOpacity(0.5) : Colors.white,", "color: isPaid ? _bg.withOpacity(0.5) : (isOverdue ? Colors.red.shade50 : Colors.white),")
    # Replace: color: isPaid\n                            ? theme.primary.withOpacity(0.08)\n                            : Colors.white,
    content = re.sub(r"color: isPaid\s*\?\s*theme\.primary\.withOpacity\(0\.08\)\s*:\s*Colors\.white,", "color: isPaid ? theme.primary.withOpacity(0.08) : (isOverdue ? Colors.red.shade50 : Colors.white),", content)
    
    # 3. Update border color
    content = re.sub(r"color: isPaid\s*\?\s*_primary\.withOpacity\(0\.3\)\s*:\s*Colors\.grey\.shade200,", "color: isPaid ? _primary.withOpacity(0.3) : (isOverdue ? Colors.red.withOpacity(0.3) : Colors.grey.shade200),", content)
    content = re.sub(r"color: isPaid\s*\?\s*theme\.primary\.withOpacity\(0\.3\)\s*:\s*Colors\.grey\.shade200,", "color: isPaid ? theme.primary.withOpacity(0.3) : (isOverdue ? Colors.red.withOpacity(0.3) : Colors.grey.shade200),", content)

    # 4. Update text color
    content = re.sub(r"color: isPaid \? _primary : Colors\.grey\.shade700,", "color: isPaid ? _primary : (isOverdue ? Colors.red.shade700 : Colors.grey.shade700),", content)
    content = re.sub(r"color: isPaid\s*\?\s*theme\.primary\s*:\s*Colors\.grey\.shade700,", "color: isPaid ? theme.primary : (isOverdue ? Colors.red.shade700 : Colors.grey.shade700),", content)

    # 5. Update icon and icon color
    content = re.sub(r"isPaid\s*\?\s*Icons\.check_circle\s*:\s*Icons\.radio_button_unchecked,", "isPaid ? Icons.check_circle : (isOverdue ? Icons.cancel : Icons.radio_button_unchecked),", content)
    content = re.sub(r"color: isPaid \? _primary : Colors\.grey\.shade400,", "color: isPaid ? _primary : (isOverdue ? Colors.red.shade400 : Colors.grey.shade400),", content)
    content = re.sub(r"color: isPaid\s*\?\s*theme\.primary\s*:\s*Colors\.grey\.shade400,", "color: isPaid ? theme.primary : (isOverdue ? Colors.red.shade400 : Colors.grey.shade400),", content)

    if content != original:
        with open(f_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print('Updated', f_path)

