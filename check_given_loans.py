import sys
sys.stdout.reconfigure(encoding='utf-8')
with open('server/controllers/loans.js', 'r', encoding='utf-8') as f:
    lines = f.readlines()
    for i in range(270, 310):
        if i < len(lines):
            print(f"{i+1}: {lines[i].rstrip()}")
