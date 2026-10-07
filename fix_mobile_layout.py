import re

filepath = 'lib/features/loans/presentation/pages/create_loan_page.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace Interest Row
content = re.sub(
    r'(\s+)Row\(\s*crossAxisAlignment: CrossAxisAlignment\.start,\s*children: \[\s*Expanded\(\s*child: (KhaataTextField\([\s\S]*?label: \'Interest Amount\'[\s\S]*?\),)\s*\),\s*SizedBox\(width: 16\.w\),\s*Expanded\(\s*child: (KhaataTextField\([\s\S]*?label: \'Rate of Interest\'[\s\S]*?\),)\s*\),\s*\],\s*\),',
    r'\1Column(\n\1  crossAxisAlignment: CrossAxisAlignment.start,\n\1  children: [\n\1    \2\n\1    SizedBox(height: 16.h),\n\1    \3\n\1  ],\n\1),',
    content
)

# Replace Start Date & End Date Row
content = re.sub(
    r'(\s+)Row\(\s*children: \[\s*Expanded\(\s*child: (_DateSelector\([\s\S]*?label: \'Start Date\'[\s\S]*?\),)\s*\),\s*SizedBox\(width: 16\.w\),\s*Expanded\(\s*child: (_DateSelector\([\s\S]*?label: \'End Date\'[\s\S]*?\),)\s*\),\s*\],\s*\),',
    r'\1Column(\n\1  crossAxisAlignment: CrossAxisAlignment.start,\n\1  children: [\n\1    \2\n\1    SizedBox(height: 16.h),\n\1    \3\n\1  ],\n\1),',
    content
)

# Replace Start Date & Due Date Row
content = re.sub(
    r'(\s+)Row\(\s*children: \[\s*Expanded\(\s*child: (_DateSelector\([\s\S]*?label: \'Start Date\'[\s\S]*?\),)\s*\),\s*SizedBox\(width: 16\.w\),\s*Expanded\(\s*child: (_DateSelector\([\s\S]*?label: \'Due Date\'[\s\S]*?\),)\s*\),\s*\],\s*\),',
    r'\1Column(\n\1  crossAxisAlignment: CrossAxisAlignment.start,\n\1  children: [\n\1    \2\n\1    SizedBox(height: 16.h),\n\1    \3\n\1  ],\n\1),',
    content
)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print("Regex ran")
