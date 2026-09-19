with open('server/controllers/loans.js', 'r', encoding='utf-8') as f:
    lines = f.readlines()

with open('server/controllers/loans.js', 'w', encoding='utf-8') as f:
    for i, line in enumerate(lines):
        if i == 464: # Line 465 (0-indexed 464)
            continue
        f.write(line)
