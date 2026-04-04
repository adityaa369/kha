import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../../core/blocs/navigation/navigation_cubit.dart';
import '../../../../core/widgets/gauge_chart.dart';
import '../../../loans/presentation/pages/loans_given_page.dart';
import '../../../insights/presentation/pages/insights_page.dart';
import '../../../../core/blocs/auth/auth_cubit.dart';
import '../../../../core/blocs/loans/loan_cubit.dart';
import '../../../../core/blocs/credit_score/credit_score_cubit.dart';
import '../../../../core/blocs/loans/loan_state.dart';
import '../../../../core/blocs/credit_score/credit_score_state.dart';
import '../../../loans/presentation/pages/my_loans_page.dart';
import '../../../../core/services/notification_service.dart';
import 'dart:async';

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
      if (payload['type'] == 'LOAN_ACCEPTED' || payload['type'] == 'LOAN_CREATED') {
        if (mounted) context.read<LoanCubit>().fetchLoans();
      }
    });

    _authSub = context.read<AuthCubit>().stream.listen((authState) {
       if (authState is AuthenticatedFull) {
         if (mounted) {
            if (context.read<LoanCubit>().state is LoanInitial) {
               context.read<LoanCubit>().fetchLoans();
            }
            if (context.read<CreditScoreCubit>().state is CreditScoreInitial) {
               context.read<CreditScoreCubit>().fetchCreditScore();
            }
         }
       }
    });
    
    // Trigger immediately if already AuthenticatedFull
    if (context.read<AuthCubit>().state is AuthenticatedFull) {
         if (context.read<LoanCubit>().state is LoanInitial) {
            context.read<LoanCubit>().fetchLoans();
         }
         if (context.read<CreditScoreCubit>().state is CreditScoreInitial) {
            context.read<CreditScoreCubit>().fetchCreditScore();
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
              color: Colors.black.withOpacity(0.05),
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
                    index: 1),
                _NavItem(
                    icon: Icons.insights_rounded, label: 'Insights', index: 2),
                _NavItem(
                    icon: Icons.handshake_rounded,
                    label: 'Given',
                    index: 3),
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
        context.read<CreditScoreCubit>().resetError();
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
        context.read<CreditScoreCubit>().fetchCreditScore();
        context.read<LoanCubit>().fetchLoans();
        await Future.delayed(const Duration(milliseconds: 1000));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Blue Header with Score Cards
          Container(
            width: double.infinity,
            color: KhaataTheme.primaryBlue,
            padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 24.h),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => context.push('/profile'),
                        child: BlocBuilder<AuthCubit, AuthState>(
                          builder: (context, state) {
                            String name = '';
                            if (state is AuthenticatedFull) {
                              name = state.user.firstName;
                            } else {
                              return const SizedBox.shrink(); // Hide until loaded
                            }
                            return Text(
                              'Hello, $name!',
                              style: TextStyle(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                      ),
                      Row(
                        children: [
                          BlocBuilder<LoanCubit, LoanState>(
                            builder: (context, state) {
                              int pendingCount = 0;
                              if (state is LoansLoaded) {
                                pendingCount = state.myLoans
                                    .where((l) => l.status == 'pending_approval')
                                    .length;
                              }
                              return GestureDetector(
                                onTap: () {
                                  context.push('/notifications');
                                },
                                child: Stack(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(6.w),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.notifications_none,
                                        color: Colors.white,
                                        size: 22.sp,
                                      ),
                                    ),
                                    if (pendingCount > 0)
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: Container(
                                          padding: EdgeInsets.all(4.w),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            '$pendingCount',
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
                            onTap: () {
                              context.push('/profile');
                            },
                            child: Container(
                              padding: EdgeInsets.all(6.w),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person_outline,
                                color: Colors.white,
                                size: 22.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
            // Score Cards Row
            BlocBuilder<CreditScoreCubit, CreditScoreState>(
              builder: (context, state) {
                if (state is CreditScoreInitial) {
                  final authState = context.read<AuthCubit>().state;
                  if (authState is AuthenticatedFull) {
                    context.read<CreditScoreCubit>().fetchCreditScore();
                  }
                }
                
                int cibil = 0;
                int experian = 0;
                String status = 'Processing';
                
                if (state is CreditScoreLoaded) {
                  cibil = state.cibilScore;
                  experian = state.experianScore;
                  status = state.status;
                }

                return Center(
                  child: SizedBox(
                    width: double.infinity,
                    child: _ScoreCard(
                      title: 'Credit Score',
                      score: cibil,
                      status: status,
                      daysLeft: 30,
                    ),
                  ),
                );
              },
            ),
                ],
              ),
            ),
          ),

          // Loan Types Section - Vertical List
          SizedBox(height: 12.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Credit Types',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: KhaataTheme.textDark,
                  ),
                ),
                TextButton(
                  onPressed: () => context.read<NavigationCubit>().changeTab(3),
                  child: Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: KhaataTheme.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              children: [
                _LoanTypeCard(
                  title: 'Hand Credit',
                  subtitle: 'Get a hand credit with minimal terms applied',
                  icon: Icons.account_balance_wallet,
                  color: KhaataTheme.accentGreen,
                  onTap: () => context.push('/create-loan?type=hand_credit'),
                ),
                SizedBox(height: 12.h),
                _LoanTypeCard(
                  title: 'Business Credit',
                  subtitle: 'Grow business by taking credit',
                  icon: Icons.business_center,
                  color: KhaataTheme.primaryBlue,
                  onTap: () => context.push('/create-loan?type=business_credit'),
                ),
                SizedBox(height: 12.h),
                _LoanTypeCard(
                  title: 'Interest Credit',
                  subtitle: 'Borrow with clear interest terms',
                  icon: Icons.percent,
                  color: KhaataTheme.warningYellow,
                  onTap: () => context.push('/create-loan?type=interest_credit'),
                ),
                SizedBox(height: 12.h),
                _LoanTypeCard(
                  title: 'Chit Funds',
                  subtitle: 'Save & borrow with group',
                  icon: Icons.groups,
                  color: KhaataTheme.secondaryBlue,
                  onTap: () => context.push('/chit-invites'),
                  trailingAction: TextButton(
                    onPressed: () => context.push('/create-chit'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Create Group',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: KhaataTheme.primaryBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Actions Section
          SizedBox(height: 24.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Text(
              'Actions For You',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: KhaataTheme.textDark,
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.w, vertical: 4.h),
                leading: Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.speed,
                    color: KhaataTheme.accentGreen,
                    size: 20.sp,
                  ),
                ),
                title: Text(
                  'Get actionable steps to improve your score',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 14.sp,
                  color: Colors.grey,
                ),
                onTap: () {},
              ),
            ),
          ),
          SizedBox(height: 100.h), // Extra padding to ensure bottom items aren't cut off or obscured
        ],
      ),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final String title;
  final int score;
  final String status;
  final int daysLeft;

  const _ScoreCard({
    required this.title,
    required this.score,
    required this.status,
    required this.daysLeft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: KhaataTheme.primaryBlue,
                  fontWeight: FontWeight.w800,
                  fontSize: 14.sp,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(width: 4.w),
              Icon(
                Icons.info_outline,
                size: 14.sp,
                color: Colors.grey,
              ),
            ],
          ),
          SizedBox(height: 8.h),
          CreditScoreGauge(
            score: score,
            size: 110,
          ),
          SizedBox(height: 4.h),
          Text(
            status,
            style: TextStyle(
              color: KhaataTheme.accentGreen,
              fontWeight: FontWeight.w700,
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Next update in $daysLeft days',
            style: TextStyle(
              fontSize: 10.sp,
              color: KhaataTheme.textGrey,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Based on loans taken & timely monthly repayments.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.sp,
              color: KhaataTheme.textGrey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoanTypeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final Widget? trailingAction;

  const _LoanTypeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.trailingAction,
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
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
             Container(
               padding: EdgeInsets.all(12.w),
               decoration: BoxDecoration(
                 color: color.withOpacity(0.1),
                 shape: BoxShape.circle,
               ),
               child: Icon(icon, color: color, size: 24.sp),
             ),
             SizedBox(width: 16.w),
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(
                     title,
                     style: TextStyle(
                       fontSize: 15.sp,
                       fontWeight: FontWeight.w700,
                     ),
                   ),
                   SizedBox(height: 4.h),
                   Text(
                     subtitle,
                     style: TextStyle(
                       fontSize: 12.sp,
                       color: KhaataTheme.textGrey,
                     ),
                   ),
                 ],
               ),
             ),
             if (trailingAction != null) trailingAction!,
          ],
        ),
      ),
    );
  }
}
