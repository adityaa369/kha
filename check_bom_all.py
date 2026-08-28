import os

with open('lib/data/models/loan_model.dart', 'rb') as f:
    data = f.read()

index = data.find(b'\xef\xbb\xbf')
if index != -1:
    print(f"Found UTF-8 BOM at byte index {index}")
else:
    print("No UTF-8 BOM found in file")

index2 = data.find(b'\xff\xfe')
if index2 != -1:
    print(f"Found UTF-16 LE BOM at byte index {index2}")

index3 = data.find(b'\xfe\xff')
if index3 != -1:
    print(f"Found UTF-16 BE BOM at byte index {index3}")
    
# Let's also check for \ufeff as utf-8 encoded string if we decode it
text = data.decode('utf-8', errors='ignore')
index4 = text.find('\ufeff')
if index4 != -1:
    print(f"Found U+FEFF at string index {index4}")
