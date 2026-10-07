import sys
import re

def remove_legacy(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find where _showDocumentDialog starts
    idx = content.find('  void _showDocumentDialog(')
    if idx != -1:
        content = content[:idx]
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content + '}\n')
        print(f"Removed legacy from {filepath}")
    else:
        print(f"Not found in {filepath}")

remove_legacy('lib/features/loans/presentation/pages/lender_loan_details_page.dart')
remove_legacy('lib/features/loans/presentation/pages/interest_loan_details_page.dart')
