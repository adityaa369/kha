import sys
sys.stdout.reconfigure(encoding='utf-8')
with open('lib/core/network/api_client.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()
    for i in range(165, 200):
        if i < len(lines):
            print(f"{i+1}: {lines[i].rstrip()}")
