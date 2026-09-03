with open('lib/features/loans/presentation/pages/create_loan_page.dart', 'r', encoding='utf-8') as f:
    c = f.read()
c = c.replace("'amount': ((double.tryParse(_amountController.text) ?? 0.0) * 100).toInt(),", "'amount': double.tryParse(_amountController.text) ?? 0.0,")
# Also fix ? inside
c = c.replace("?${amount.toStringAsFixed(2)}", "\u20B9${amount.toStringAsFixed(2)}")
c = c.replace("?${totalAmount.toStringAsFixed(2)}", "\u20B9${totalAmount.toStringAsFixed(2)}")
with open('lib/features/loans/presentation/pages/create_loan_page.dart', 'w', encoding='utf-8') as f:
    f.write(c)
