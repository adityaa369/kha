import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'core/blocs/auth/auth_cubit.dart';
import 'core/blocs/loans/loan_cubit.dart';
import 'core/blocs/loans/loan_state.dart';
import 'core/blocs/loans/portfolio_cubit.dart';
import 'data/repositories/loan_repository.dart';
import 'core/blocs/chit_funds/chit_fund_cubit.dart';
import 'data/repositories/chit_fund_repository.dart';
import 'features/home/presentation/cubit/notification_cubit.dart';
import 'core/network/api_client.dart';
import 'core/utils/secure_storage.dart';
import 'core/utils/notification_router.dart';
import 'core/blocs/admin/admin_cubit.dart';
import 'core/blocs/system/system_state_cubit.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:async';


import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'core/blocs/system/app_bootstrap_cubit.dart';

final systemStateCubit = SystemStateCubit();
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

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

  runApp(
    BlocProvider(
      create: (_) => AppBootstrapCubit()..initializeApp(),
      child: const KhaataAppBootstrap(),
    ),
  );
}

class KhaataAppBootstrap extends StatefulWidget {
  const KhaataAppBootstrap({super.key});

  @override
  State<KhaataAppBootstrap> createState() => _KhaataAppBootstrapState();
}

class _KhaataAppBootstrapState extends State<KhaataAppBootstrap> {
  bool _configured = false;

  void _configureAsyncDependencies() {
    if (_configured) return;
    _configured = true;

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

    SentryFlutter.init((options) {
      options.dsn = dotenv.env['SENTRY_DSN'] ?? '';
      options.tracesSampleRate = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppBootstrapCubit, AppBootstrapState>(
      listener: (context, state) {
        if (state is AppBootstrapSuccess) {
          _configureAsyncDependencies();
          FlutterNativeSplash.remove();
        } else if (state is AppBootstrapError) {
          FlutterNativeSplash.remove();
        }
      },
      builder: (context, state) {
        if (state is AppBootstrapSuccess) {
          return const KhaataApp();
        } else if (state is AppBootstrapError) {
          return MaterialApp(
            home: Scaffold(
              backgroundColor: Colors.white,
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'CRITICAL APP LAUNCH FAILURE:\n\n${state.error}',
                    style: const TextStyle(color: Colors.black87, fontSize: 14),
                  ),
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
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
                title: 'App',
                theme: KhaataTheme.lightTheme,
                routerConfig: router,
                builder: (context, routerWidget) {
                  final mediaQuery = MediaQuery.of(context);
                  // Clamp text scaling to ensure UI consistency across different devices
                  // while still respecting moderate accessibility settings.
                  final clampedTextScaler = mediaQuery.textScaler.clamp(
                    minScaleFactor: 1.0,
                    maxScaleFactor: 1.2,
                  );

                  return MediaQuery(
                    data: mediaQuery.copyWith(textScaler: clampedTextScaler),
                    child: BlocBuilder<SystemStateCubit, SystemState>(
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
                                                  'https://khataa-backend.onrender.com/health/live',
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
                  ),
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
    extends State<NotificationListenerWidget> with WidgetsBindingObserver {
  StreamSubscription? _foregroundSub;
  StreamSubscription? _tapSub;
  StreamSubscription? _tokenRefreshSub;
  StreamSubscription? _loanStateSub;
  Timer? _autoRefreshTimer;
  Timer? _portfolioDebounce;

  /// Dedup guard: track the last navigated notification ID to prevent double-push
  String? _lastHandledMessageId;

  /// True only when a user is logged in and credits have been loaded once.
  bool get _canAutoRefresh {
    if (!mounted) return false;
    try {
      return context.read<AuthCubit>().state is Authenticated &&
          context.read<LoanCubit>().state is LoansLoaded;
    } catch (_) {
      return false;
    }
  }

  /// Quietly re-sync credits (and Insights via the loan listener).
  void _silentRefresh() {
    if (!_canAutoRefresh) return;
    context.read<LoanCubit>().fetchLoans();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _silentRefresh(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _silentRefresh();
      _startAutoRefresh();
    } else if (state == AppLifecycleState.paused) {
      _autoRefreshTimer?.cancel();
    }
  }

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

    // Get exact route via pure function
    final route = NotificationRouter.getRouteFromPayload(message.data);
    
    // We use go() for everything except deep chit links to ensure flat nav stack,
    // but the extracted class could be updated to return an intent type if needed.
    if (route.startsWith('/chit-live-auction')) {
      router.push(route);
    } else {
      router.go(route);
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

    // 5. REAL-TIME SYNC — refresh on app resume + every 30s while in foreground
    WidgetsBinding.instance.addObserver(this);
    _startAutoRefresh();

    // 6. Keep Insights in sync whenever credits reload (payments, month marks)
    _loanStateSub = context.read<LoanCubit>().stream.listen((loanState) {
      if (loanState is! LoansLoaded) return;
      _portfolioDebounce?.cancel();
      _portfolioDebounce = Timer(const Duration(milliseconds: 800), () {
        if (mounted) context.read<PortfolioCubit>().refreshSilently();
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoRefreshTimer?.cancel();
    _portfolioDebounce?.cancel();
    _loanStateSub?.cancel();
    _foregroundSub?.cancel();
    _tapSub?.cancel();
    _tokenRefreshSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}


