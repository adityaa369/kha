import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../core/blocs/auth/auth_cubit.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/otp_page.dart';
import '../features/auth/presentation/pages/pan_details_page.dart';
import '../features/auth/presentation/pages/personal_details_page.dart';
import '../features/auth/presentation/pages/registration_otp_page.dart';
import '../features/auth/presentation/pages/welcome_page.dart';
import '../features/auth/presentation/pages/processing_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/insights/presentation/pages/insights_page.dart';
import '../features/loans/presentation/pages/loans_given_page.dart';
import '../features/loans/presentation/pages/my_loans_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/loans/presentation/pages/create_loan_page.dart';
import '../features/loans/presentation/pages/loan_confirmation_page.dart';
import '../features/loans/presentation/pages/loan_success_page.dart';
import '../features/splash/presentation/pages/splash_page.dart';
import '../features/auth/presentation/pages/auth_choice_page.dart';
import '../features/chit_funds/presentation/pages/chit_invites_page.dart';
import '../features/chit_funds/presentation/pages/my_chits_page.dart';
import '../features/chit_funds/presentation/pages/create_chit_page.dart';
import '../features/chit_funds/presentation/pages/bid_authorization_page.dart';
import '../features/chit_funds/presentation/pages/chit_success_page.dart';
import '../features/chit_funds/presentation/pages/chit_group_admin_page.dart';
import '../features/home/presentation/pages/notifications_page.dart';
import '../features/loans/presentation/pages/loan_approval_page.dart';
import '../data/models/loan_model.dart';
import 'constants.dart';

final router = GoRouter(
  initialLocation: AppConstants.splash,
  redirect: (context, state) {
    final authState = context.read<AuthCubit>().state;
    
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
      AppConstants.registrationOtp,
      AppConstants.processing,
    ].contains(state.uri.path);

    if (state.uri.path == AppConstants.splash) return null;

    if (authState is Unauthenticated || authState is AuthInitial) {
      if (!isAuthRoute) return AppConstants.login;
      return null;
    }
    
    if (authState is OtpVerified || authState is RegistrationOtpVerified || authState is AuthenticatedUnverified) {
      if (state.uri.path != AppConstants.personalDetails) {
        return AppConstants.personalDetails;
      }
      return null;
    }
    
    if (authState is PersonalDetailsSaved) {
      if (state.uri.path != AppConstants.panDetails) {
        return AppConstants.panDetails;
      }
      return null;
    }

    if (authState is PanDetailsSaved) {
      if (state.uri.path != AppConstants.processing) {
        return AppConstants.processing;
      }
      return null;
    }
    
    if (authState is AuthenticatedFull) {
      if (isAuthRoute || isOnboardingRoute) return AppConstants.home;
      return null;
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
      path: AppConstants.registrationOtp,
      builder: (context, state) {
        final phone = state.extra as String? ?? '';
        return RegistrationOtpPage(phone: phone);
      },
    ),
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
    GoRoute(path: AppConstants.notifications, builder: (context, state) => const NotificationsPage()),
    GoRoute(
      path: AppConstants.loanApproval,
      builder: (context, state) {
        final loan = state.extra as LoanModel;
        return LoanApprovalPage(loan: loan);
      },
    ),
    GoRoute(path: AppConstants.loanSuccess, builder: (context, state) => const LoanSuccessPage()),
    GoRoute(path: '/auth-choice', builder: (context, state) => const AuthChoicePage()),
    GoRoute(path: AppConstants.chitInvites, builder: (context, state) => const ChitInvitesPage()),
    GoRoute(path: AppConstants.myChits, builder: (context, state) => const MyChitsPage()),
    GoRoute(path: AppConstants.createChit, builder: (context, state) => const CreateChitGroupPage()),
    GoRoute(path: AppConstants.bidAuth, builder: (context, state) => const BidAuthorizationPage()),
    GoRoute(path: AppConstants.chitSuccess, builder: (context, state) => const ChitSuccessPage()),
    GoRoute(
      path: AppConstants.chitAdminDashboard,
      builder: (context, state) {
        final chitId = state.extra as String;
        return ChitGroupAdminPage(chitId: chitId);
      },
    ),
  ],
);