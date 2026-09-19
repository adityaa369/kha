import sys
sys.stdout.reconfigure(encoding='utf-8')
with open('lib/features/auth/presentation/pages/otp_page.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()
    for i in range(20, 100):
        if i < len(lines):
            print(f"{i+1}: {lines[i].rstrip()}")
