import os
import re

file_path = 'lib/features/loans/presentation/pages/lender_loan_details_page.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("tx['amount']", "tx.amount")
content = content.replace("tx['type']", "tx.type")
content = content.replace("tx['createdAt']", "tx.createdAt")
content = content.replace("tx['status']", "tx.status")
content = content.replace("tx['note']", "tx.note")
content = content.replace("DateTime.parse(tx.createdAt)", "tx.createdAt")
content = content.replace("date != null", "true")
content = content.replace("date.add", "tx.createdAt!.add")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Fixed legacy tx property access in lender details!")
