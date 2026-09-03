import glob

def fix(path):
    with open(path, 'r', encoding='utf-8') as f:
        c = f.read()

    replacements = {
        "dY\'3 Record Payment": "\U0001F4B0 Record Payment", # ??
        "dY\'3 Add Credit": "\U0001F4B0 Add Credit",
        "% Record Interest Payment": "\U0001F4B0 Record Interest Payment",
        "marked as paid \ufffdo\"": "marked as paid \u2705", # ?
        "\u00e2\u20ac\u201d": "\u2014",
        "A\ufffdsA1": "\u20B9", # ?
        "?": "\u20B9",
    }
    
    for bad, good in replacements.items():
        c = c.replace(bad, good)
        
    with open(path, 'w', encoding='utf-8') as f:
        f.write(c)

for path in glob.glob('lib/features/loans/presentation/**/*.dart', recursive=True):
    fix(path)
    
print("Fixed strings")
