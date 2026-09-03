with open('lib/data/repositories/loan_repository.dart', 'r', encoding='utf-8') as f:
    c = f.read()
c = c.replace("_apiClient.delete", "_api.delete")
with open('lib/data/repositories/loan_repository.dart', 'w', encoding='utf-8') as f:
    f.write(c)

with open('lib/features/loans/presentation/pages/lender_loan_details_page.dart', 'r', encoding='utf-8') as f:
    c = f.read()
# Replace AppConstants.loanConfirmation, extra: loan
old_push = "context.push(AppConstants.loanConfirmation, extra: loan)"
new_push = """context.push('/loan-confirmation', extra: {
                        'loan_id': loan.id,
                        'borrower_name': loan.borrowerName,
                        'borrower_phone': loan.mobile,
                        'amount': loan.amountPaise,
                      })"""
c = c.replace(old_push, new_push)
with open('lib/features/loans/presentation/pages/lender_loan_details_page.dart', 'w', encoding='utf-8') as f:
    f.write(c)
