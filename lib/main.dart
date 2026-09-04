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
import 'core/blocs/loans/portfolio_cubit.dart';
import 'data/repositories/loan_repository.dart';
import 'core/blocs/chit_funds/chit_fund_cubit.dart';
import 'data/repositories/chit_fund_repository.dart';
import 'features/home/presentation/cubit/notification_cubit.dart';
import 'core/network/api_client.dart';
import 'core/utils/secure_storage.dart';
import 'core/blocs/admin/admin_cubit.dart';
import 'core/blocs/system/system_state_cubit.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'firebase_options.dart';

final systemStateCubit = SystemStateCubit();

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).then((_) async {
      try {
        await FirebaseAppCheck.instance.activate(
          providerAndroid: kDebugMode
              ? const AndroidDebugProvider()
              : const AndroidPlayIntegrityProvider(),
          providerApple: kDebugMode
              ? const AppleDebugProvider()
              : const AppleDeviceCheckProvider(),
        );
        debugPrint("Firebase App Check activated successfully.");
      } catch (e) {
        debugPrint("Firebase App Check activation failed: $e");
      }
      try {
        NotificationService.initialize();
      } catch (e) {
        debugPrint("Notification init failed: $e");
      }
    });

    await dotenv.load(fileName: ".env");

    // Wire up global auth error handlers â€” clears session and redirects to login
    ApiClient.onMaintenanceMode = () {
      systemStateCubit.pauseFinancialOperations();
    };
    ApiClient.onUnauthorized = () async {
      await SecureStorage.clearAuthData();
      router.go('/login');
    };
    ApiClient.onTokenExpired = () async {
      await SecureStorage.clearAuthData();
      router.go('/login');
    };

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

    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Material(
        color: Colors.white,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: KhaataTheme.primaryBlue, size: 60),
                const SizedBox(height: 16),
                const Text('Something went wrong', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 8),
                Text(details.exceptionAsString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ),
      );
    };

    await SentryFlutter.init((options) {
      options.dsn = dotenv.env['SENTRY_DSN'] ?? '';
      options.tracesSampleRate = 1.0;
    }, appRunner: () => runApp(const KhaataApp()));
  } catch (globalError, stackTrace) {
    runApp(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Text(
                'CRITICAL APP LAUNCH FAILURE:\n\n$globalError\n\n$stackTrace',
                style: const TextStyle(color: Colors.black87, fontSize: 14),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class KhaataApp extends StatelessWidget {
  const KhaataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => LoanRepository()),
        RepositoryProvider(create: (_) => ChitFundRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: systemStateCubit),
          BlocProvider(create: (_) => AuthCubit()..checkAuthStatus()),
          BlocProvider(create: (_) => LoanCubit()),
          BlocProvider(create: (context) => PortfolioCubit(context.read<LoanRepository>())),
          BlocProvider(create: (context) => ChitFundCubit(context.read<ChitFundRepository>())),
          BlocProvider(create: (_) => NotificationCubit(ApiClient())..fetchNotifications()),
          BlocProvider<AdminCubit>(create: (_) => AdminCubit()),
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
              builder: (context, routerWidget) {
                return BlocBuilder<SystemStateCubit, SystemState>(
                  builder: (context, systemState) {
                    return Stack(
                      children: [
                        if (routerWidget != null) routerWidget,
                        if (systemState == SystemState.financialOperationsPaused)
                          Positioned(
                            top: 40.h,
                            left: 16.w,
                            right: 16.w,
                            child: Material(
                              color: Colors.transparent,
                              child: Container(
                                padding: EdgeInsets.all(16.w),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade900,
                                  borderRadius: BorderRadius.circular(12.r),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))
                                  ]
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24.sp),
                                        SizedBox(width: 12.w),
                                        Expanded(
                                          child: Text(
                                            '🔴 SERVICE PAUSED\nFinancial operations are temporarily unavailable. Your funds are safe.',
                                            style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 12.h),
                                    ElevatedButton(
                                      onPressed: () async {
                                        try {
                                          final response = await ApiClient().dio.get('https://khataa-backend.onrender.com/health/live');
                                          if (response.statusCode == 200) {
                                            if (context.mounted) {
                                              context.read<SystemStateCubit>().resumeOperations();
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Operations resumed successfully!'))
                                              );
                                            }
                                          }
                                        } catch (e) {}
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: Colors.red.shade900,
                                        minimumSize: Size(double.infinity, 36.h),
                                      ),
                                      child: const Text('Check Status / Retry'),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
      ),
    );
  }
}

class NotificationListenerWidget extends StatefulWidget {
  final Widget child;
  const NotificationListenerWidget({super.key, required this.child});

  @override
  State<NotificationListenerWidget> createState() =>
      _NotificationListenerWidgetState();
}

class _NotificationListenerWidgetState
    extends State<NotificationListenerWidget> {
  StreamSubscription? _sub;
  StreamSubscription? _openSub;

Future<void> _handleNotificationRouting(RemoteMessage message) async {
    final type = message.data['type'] as String?;
    final loanId = message.data['loanId'] as String?;
    final intentId = message.data['intentId'] as String?;
    final eventId = message.data['eventId'] as String?; // UI dedup if necessary

    if (type == 'PAYMENT_COMMITTED' || 
        type == 'CREDIT_ADDED' || 
        type == 'LOAN_ACCEPTED' || 
        type == 'LOAN_CLOSED' || 
        type == 'LOAN_FROZEN') {
      if (loanId != null) router.go('${AppConstants.loanDetails}/$loanId');
    } else if (type == 'LOAN_CREATED' || type == 'LOAN_OTP' || type == 'LOAN_INIT_OTP') {
      if (loanId != null) {
        // We can go to approval directly, or loan details. 
        // We'll map to approval to be explicit.
        router.go('${AppConstants.loanApproval}/$loanId');
      } else {
        router.go(AppConstants.notifications);
      }
    } else if (type == 'ADD_CREDIT_INTENT') {
      if (intentId != null) {
        router.go('/add-credit-approval/$intentId?loanId=${loanId ?? ''}');
      }
    } else if (type == 'CLOSE_INTENT') {
      if (intentId != null) {
        router.go('/close-loan-approval/$intentId?loanId=${loanId ?? ''}');
      }
    } else if (type == 'CHIT_AUCTION_START') {
      final ledgerId = message.data['ledgerId'] ?? '';
      router.push('/chit-live-auction?ledgerId=$ledgerId');
    } else {
      // Unknown type -> Generic Notifications Inbox
      router.go(AppConstants.notifications);
    }
  }

  @override
  void initState() {
    super.initState();
    _sub = NotificationService.onMessageStream.stream.listen((_) {
      if (!mounted) return;
      context.read<LoanCubit>().fetchLoans();
      context.read<ChitFundCubit>().loadInvitesAndOwned();
      context.read<NotificationCubit>().fetchNotifications();
    });

    _openSub = FirebaseMessaging.onMessageOpenedApp.listen((
      RemoteMessage message,
    ) {
      _handleNotificationRouting(message);
    });

FirebaseMessaging.instance.getInitialMessage().then((
      RemoteMessage? message,
    ) {
      if (message != null) {
        // 4F-4G: Execute immediately. Router will preserve intent if AuthCubit is still Initial.
        if (mounted) {
          _handleNotificationRouting(message);
        }
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




