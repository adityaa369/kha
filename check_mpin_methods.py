import sys
sys.stdout.reconfigure(encoding='utf-8')
with open('server/controllers/auth.js', 'r', encoding='utf-8') as f:
    lines = f.readlines()
    for i, line in enumerate(lines):
        if "exports.getMpinStatus =" in line or "exports.setupMpin =" in line:
            start = i
            end = i + 30
            print(f"--- method ---")
            for j in range(start, min(end, len(lines))):
                print(f"{j+1}: {lines[j].rstrip()}")
