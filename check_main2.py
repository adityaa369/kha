with open('lib/main.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()
    for i in range(30, 60):
        if i < len(lines):
            print(f"{i+1}: {lines[i].rstrip()}")
