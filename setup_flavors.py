import os

env_config = """enum AppFlavor { staging, production }

class EnvConfig {
  static late final AppFlavor flavor;
  static late final String apiUrl;
  static late final String appName;

  static void init({
    required AppFlavor flavor,
    required String apiUrl,
    required String appName,
  }) {
    EnvConfig.flavor = flavor;
    EnvConfig.apiUrl = apiUrl;
    EnvConfig.appName = appName;
  }
}
"""
os.makedirs('lib/core/config', exist_ok=True)
with open('lib/core/config/env_config.dart', 'w', encoding='utf-8') as f:
    f.write(env_config)

main_staging = """import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/config/env_config.dart';
import 'main.dart' as app;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load staging specific environment variables (if required)
  await dotenv.load(fileName: ".env.staging");
  
  EnvConfig.init(
    flavor: AppFlavor.staging,
    apiUrl: 'https://staging-api.khataa.in',
    appName: 'Khataa Staging',
  );

  app.runMainApp();
}
"""
with open('lib/main_staging.dart', 'w', encoding='utf-8') as f:
    f.write(main_staging)

main_prod = """import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/config/env_config.dart';
import 'main.dart' as app;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load production specific environment variables
  await dotenv.load(fileName: ".env.production");
  
  EnvConfig.init(
    flavor: AppFlavor.production,
    apiUrl: 'https://api.khataa.in',
    appName: 'Khataa',
  );

  app.runMainApp();
}
"""
with open('lib/main_production.dart', 'w', encoding='utf-8') as f:
    f.write(main_prod)

print("Created Dart entry points and EnvConfig")
