import sys
sys.stdout.reconfigure(encoding='utf-8')
with open('server/controllers/loans.js', 'r', encoding='utf-8') as f:
    lines = f.readlines()
    for i in range(450, 470):
        print(f"{i+1}: {lines[i].rstrip()}")
