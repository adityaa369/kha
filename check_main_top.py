with open('lib/main.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()
    for i in range(1, 40):
        print(f"{i+1}: {lines[i].rstrip()}")
