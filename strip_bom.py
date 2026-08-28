import os

file_path = 'lib/data/models/loan_model.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('\ufeff', '')

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Stripped U+FEFF from loan_model.dart")
