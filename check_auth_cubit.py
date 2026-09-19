with open('lib/core/blocs/auth/auth_cubit.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()
    for i in range(480, 505):
        if i < len(lines):
            print(f"{i+1}: {lines[i].rstrip()}")
