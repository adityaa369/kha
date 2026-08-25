import os

file_path = 'lib/main.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("Future<void> runMainApp() async {", "void main() async {")
content = content.replace("// WidgetsFlutterBinding.ensureInitialized() handled in entry point", "WidgetsFlutterBinding.ensureInitialized();")
content = content.replace("// dotenv load handled in entry point", "await dotenv.load(fileName: \".env\");")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Reverted main.dart")
