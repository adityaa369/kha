import os
import glob

files = glob.glob('lib/**/*.dart', recursive=True)
count = 0
for f in files:
    try:
        with open(f, 'r', encoding='utf-8') as file:
            content = file.read()
        
        new_content = content.replace('₹', '₹')
        
        if new_content != content:
            with open(f, 'w', encoding='utf-8') as file:
                file.write(new_content)
            count += 1
            print(f"Fixed {f}")
    except Exception as e:
        pass
print(f"Total fixed: {count}")
