import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../services/notification_service.dart';
import '../../../firebase_options.dart';

abstract class AppBootstrapState {}

class AppBootstrapInitial extends AppBootstrapState {}

class AppBootstrapLoading extends AppBootstrapState {}

class AppBootstrapSuccess extends AppBootstrapState {}

class AppBootstrapError extends AppBootstrapState {
  final String error;
  AppBootstrapError(this.error);
}

class AppBootstrapCubit extends Cubit<AppBootstrapState> {
  AppBootstrapCubit() : super(AppBootstrapInitial());

  Future<void> initializeApp() async {
    emit(AppBootstrapLoading());
    try {
      // 1. Firebase Initialization
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // 2. Firebase App Check
      try {
        await FirebaseAppCheck.instance.activate(
          providerAndroid: kDebugMode
              ? const AndroidDebugProvider()
              : const AndroidPlayIntegrityProvider(),
          providerApple: kDebugMode
              ? const AppleDebugProvider()
              : const AppleDeviceCheckProvider(),
        );
      } catch (e) {
        debugPrint('Firebase AppCheck initialization failed: $e');
      }

      // 3. DotEnv
      try {
        await dotenv.load(fileName: ".env");
      } catch (e) {
        debugPrint('Error loading .env file: $e');
      }

      // 4. Notification Service
      try {
        await NotificationService.initialize();
      } catch (e) {
        debugPrint('Error initializing notification service: $e');
      }

      // Tell flutter_native_splash to remove the splash screen if we want,
      // but wait until the first real UI renders.
      emit(AppBootstrapSuccess());
    } catch (e) {
      emit(AppBootstrapError(e.toString()));
    }
  }
}
