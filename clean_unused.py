import re

def clean_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find and delete _showUpdateProgressChecklistDialog
    start_idx = content.find('  void _showUpdateProgressChecklistDialog(')
    if start_idx != -1:
        # Find the next method or end of class
        end_idx = content.find('  // Payment Schedule Dialog', start_idx)
        if end_idx == -1:
            end_idx = content.find('  // Record Interest Dialog', start_idx)
        if end_idx == -1:
            end_idx = content.find('  void _showRecordPrincipalDialog(', start_idx)
        if end_idx != -1:
            content = content[:start_idx] + content[end_idx:]

    # Find and delete _MonthCheckItem
    start_idx = content.find('class _MonthCheckItem {')
    if start_idx != -1:
        # It's usually the last class or near the end. Let's find the end of it
        end_idx = content.find('}', start_idx)
        if end_idx != -1:
            end_idx = content.find('}', end_idx + 1) # inner methods might exist, but it's a simple struct
            if end_idx != -1:
                content = content[:start_idx] + content[end_idx + 1:]

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

clean_file('lib/features/loans/presentation/pages/hand_loan_details_page.dart')
clean_file('lib/features/loans/presentation/pages/interest_loan_details_page.dart')
