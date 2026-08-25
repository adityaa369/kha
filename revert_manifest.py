import os

file_path = 'android/app/src/main/AndroidManifest.xml'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('android:label="@string/app_name"', 'android:label="khatha"')

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Reverted AndroidManifest.xml")
