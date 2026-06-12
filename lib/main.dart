import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'config/constants.dart';
import 'core/blocs/auth/auth_cubit.dart';
import 'core/blocs/loans/loan_cubit.dart';
import 'core/blocs/chit_funds/chit_fund_cubit.dart';
import 'data/repositories/chit_fund_repository.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/services/biometric_auth_service.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp().then((_) async {
      try {
        await FirebaseAppCheck.instance.activate(
          providerAndroid: kDebugMode ? const AndroidDebugProvider() : const AndroidPlayIntegrityProvider(),
          providerApple: kDebugMode ? const AppleDebugProvider() : const AppleDeviceCheckProvider(),
        );
        print("Firebase App Check activated successfully.");
      } catch (e) {
        print("Firebase App Check activation failed: $e");
      }
      try {
        NotificationService.initialize();
      } catch (e) {
        print("Notification init failed: $e");
      }
    });
    
    await dotenv.load(fileName: ".env");

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    await SentryFlutter.init((options) {
      options.dsn = dotenv.env['SENTRY_DSN'] ?? '';
      options.tracesSampleRate = 1.0;
    }, appRunner: () => runApp(const KhaataApp()));

  } catch (globalError, stackTrace) {
    runApp(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.red,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Text(
                'CRITICAL APP LAUNCH FAILURE:\n\n$globalError\n\n$stackTrace',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ),
      )
    );
  }
}

class KhaataApp extends StatelessWidget {
  const KhaataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthCubit()..checkAuthStatus()),
        BlocProvider(create: (_) => LoanCubit()),
        BlocProvider(create: (_) => ChitFundCubit(ChitFundRepository())),
      ],
      child: NotificationListenerWidget(
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) {
            return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              title: 'Khaata',
              theme: KhaataTheme.lightTheme,
              routerConfig: router,
            );
          },
        ),
      ),
    );
  }
}

class NotificationListenerWidget extends StatefulWidget {
  final Widget child;
  const NotificationListenerWidget({super.key, required this.child});

  @override
  State<NotificationListenerWidget> createState() => _NotificationListenerWidgetState();
}

class _NotificationListenerWidgetState extends State<NotificationListenerWidget> {
  StreamSubscription? _sub;
  StreamSubscription? _openSub;

  Future<void> _handleNotificationRouting(RemoteMessage message) async {
    final authenticated = await BiometricAuthService.authenticate();
    if (authenticated) {
      if (message.data['type'] == 'LOAN_CREATED') {
        router.go(AppConstants.myLoans);
      } else if (message.data['type'] == 'LOAN_OTP' || message.data['type'] == 'LOAN_INIT_OTP') {
        router.go(AppConstants.notifications);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _sub = NotificationService.onMessageStream.stream.listen((_) {
      context.read<LoanCubit>().fetchLoans();
      context.read<ChitFundCubit>().loadInvitesAndOwned();
    });
    
    _openSub = FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationRouting(message);
    });

    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _handleNotificationRouting(message);
          }
        });
      }
    });
  }
  
  @override
  void dispose() {
    _sub?.cancel();
    _openSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
