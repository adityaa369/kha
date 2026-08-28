import sys

with open('lib/data/models/loan_model.dart', 'rb') as f:
    data = f.read(50)
    print("HEX:", data.hex())
    print("CHARS:", data)
