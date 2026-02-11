import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/blocs/auth/auth_cubit.dart';
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
import '../features/auth/presentation/pages/auth_choice_page.dart';
import 'constants.dart';

final router = GoRouter(
  initialLocation: AppConstants.splash,
  redirect: (context, state) {
    final authState = context.read<AuthCubit>().state;
    final isLoggedIn = authState is Authenticated;

    final isAuthRoute = [
      AppConstants.login,
      AppConstants.otp,
      AppConstants.welcome,
      AppConstants.splash,
      '/auth-choice',
    ].contains(state.uri.path);

    final isOnboardingRoute = [
      AppConstants.personalDetails,
      AppConstants.panDetails,
      AppConstants.processing,
    ].contains(state.uri.path);

    // If on splash, let it handle its own navigation
    if (state.uri.path == AppConstants.splash) return null;

    // If not logged in and trying to access protected routes
    if (!isLoggedIn && !isAuthRoute && !isOnboardingRoute) {
      return AppConstants.login;
    }

    // If logged in and on basic auth routes (login/otp), go home
    // But allow them to stay on onboarding routes if they are in the middle of it
    if (isLoggedIn && (state.uri.path == AppConstants.login || state.uri.path == AppConstants.otp)) {
      return AppConstants.home;
    }

    return null;
  },
  routes: [
    GoRoute(path: AppConstants.splash, builder: (context, state) => const SplashPage()),
    GoRoute(path: AppConstants.welcome, builder: (context, state) => const WelcomePage()),
    GoRoute(path: AppConstants.login, builder: (context, state) => const LoginPage()),
    GoRoute(
      path: AppConstants.otp,
      builder: (context, state) {
        final phone = state.extra as String? ?? '';
        return OtpPage(phone: phone);
      },
    ),
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
    GoRoute(path: '/auth-choice', builder: (context, state) => const AuthChoicePage()),
  ],
);