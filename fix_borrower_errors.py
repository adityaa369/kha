import glob

def fix(path):
    with open(path, 'r', encoding='utf-8') as f:
        c = f.read()

    # Fix theme issue in recentTransactions
    c = c.replace("_recentTransactions(LoanModel loan, _TypeTheme theme)", "_recentTransactions(LoanModel loan)")
    c = c.replace("_recentTransactions(activeLoan, theme)", "_recentTransactions(activeLoan)")
    c = c.replace("color: theme.bg,", "color: _bg,")
    c = c.replace("color: theme.primary,", "color: _primary,")
    
    # Fix duration variable scope error
    c = c.replace("(loan.durationMonths ?? duration)", "(loan.durationMonths ?? 0)")
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(c)

for path in [
    'lib/features/loans/presentation/pages/hand_loan_details_page.dart',
    'lib/features/loans/presentation/pages/business_loan_details_page.dart',
    'lib/features/loans/presentation/pages/interest_loan_details_page.dart',
]:
    fix(path)
print("Fixed borrower errors")
