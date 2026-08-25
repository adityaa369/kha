import 'package:flutter/material.dart';
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
