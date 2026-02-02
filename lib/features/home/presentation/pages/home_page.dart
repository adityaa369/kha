import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../../core/blocs/navigation/navigation_cubit.dart';
import '../../../../core/widgets/gauge_chart.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../loans/presentation/pages/my_loans_page.dart';
import '../../../loans/presentation/pages/loans_given_page.dart';
import '../../../insights/presentation/pages/insights_page.dart';

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

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final currentIndex = context.watch<NavigationCubit>().state;

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
            child: Row(
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
    final isSelected = context.watch<NavigationCubit>().state == index;

    return GestureDetector(
      onTap: () => context.read<NavigationCubit>().changeTab(index),
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
    return SingleChildScrollView(
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
                      Text(
                        'Hello, Aditya!',
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ProfilePage()),
                          );
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
                  SizedBox(height: 20.h),
                  // Score Cards Row
                  Row(
                    children: [
                      Expanded(
                        child: _ScoreCard(
                          title: 'CIBIL',
                          score: 763,
                          status: 'Good',
                          daysLeft: 16,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _ScoreCard(
                          title: 'experian',
                          score: 764,
                          status: 'Good',
                          daysLeft: 32,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Did You Know Card
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F4FD),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.campaign,
                          color: KhaataTheme.primaryBlue,
                          size: 22.sp),
                      SizedBox(width: 8.w),
                      Text(
                        'Did You Know?',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15.sp,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Padding(
                    padding: EdgeInsets.only(left: 30.w),
                    child: Text(
                      'Your credit utilization is 76%',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: KhaataTheme.textGrey,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  SizedBox(
                    width: double.infinity,
                    height: 44.h,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KhaataTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text(
                        'Check For More Info',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Offers Section - FIXED LAYOUT
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Text(
              'Exciting offers for you!',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: KhaataTheme.textDark,
              ),
            ),
          ),
          // Loan Types Section - Horizontal Scroll Cards
          SizedBox(height: 24.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Create Loan Agreement',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: KhaataTheme.textDark,
                  ),
                ),
                TextButton(
                  onPressed: () {},
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
          SizedBox(height: 12.h),
          SizedBox(
            height: 180.h,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              children: [
                _LoanTypeCard(
                  title: 'Personal Loan',
                  subtitle: 'Get a personal loan\nin 2 mins ⚡',
                  amount: '₹ 7,00,000',
                  icon: Icons.account_balance_wallet,
                  color: KhaataTheme.accentGreen,
                  onTap: () => context.push('/create-loan?type=personal'),
                ),
                SizedBox(width: 12.w),
                _LoanTypeCard(
                  title: 'Business Loan',
                  subtitle: 'Grow your business\nquickly 🚀',
                  amount: '₹ 50,00,000',
                  icon: Icons.business_center,
                  color: KhaataTheme.primaryBlue,
                  onTap: () => context.push('/create-loan?type=business'),
                ),
                SizedBox(width: 12.w),
                _LoanTypeCard(
                  title: 'Home Loan',
                  subtitle: 'Buy your dream\nhome 🏠',
                  amount: '₹ 1,00,00,000',
                  icon: Icons.home,
                  color: KhaataTheme.warningYellow,
                  onTap: () => context.push('/create-loan?type=home'),
                ),
                SizedBox(width: 12.w),
                _LoanTypeCard(
                  title: 'Chit Fund',
                  subtitle: 'Save & borrow with\ngroup 🤝',
                  amount: '₹ 10,00,000',
                  icon: Icons.groups,
                  color: KhaataTheme.secondaryBlue,
                  onTap: () => context.push('/create-loan?type=chitfund'),
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
          SizedBox(height: 20.h),
        ],
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
    final isCibil = title.toLowerCase() == 'cibil';

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
                  color: isCibil ? KhaataTheme.secondaryBlue : KhaataTheme.primaryBlue,
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
        ],
      ),
    );
  }
}


class _LoanTypeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _LoanTypeCard({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200.w, // Fixed width for horizontal scroll
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    'Quick Process',
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(icon, color: color, size: 28.sp),
              ],
            ),
            SizedBox(height: 12.h),
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
                height: 1.3,
              ),
            ),
            const Spacer(),
            Text(
              'Up to $amount',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}