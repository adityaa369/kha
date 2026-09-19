with open('lib/features/loans/presentation/pages/lender_loan_details_page.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()
    for i, line in enumerate(lines):
        if "activeLoan.loanStatus.isFinished" in line:
            # find enclosing method
            for j in range(i, -1, -1):
                if "Widget _" in lines[j] or "Widget build(" in lines[j]:
                    print(f"Method at {j+1}: {lines[j].strip()}")
                    break
            print(f"Usage at {i+1}: {line.strip()}")
