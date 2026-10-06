import sys

filepath = 'lib/features/loans/presentation/widgets/repayment_timeline_widget.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace(
    'return Container(\n              padding: EdgeInsets.all(16.w),',
    'return Container(\n              width: double.infinity,\n              padding: EdgeInsets.all(16.w),'
)
with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
