import os

file_path = 'lib/main.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("void main() async {", "Future<void> runMainApp() async {")
content = content.replace("WidgetsFlutterBinding.ensureInitialized();", "// WidgetsFlutterBinding.ensureInitialized() handled in entry point")
content = content.replace("await dotenv.load(fileName: \".env\");", "// dotenv load handled in entry point")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Updated main.dart to export runMainApp")
