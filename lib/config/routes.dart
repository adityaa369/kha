import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/otp_page.dart';
import '../features/auth/presentation/pages/pan_details_page.dart';
import '../features/auth/presentation/pages/personal_details_page.dart';
import '../features/auth/presentation/pages/welcome_page.dart';
import '../features/auth/presentation/pages/processing_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/insights/presentation/pages/insights_page.dart';
import '../features/loans/presentation/pages/loans_given_page.dart';
import '../features/loans/presentation/pages/my_loans_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/loans/presentation/pages/create_loan_page.dart';
import '../features/loans/presentation/pages/loan_confirmation_page.dart';
import '../features/splash/presentation/pages/splash_page.dart';
import 'constants.dart';

final router = GoRouter(
  initialLocation: AppConstants.splash,
  routes: [
    GoRoute(path: AppConstants.splash, builder: (context, state) => const SplashPage()),
    GoRoute(path: AppConstants.welcome, builder: (context, state) => const WelcomePage()),
    GoRoute(path: AppConstants.login, builder: (context, state) => const LoginPage()),
    GoRoute(path: AppConstants.otp, builder: (context, state) => const OtpPage()),
    GoRoute(path: AppConstants.personalDetails, builder: (context, state) => const PersonalDetailsPage()),
    GoRoute(path: AppConstants.panDetails, builder: (context, state) => const PanDetailsPage()),
    GoRoute(
      path: '/create-loan',
      builder: (context, state) {
        final loanType = state.uri.queryParameters['type'] ?? 'personal';
        return CreateLoanPage(loanType: loanType);
      },
    ),
    GoRoute(
      path: '/loan-confirmation',
      builder: (context, state) {
        final loanData = state.extra as Map<String, dynamic>;
        return LoanConfirmationPage(loanData: loanData);
      },
    ),
    GoRoute(path: AppConstants.processing, builder: (context, state) => const ProcessingPage()),
    GoRoute(path: AppConstants.home, builder: (context, state) => const HomePage()),
    GoRoute(path: AppConstants.myLoans, builder: (context, state) => const MyLoansPage()),
    GoRoute(path: AppConstants.loansGiven, builder: (context, state) => const LoansGivenPage()),
    GoRoute(path: AppConstants.insights, builder: (context, state) => const InsightsPage()),
    GoRoute(path: AppConstants.profile, builder: (context, state) => const ProfilePage()),
  ],
);