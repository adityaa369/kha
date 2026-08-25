import os
import re

file_path = 'android/app/build.gradle.kts'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

flavor_pattern = re.compile(r'    flavorDimensions \+= "env".*?productFlavors \{.*?\}\n    \}\n', re.DOTALL)
content = re.sub(flavor_pattern, '', content)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Reverted build.gradle.kts")
