import os

file_path = 'lib/data/models/loan_model.dart'
with open(file_path, 'rb') as f:
    content = f.read()

if content.startswith(b'\xef\xbb\xbf'):
    content = content[3:]
    with open(file_path, 'wb') as f:
        f.write(content)
    print("BOM removed from loan_model.dart")
else:
    # Try string decode and replace just in case
    text = content.decode('utf-8', errors='ignore')
    if text.startswith('\ufeff'):
        text = text[1:]
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(text)
        print("BOM removed via string replacement")
    else:
        print("No BOM found")
