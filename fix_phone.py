with open('lib/features/loans/presentation/widgets/flexible_payment_sheet.dart', 'r', encoding='utf-8') as f:
    c = f.read()

c = c.replace("final phone = '+91';", "final phone = '+91${widget.loan.mobile ?? ''}';")

with open('lib/features/loans/presentation/widgets/flexible_payment_sheet.dart', 'w', encoding='utf-8') as f:
    f.write(c)
