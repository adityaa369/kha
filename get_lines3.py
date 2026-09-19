with open('lib/features/loans/presentation/pages/lender_loan_details_page.dart', 'r', encoding='utf-8') as f:
    with open('lines_output.txt', 'w', encoding='utf-8') as out:
        for i, line in enumerate(f.readlines()):
            if 335 <= i+1 <= 350:
                out.write(f"{i+1}: {line.strip()}\n")
