import glob

for path in glob.glob('lib/features/loans/presentation/**/*.dart', recursive=True):
    with open(path, 'r', encoding='utf-8') as f:
        c = f.read()
    
    if "?${" in c:
        c = c.replace("?${", "\u20B9${")
        with open(path, 'w', encoding='utf-8') as f:
            f.write(c)

print("Fixed question marks")
