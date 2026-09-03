import os
import glob

def fix_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    replacements = {
        '\u00e2\u20ac\u201d': '\u2014',
        '\u00e2\u201a\u00b9': '\u20B9',
        '\u00f0\u0178\u2019\u00b0': '\U0001F4B0',
        '\u00e2\u0161\u2013\u00ef\u00b8\u008f': '\u2696\uFE0F',
        '\u00f0\u0178\u008f\u00a2': '\U0001F3E2',
        '\u00e2\u0153\u2026': '\u2705',
        '\ufffd\"?\ufffd\"?\ufffd\"?': '---',
    }
    
    for bad, good in replacements.items():
        content = content.replace(bad, good)
        
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

for path in glob.glob('lib/features/loans/presentation/**/*.dart', recursive=True):
    fix_file(path)

print("Fixed Mojibake")
