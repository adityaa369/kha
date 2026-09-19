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
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
      try {
        await FirebaseAppCheck.instance.activate(
          providerAndroid: kDebugMode
              ? const AndroidDebugProvider()
              : const AndroidPlayIntegrityProvider(),
          providerApple: kDebugMode
              ? const AppleDebugProvider()
              : const AppleDeviceCheckProvider(),
        );
      } catch (e) {}
      try {
        NotificationService.initialize();
      } catch (e) {}

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
                const Icon(
                  Icons.error_outline,
                  color: KhaataTheme.primaryBlue,
                  size: 60,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Something went wrong',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  details.exceptionAsString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
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
          BlocProvider(
            create: (context) => PortfolioCubit(context.read<LoanRepository>()),
          ),
          BlocProvider(
            create: (context) =>
                ChitFundCubit(context.read<ChitFundRepository>()),
          ),
          BlocProvider(
            create: (_) => NotificationCubit(ApiClient())..fetchNotifications(),
          ),
          BlocProvider<AdminCubit>(create: (_) => AdminCubit()),
        ],
        child: NotificationListenerWidget(
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (context, child) {
              return MaterialApp.router(
                scaffoldMessengerKey: scaffoldMessengerKey,
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
                          if (systemState ==
                              SystemState.financialOperationsPaused)
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
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.warning_amber_rounded,
                                            color: Colors.white,
                                            size: 24.sp,
                                          ),
                                          SizedBox(width: 12.w),
                                          Expanded(
                                            child: Text(
                                              '🔴 SERVICE PAUSED\nFinancial operations are temporarily unavailable. Your funds are safe.',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 13.sp,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 12.h),
                                      ElevatedButton(
                                        onPressed: () async {
                                          try {
                                            final response = await ApiClient()
                                                .dio
                                                .get(
                                                  'https:// khataabackend.onrender.com/health/live',
                                                );
                                            if (response.statusCode == 200) {
                                              if (context.mounted) {
                                                context
                                                    .read<SystemStateCubit>()
                                                    .resumeOperations();
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Operations resumed successfully!',
                                                    ),
                                                  ),
                                                );
                                              }
                                            }
                                          } catch (e) {}
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: Colors.red.shade900,
                                          minimumSize: Size(
                                            double.infinity,
                                            36.h,
                                          ),
                                        ),
                                        child: const Text(
                                          'Check Status / Retry',
                                        ),
                                      ),
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
  StreamSubscription? _foregroundSub;
  StreamSubscription? _tapSub;
  StreamSubscription? _tokenRefreshSub;

  /// Dedup guard: track the last navigated notification ID to prevent double-push
  String? _lastHandledMessageId;

  // ============================================================
  // DEEP LINK ROUTER — Phase 8
  // All routing is done by canonical eventType + referenceId.
  // Authorization is handled by the destination page itself (LoanDetailsPage
  // checks lender/borrower ownership). We NEVER bypass route guards.
  // ============================================================
  Future<void> _routeToNotification(RemoteMessage message) async {
    if (!mounted) return;

    // Dedup: same message received twice (e.g., cold-start + onMessageOpenedApp)
    final msgId = message.messageId;
    if (msgId != null && msgId == _lastHandledMessageId) return;
    _lastHandledMessageId = msgId;

    final data = message.data;
    final eventType = data['eventType'] as String?;
    // Backend now sends referenceId; fall back to legacy loanId for compatibility

    final referenceId = (data['referenceId'] ?? data['loanId']) as String?;
    final intentId = data['intentId'] as String?;

    // Ensure router is available (splash may still be showing during cold start)
    // The router redirect guard handles auth — we just push the destination.
    switch (eventType) {
      // --- Loan / Agreement events → Loan Details (auth check inside page) ---
      case 'LOAN_CREATED':
      case 'LOAN_RECEIVED':
      case 'LOAN_ACTIVATED':
      case 'AGREEMENT_ACCEPTED':
      case 'PAYMENT_RECEIVED':
      case 'PAYMENT_FAILED':
      case 'LOAN_COMPLETED':
      case 'LOAN_CLOSED':
        if (referenceId != null && referenceId.isNotEmpty) {
          router.go('${AppConstants.loanDetails}/$referenceId');
        } else {
          router.go(AppConstants.notifications);
        }
        break;

      // --- Agreement Ready → Loan Approval page ---
      case 'AGREEMENT_READY':
        if (referenceId != null && referenceId.isNotEmpty) {
          router.go('${AppConstants.loanApproval}/$referenceId');
        } else {
          router.go(AppConstants.notifications);
        }
        break;

      // --- Legacy type-based routing (backwards compat) ---
      // These fire from old-style data payloads that haven't yet migrated
      default:
        final legacyType = data['type'] as String?;
        final loanId = data['loanId'] as String?;
        if (legacyType == 'ADD_CREDIT_INTENT' && intentId != null) {
          router.go('/add-credit-approval/$intentId?loanId=${loanId ?? ''}');
        } else if (legacyType == 'CLOSE_INTENT' && intentId != null) {
          router.go('/close-loan-approval/$intentId?loanId=${loanId ?? ''}');
        } else if (legacyType == 'CHIT_AUCTION_START') {
          final ledgerId = data['ledgerId'] ?? '';
          router.push('/chit-live-auction?ledgerId=$ledgerId');
        } else if (loanId != null && loanId.isNotEmpty) {
          // Generic loan reference — open loan details (page handles auth)
          router.go('${AppConstants.loanDetails}/$loanId');
        } else {
          router.go(AppConstants.notifications);
        }
    }
  }

  void _refreshDataOnMessage() {
    if (!mounted) return;
    context.read<LoanCubit>().fetchLoans();
    context.read<ChitFundCubit>().loadInvitesAndOwned();
    context.read<NotificationCubit>().fetchNotifications();
  }

  Future<void> _registerFcmToken(String token) async {
    try {
      await ApiClient().put(
        '/users/fcm-token',
        data: {'fcmToken': token},
      );
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();

    // 1. FOREGROUND messages — refresh data and show heads-up (handled by NotificationService)
    _foregroundSub = NotificationService.onForegroundMessage.stream.listen((_) {
      _refreshDataOnMessage();
    });

    // 2. BACKGROUND → FOREGROUND tap (onMessageOpenedApp)
    //    and FOREGROUND tap via NotificationService.onNotificationTap
    _tapSub = NotificationService.onNotificationTap.stream.listen((message) {
      _routeToNotification(message);
    });

    // 3. COLD START — app was completely terminated, opened via notification
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null && mounted) {
        _routeToNotification(message);
      }
    });

    // 4. FCM token refresh — re-register on rotation
    _tokenRefreshSub = NotificationService.onTokenRefresh.listen((newToken) {
      _registerFcmToken(newToken);
    });
  }

  @override
  void dispose() {
    _foregroundSub?.cancel();
    _tapSub?.cancel();
    _tokenRefreshSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
