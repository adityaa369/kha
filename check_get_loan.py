import sys
sys.stdout.reconfigure(encoding='utf-8')
with open('server/controllers/loans.js', 'r', encoding='utf-8') as f:
    lines = f.readlines()
    for i, line in enumerate(lines):
        if "exports.getLoanById =" in line:
            start = i
            end = i + 40
            for j in range(start, min(end, len(lines))):
                print(f"{j+1}: {lines[j].rstrip()}")
            break
