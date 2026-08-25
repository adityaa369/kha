import os

file_path = 'android/app/src/main/AndroidManifest.xml'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('android:label="khatha"', 'android:label="@string/app_name"')

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Updated AndroidManifest.xml to use dynamic app_name")
