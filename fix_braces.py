with open('lib/main.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    for i, line in enumerate(lines):
        if i == 41: # Line 42 (try {)
            continue
        if i == 55: # Line 56 (});)
            continue
        f.write(line)
