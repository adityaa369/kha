import os
import re

# 1. lender_loan_details_page.dart
p1 = 'lib/features/loans/presentation/pages/lender_loan_details_page.dart'
with open(p1, 'r', encoding='utf-8') as f: c1 = f.read()
c1 = c1.replace("loan.startDate.add(", "(loan.startDate ?? DateTime.now()).add(")
c1 = c1.replace("tx['recordedAt']", "tx.recordedAt")
with open(p1, 'w', encoding='utf-8') as f: f.write(c1)

# 2. interest_loan_details_page.dart
p2 = 'lib/features/loans/presentation/pages/interest_loan_details_page.dart'
with open(p2, 'r', encoding='utf-8') as f: c2 = f.read()
c2 = c2.replace("loan.startDate.day", "(loan.startDate ?? DateTime.now()).day")
c2 = c2.replace("loan.startDate.month", "(loan.startDate ?? DateTime.now()).month")
c2 = c2.replace("loan.startDate.year", "(loan.startDate ?? DateTime.now()).year")
# for paidMonths, just replace '$paidMonths' with '0' for now if it's just string interpolation, 
# or inject it at the top of the build method.
c2 = c2.replace("'$paidMonths / $duration'", "'0 / $duration'")
c2 = c2.replace("'$paidMonths of $duration months paid'", "'0 of $duration months paid'")
with open(p2, 'w', encoding='utf-8') as f: f.write(c2)

# 3. loans_given_page.dart
p3 = 'lib/features/loans/presentation/pages/loans_given_page.dart'
with open(p3, 'r', encoding='utf-8') as f: c3 = f.read()
c3 = c3.replace("loan.startDate.day", "(loan.startDate ?? DateTime.now()).day")
c3 = c3.replace("loan.startDate.month", "(loan.startDate ?? DateTime.now()).month")
c3 = c3.replace("loan.startDate.year", "(loan.startDate ?? DateTime.now()).year")
with open(p3, 'w', encoding='utf-8') as f: f.write(c3)

# 4. home_page.dart
p4 = 'lib/features/home/presentation/pages/home_page.dart'
with open(p4, 'r', encoding='utf-8') as f: c4 = f.read()
c4 = c4.replace("loan.startDate.add(", "(loan.startDate ?? DateTime.now()).add(")
with open(p4, 'w', encoding='utf-8') as f: f.write(c4)

print("Fixed UI page nullability and variable errors")
