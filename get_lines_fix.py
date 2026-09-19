with open('lib/features/loans/presentation/pages/lender_loan_details_page.dart', 'r', encoding='utf-8') as f:
    for i, line in enumerate(f.readlines()):
        if 380 <= i+1 <= 390 or 525 <= i+1 <= 535:
            print(f"{i+1}: {line.strip()}")
