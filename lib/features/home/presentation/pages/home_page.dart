import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../../config/theme.dart';
import '../../../../core/blocs/navigation/navigation_cubit.dart';
import '../../../loans/presentation/pages/loans_given_page.dart';
import '../../../insights/presentation/pages/insights_page.dart';
import '../../../../core/blocs/auth/auth_cubit.dart';
import '../../../../core/blocs/loans/loan_cubit.dart';
import '../../../../core/blocs/loans/loan_state.dart';
import '../cubit/notification_cubit.dart';
import '../cubit/notification_state.dart';
import '../../../loans/presentation/pages/my_loans_page.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/widgets/looping_avatar.dart';
import 'dart:async';
import '../../../../data/models/loan_model.dart';
import '../../../../config/constants.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NavigationCubit(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  StreamSubscription? _msgSub;
  StreamSubscription? _authSub;

  @override
  void initState() {
    super.initState();
    _msgSub = NotificationService.onMessageStream.stream.listen((payload) {
      if (payload['type'] == 'LOAN_ACCEPTED' ||
          payload['type'] == 'LOAN_CREATED') {
        if (mounted) context.read<LoanCubit>().fetchLoans();
      }
    });

    _authSub = context.read<AuthCubit>().stream.listen((authState) {
      if (authState is AuthenticatedFull) {
        if (mounted) {
          if (context.read<LoanCubit>().state is LoanInitial) {
            context.read<LoanCubit>().fetchLoans();
          }
        }
      }
    });

    // Trigger immediately if already AuthenticatedFull
    if (context.read<AuthCubit>().state is AuthenticatedFull) {
      if (context.read<LoanCubit>().state is LoanInitial) {
        context.read<LoanCubit>().fetchLoans();
      }
    }
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = context.select<NavigationCubit, int>(
      (cubit) => cubit.state,
    );

    return Scaffold(
      backgroundColor: KhaataTheme.backgroundGrey,
      body: IndexedStack(
        index: currentIndex,
        children: const [
          HomeContent(),
          MyLoansPage(),
          InsightsPage(),
          LoansGivenPage(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.home_rounded, label: 'Home', index: 0),
                _NavItem(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'My Loans',
                  index: 1,
                ),
                _NavItem(
                  icon: Icons.insights_rounded,
                  label: 'Insights',
                  index: 2,
                ),
                _NavItem(
                  icon: Icons.handshake_rounded,
                  label: 'Given',
                  index: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = context.select<NavigationCubit, bool>(
      (cubit) => cubit.state == index,
    );

    return GestureDetector(
      onTap: () {
        context.read<LoanCubit>().resetError();
        context.read<NavigationCubit>().changeTab(index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? KhaataTheme.primaryBlue : Colors.grey,
            size: 22.sp,
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: isSelected ? KhaataTheme.primaryBlue : Colors.grey,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: KhaataTheme.primaryBlue,
      onRefresh: () async {
        context.read<AuthCubit>().checkAuthStatus();
        context.read<LoanCubit>().fetchLoans();
        await Future.delayed(const Duration(milliseconds: 1000));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: TweenAnimationBuilder(
          duration: const Duration(milliseconds: 600),
          tween: Tween<double>(begin: 0, end: 1),
          builder: (context, double value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top + 16.h),
              const _TopBar(),
              SizedBox(height: 24.h),
              const _GreetingSection(),
              SizedBox(height: 24.h),
              const _HeroBanner(),
              SizedBox(height: 24.h),
              const _PaymentsSection(),
              SizedBox(height: 24.h),
              const _ExploreMoreSection(),
              SizedBox(height: 100.h),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatefulWidget {
  const _TopBar();

  @override
  State<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<_TopBar> {
  String locationText = 'Locating...';

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    debugPrint('KHAATA_DEBUG: _fetchLocation starting...');
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('KHAATA_DEBUG: location services enabled = $serviceEnabled');
      if (!serviceEnabled) {
        Position? lastPos = await Geolocator.getLastKnownPosition();
        debugPrint('KHAATA_DEBUG: last known position = $lastPos');
        if (lastPos != null) {
          await _decodeAndSetLocation(lastPos);
          return;
        }
        if (mounted) setState(() => locationText = 'Enable Location');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('KHAATA_DEBUG: checked location permission = $permission');
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        debugPrint('KHAATA_DEBUG: requested location permission = $permission');
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() => locationText = 'Location Denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => locationText = 'Location Denied');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );
      debugPrint(
        'KHAATA_DEBUG: current position = ${position.latitude}, ${position.longitude}',
      );

      await _decodeAndSetLocation(position);
    } catch (e) {
      debugPrint('KHAATA_DEBUG: error in _fetchLocation = $e');
      try {
        Position? lastPos = await Geolocator.getLastKnownPosition();
        if (lastPos != null) {
          await _decodeAndSetLocation(lastPos);
          return;
        }
      } catch (_) {}
      if (mounted) {
        setState(() => locationText = 'Location Unavailable');
      }
    }
  }

  Future<void> _decodeAndSetLocation(Position position) async {
    try {
      debugPrint(
        'KHAATA_DEBUG: placemark decoding for ${position.latitude}, ${position.longitude}...',
      );
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      debugPrint('KHAATA_DEBUG: placemarks found = ${placemarks.length}');
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        debugPrint(
          'KHAATA_DEBUG: placemark[0] details: locality=${place.locality}, subLocality=${place.subLocality}, subAdmin=${place.subAdministrativeArea}, name=${place.name}, adminArea=${place.administrativeArea}',
        );

        // Select the most precise city/town/village name
        String city = 'Unknown';
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          if (place.locality != null &&
              place.locality!.isNotEmpty &&
              place.locality != place.subLocality) {
            city = '${place.subLocality!}, ${place.locality!}';
          } else {
            city = place.subLocality!;
          }
        } else if (place.locality != null && place.locality!.isNotEmpty) {
          city = place.locality!;
        } else if (place.subAdministrativeArea != null &&
            place.subAdministrativeArea!.isNotEmpty) {
          city = place.subAdministrativeArea!;
        } else if (place.name != null && place.name!.isNotEmpty) {
          city = place.name!;
        }

        String state = place.administrativeArea != null
            ? _getStateAbbreviation(place.administrativeArea!)
            : '';
        String finalLoc = '$city${state.isNotEmpty ? ', $state' : ''}';
        debugPrint('KHAATA_DEBUG: setting locationText to: $finalLoc');
        if (mounted) {
          setState(() {
            locationText = finalLoc;
          });
        }
      }
    } catch (e) {
      debugPrint('KHAATA_DEBUG: error in _decodeAndSetLocation = $e');
    }
  }

  String _getStateAbbreviation(String state) {
    final states = {
      'Andhra Pradesh': 'AP',
      'Karnataka': 'KA',
      'Maharashtra': 'MH',
      'Delhi': 'DL',
      'Tamil Nadu': 'TN',
      'Telangana': 'TG',
      'Gujarat': 'GJ',
      'Uttar Pradesh': 'UP',
      'Rajasthan': 'RJ',
      'Punjab': 'PB',
      'Haryana': 'HR',
      'West Bengal': 'WB',
      'Madhya Pradesh': 'MP',
      'Bihar': 'BR',
      'Kerala': 'KL',
      'Odisha': 'OD',
    };
    return states[state] ??
        (state.length >= 2 ? state.substring(0, 2).toUpperCase() : state);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () async {
                if (locationText == 'Enable Location') {
                  await Geolocator.openLocationSettings();
                } else if (locationText == 'Location Denied') {
                  await Geolocator.openAppSettings();
                } else {
                  setState(() => locationText = 'Locating...');
                  await _fetchLocation();
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: Colors.green.shade600,
                      size: 16.sp,
                    ),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        locationText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.black54,
                      size: 16.sp,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Row(
            children: [
              BlocBuilder<NotificationCubit, NotificationState>(
                builder: (context, state) {
                  int unreadCount = 0;
                  if (state is NotificationLoaded) {
                    unreadCount = state.notifications
                        .where((n) => !n.isRead)
                        .length;
                  }

                  return GestureDetector(
                    onTap: () {
                      context.push('/notifications');
                      context.read<NotificationCubit>().fetchNotifications();
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Icon(
                            Icons.notifications_none,
                            color: Colors.black87,
                            size: 20.sp,
                          ),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: EdgeInsets.all(4.w),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$unreadCount',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(width: 12.w),
              GestureDetector(
                onTap: () => context.push('/profile'),
                child: BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    String? gender;
                    if (state is AuthenticatedFull) {
                      gender = state.user.gender;
                    }
                    return Container(
                      width: 38.w,
                      height: 38.w,
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: LoopingAvatar(gender: gender, height: 38.w),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GreetingSection extends StatelessWidget {
  const _GreetingSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              String name = 'User';
              if (state is AuthenticatedFull) {
                name = state.user.firstName;
              }
              return Row(
                children: [
                  Text(
                    'Hello, ',
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.green.shade700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    '!',
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      // We use a Stack to allow the 3D character to break out of the top of the card
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background Card
          Container(
            padding: EdgeInsets.only(
              left: 20.w,
              top: 24.h,
              right: 20.w,
              bottom: 20.h,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF2FAF4), Color(0xFFE2F4E6)],
              ),
              borderRadius: BorderRadius.circular(32.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text Content
                SizedBox(
                  width:
                      MediaQuery.of(context).size.width *
                      0.50, // Reduced from 0.55 to prevent overlap
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 16.sp, // Reduced font size further
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                            height: 1.2,
                            letterSpacing: -0.5,
                            fontFamily: 'Inter',
                          ),
                          children: const [
                            TextSpan(
                              text: 'Take control of your\n',
                            ), // Aligned to two lines
                            TextSpan(
                              text: 'finances ',
                              style: TextStyle(color: Color(0xFF16A34A)),
                            ),
                            TextSpan(text: 'today!'),
                          ],
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'Track, manage & grow\nyour money with\nconfidence.',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.black87.withValues(alpha: 0.65),
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      // CTA Button
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 10.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A),
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF16A34A,
                              ).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Get Started',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12.sp,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 16.sp,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),
                // Icons Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _HeroIcon(
                      icon: Icons.pie_chart,
                      color: Colors.green.shade600,
                      label: 'Track\nBetter',
                    ),
                    _HeroIcon(
                      icon: Icons.shield,
                      color: Colors.amber.shade500,
                      label: 'Spend\nSmarter',
                    ),
                    _HeroIcon(
                      icon: Icons.track_changes,
                      color: Colors.blue.shade500,
                      label: 'Achieve\nGoals',
                    ),
                    _HeroIcon(
                      icon: Icons.show_chart,
                      color: Colors.purple.shade400,
                      label: 'Grow\nSteadily',
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 3D Character overlay
          Positioned(
            right: -10.w, // Shift right
            top: -10.h, // Align more naturally
            child: IgnorePointer(
              child: SizedBox(
                height: 180
                    .h, // Drastically reduced from 250.h to stop physical overlap
                child: Image.asset(
                  'assets/images/hero_3d_man.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _HeroIcon({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              14.r,
            ), // Rounded square (squircle)
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 24.sp),
        ),
        SizedBox(height: 8.h),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class _PaymentsSection extends StatelessWidget {
  const _PaymentsSection();

  static String _formatCurrency(double amount) {
    if (amount.isNaN || amount.isInfinite) return '0';
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoanCubit, LoanState>(
      builder: (context, state) {
        if (state is! LoansLoaded) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final loans = state.myLoans;
        final now = DateTime.now();

        // 1. Gather all active taken loans with their upcoming/due details
        List<Map<String, dynamic>> dueList = [];

        for (final loan in loans) {
          if (loan.loanStatus.isFinished ||
              loan.loanStatus.isPending) {
            continue;
          }

          final type = loan.type.toLowerCase().replaceAll('_', '');
          // Usually business credit / chitfund are handled differently or don't have standard EMIs
          if (type == 'businesscredit' ||
              type == 'business' ||
              type == 'chitfund') {
            continue;
          }

          final duration =
              (loan.durationMonths == null || loan.durationMonths == 0)
              ? 6
              : loan.durationMonths!;
          final progressVal = loan.progress.clamp(0.0, 1.0);
          final completedMonths = (duration * progressVal).round();

          final nextDueDate = (loan.startDate ?? DateTime.now()).add(
            Duration(days: (completedMonths + 1) * 30),
          );

          double installment = 0;
          if (type == 'interestcredit' || type == 'home') {
            installment = loan.amount * (loan.interestRate ?? 0) / 100;
          } else {
            installment = loan.amount / duration;
          }

          final daysDifference = nextDueDate.difference(now).inDays;

          dueList.add({
            'loan': loan,
            'dueDate': nextDueDate,
            'amount': installment,
            'daysDifference': daysDifference,
          });
        }

        // 2. Sort by most urgent first
        dueList.sort(
          (a, b) =>
              (a['dueDate'] as DateTime).compareTo(b['dueDate'] as DateTime),
        );

        if (dueList.isEmpty) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
            child: Center(
              child: Text(
                'No upcoming payments',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13.sp),
              ),
            ),
          );
        }

        // 3. Render the list of cards
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          child: Column(
            children: dueList.map((item) {
              final loan = item['loan'] as LoanModel;
              final amount = item['amount'] as double;
              final daysDiff = item['daysDifference'] as int;

              String subtitle;
              Color iconBg;
              IconData icon;
              bool isOverdue = false;

              if (daysDiff < 0) {
                final daysPast = daysDiff.abs();
                subtitle = "Overdue by $daysPast Day${daysPast > 1 ? 's' : ''}";
                iconBg = Colors.red.shade600;
                icon = Icons.warning_amber_rounded;
                isOverdue = true;
              } else if (daysDiff == 0) {
                subtitle = "Due Today";
                iconBg = Colors.orange.shade600;
                icon = Icons.today;
              } else {
                subtitle = "Due in $daysDiff Day${daysDiff > 1 ? 's' : ''}";
                iconBg = Colors.blue.shade600;
                icon = Icons.calendar_month;
              }

              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: _PaymentCard(
                  icon: icon,
                  iconBg: iconBg,
                  title: 'Pay to ${loan.lenderName}',
                  amount: '₹${_formatCurrency(amount)}',
                  subtitle: subtitle,
                  showProgress: isOverdue,
                  progressValue: loan.progress.clamp(0.0, 1.0),
                  onTap: () {
                    context.push(AppConstants.loanDetails, extra: loan);
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String amount;
  final String subtitle;
  final bool showProgress;
  final double progressValue;
  final VoidCallback? onTap;

  const _PaymentCard({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.amount,
    required this.subtitle,
    this.showProgress = false,
    this.progressValue = 0.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: iconBg.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconBg, size: 24.sp),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (showProgress) ...[
                    SizedBox(height: 8.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4.r),
                      child: LinearProgressIndicator(
                        value: progressValue,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.blue.shade600,
                        ),
                        minHeight: 4.h,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  amount,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 4.h),
                Icon(Icons.chevron_right, color: Colors.black45, size: 20.sp),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExploreMoreSection extends StatelessWidget {
  const _ExploreMoreSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Explore More',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16.h),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12.h,
            crossAxisSpacing: 12.w,
            childAspectRatio: 0.88,
            children: [
              _ExploreCard(
                title: 'Hand Credit',
                subtitle: 'Quick cash with minimal terms',
                icon: Icons.volunteer_activism,
                iconColor: const Color(0xFF1B5E20), // Dark Green
                bgColor: const Color(0xFFE8F5E9),
                badges: const ['Fast Approval'],
                onTap: () => context.push('/create-loan?type=hand_credit'),
              ),
              _ExploreCard(
                title: 'Business Credit',
                subtitle: 'Grow your business with flexible credit',
                icon: Icons.business_center,
                iconColor: const Color(0xFF4A148C), // Dark Violet
                bgColor: const Color(0xFFF3E5F5),
                badges: const ['High Limit'],
                onTap: () => context.push('/create-loan?type=business_credit'),
              ),
              _ExploreCard(
                title: 'Interest Credit',
                subtitle: 'Borrow with clear and simple terms',
                icon: Icons.percent,
                iconColor: const Color(0xFFE65100), // Dark Orange
                bgColor: const Color(0xFFFFF3E0),
                badges: const ['Low Interest'],
                onTap: () => context.push('/create-loan?type=interest_credit'),
              ),
              _ExploreCard(
                title: 'Chit Funds',
                subtitle: 'Save & borrow together with your group',
                icon: Icons.groups,
                iconColor: const Color(0xFF880E4F), // Dark Pinkish
                bgColor: const Color(0xFFFCE4EC),
                badges: const ['Trusted Groups'],
                onTap: () => context.push('/chit-home'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExploreCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final List<String> badges;
  final VoidCallback onTap;

  const _ExploreCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.badges,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 24.sp),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.black87.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 4.w,
                    runSpacing: 4.h,
                    children: badges
                        .map(
                          (badge) => Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 3.h,
                            ),
                            decoration: BoxDecoration(
                              color: iconColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                fontSize: 8.sp,
                                color: iconColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: iconColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 14.sp,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

