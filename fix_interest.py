import sys
filepath = 'lib/features/loans/presentation/pages/interest_loan_details_page.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

target = 'onTap: () => _showDocumentDialog(context, url, isPdf, theme),'
replacement = '''onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => SecureDocumentViewer(documentId: url),
                );
              },'''
content = content.replace(target, replacement)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print('Fixed document viewer in interest details')
