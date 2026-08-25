import 'package:flutter/material.dart';
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
