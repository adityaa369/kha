import os
import re
import shutil

# 1. Delete Staging Files
try: os.remove('lib/main_staging.dart')
except: pass
try: os.remove('lib/main_production.dart')
except: pass
try: os.remove('lib/core/config/env_config.dart')
except: pass
try: shutil.rmtree('lib/core/config')
except: pass

# 2. Revert AndroidManifest
manifest_path = 'android/app/src/main/AndroidManifest.xml'
with open(manifest_path, 'r', encoding='utf-8') as f:
    manifest = f.read()
manifest = manifest.replace('android:label="@string/app_name"', 'android:label="khatha"')
with open(manifest_path, 'w', encoding='utf-8') as f:
    f.write(manifest)

# 3. Revert build.gradle.kts
gradle_path = 'android/app/build.gradle.kts'
with open(gradle_path, 'r', encoding='utf-8') as f:
    gradle = f.read()
flavor_pattern = re.compile(r'    flavorDimensions \+= "env".*?productFlavors \{.*?\}\n', re.DOTALL)
gradle = re.sub(flavor_pattern, '', gradle)
with open(gradle_path, 'w', encoding='utf-8') as f:
    f.write(gradle)

# 4. Restore google-services.json
try: shutil.copy('android/app/src/production/google-services.json', 'android/app/google-services.json')
except: pass
try: shutil.rmtree('android/app/src/staging')
except: pass
try: shutil.rmtree('android/app/src/production')
except: pass

# 5. Revert main.dart
main_path = 'lib/main.dart'
with open(main_path, 'r', encoding='utf-8') as f:
    main_dart = f.read()
main_dart = main_dart.replace("Future<void> runMainApp() async {", "void main() async {")
main_dart = main_dart.replace("// WidgetsFlutterBinding.ensureInitialized() handled in entry point", "WidgetsFlutterBinding.ensureInitialized();")
main_dart = main_dart.replace("// dotenv load handled in entry point", "await dotenv.load(fileName: \".env\");")
with open(main_path, 'w', encoding='utf-8') as f:
    f.write(main_dart)

# 6. Revert constants.dart
const_path = 'lib/config/constants.dart'
with open(const_path, 'r', encoding='utf-8') as f:
    const_dart = f.read()
const_dart = const_dart.replace("import '../core/config/env_config.dart';\n", "")
const_dart = const_dart.replace(
    "static String get baseUrl {\n    return '${EnvConfig.apiUrl}/api';\n  }", 
    "static const String _prodUrl = 'https://khataa-backend.onrender.com';\n  static String get baseUrl {\n    return dotenv.env['BASE_URL'] ?? '$_prodUrl/api';\n  }"
)
with open(const_path, 'w', encoding='utf-8') as f:
    f.write(const_dart)

print("Safe Revert Complete")
