import os
import glob

files = glob.glob('lib/**/*.dart', recursive=True)
count = 0
for f in files:
    try:
        with open(f, 'r', encoding='utf-8') as file:
            content = file.read()
        
        if 'â‚¹' in content or ',1' in content or '₹' in content:
            # Let's just fix known corruption
            new_content = content.replace('â‚¹', '₹').replace(',1', '₹')
            
            # also wait, some might just be . Let's see if there are other corrupted strings.
            if new_content != content:
                with open(f, 'w', encoding='utf-8') as file:
                    file.write(new_content)
                count += 1
                print(f"Fixed {f}")
    except Exception as e:
        pass
print(f"Total fixed: {count}")
