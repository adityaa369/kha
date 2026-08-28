import re

file_path = 'lib/data/models/loan_model.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Fix Mojibake
content = content.replace(",1 ${_formatNumber(amount)}", "\u20B9 ${_formatNumber(amount)}")
content = content.replace("',1 ${_formatNumber(amount)}", "\u20B9 ${_formatNumber(amount)}")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
