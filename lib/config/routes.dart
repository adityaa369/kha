import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/blocs/auth/auth_cubit.dart';
import '../features/splash/presentation/pages/splash_page.dart';
import '../features/auth/presentation/pages/auth_choice_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/signup_page.dart';
import '../features/auth/presentation/pages/otp_page.dart';
import '../features/auth/presentation/pages/personal_details_page.dart';
import '../features/auth/presentation/pages/pan_details_page.dart';
import '../features/auth/presentation/pages/processing_page.dart';
import '../features/auth/presentation/pages/reset_password_page.dart';
import '../features/auth/presentation/pages/registration_otp_page.dart';
import '../features/auth/presentation/pages/welcome_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/insights/presentation/pages/insights_page.dart';
import '../features/loans/presentation/pages/my_loans_page.dart';
import '../features/loans/presentation/pages/loans_given_page.dart';
import '../features/loans/presentation/pages/create_loan_page.dart';
import '../features/loans/presentation/pages/loan_confirmation_page.dart';
import '../features/loans/presentation/pages/loan_success_page.dart';
import '../features/loans/presentation/pages/loan_close_success_page.dart';
import '../features/loans/presentation/pages/loan_details_page.dart';

import '../features/chit_funds/presentation/pages/chit_invites_page.dart';
import '../features/chit_funds/presentation/pages/my_chits_page.dart';
import '../features/chit_funds/presentation/pages/create_chit_page.dart';
import '../features/chit_funds/presentation/pages/bid_authorization_page.dart';
import '../features/chit_funds/presentation/pages/chit_success_page.dart';
import '../features/chit_funds/presentation/pages/chit_group_admin_page.dart';
import '../features/home/presentation/pages/notifications_page.dart';
import '../features/loans/presentation/pages/loan_approval_page.dart';
import '../features/loans/presentation/pages/add_credit_approval_page.dart';
import '../features/loans/presentation/pages/close_loan_approval_page.dart';
import '../features/chit_funds/presentation/pages/chit_live_auction_page.dart';
import '../features/chit_funds/presentation/pages/chit_home_page.dart';
import '../features/chit_funds/presentation/pages/chit_member_detail_page.dart';
import '../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../features/profile/presentation/pages/security_hub_page.dart';
import '../core/blocs/security/security_cubit.dart';
import '../data/repositories/security_repository.dart';
import '../core/network/api_client.dart';


import 'constants.dart';

final router = GoRouter(
  initialLocation: AppConstants.splash,
  redirect: (context, state) {
    final authState = context.read<AuthCubit>().state;

    final isAuthRoute = [
      AppConstants.login,
      '/signup',
      AppConstants.otp,
      AppConstants.welcome,
      AppConstants.splash,
      '/auth-choice',
    ].contains(state.uri.path);

    // Bootstrapping Phase: Trap in Splash and preserve intent via query param
    if (authState is AuthInitial) {
      if (state.uri.path != AppConstants.splash) {
        return '${AppConstants.splash}?redirect_to=${Uri.encodeComponent(state.uri.toString())}';
      }
      return null;
    }

    if (authState is Unauthenticated) {
      if (!isAuthRoute && state.uri.path != '/reset-password') {
        // Here we could technically save redirect_to for post-login, but for now just protect routes.
        return AppConstants.login;
      }
      return null;
    }

    if (authState is PasswordResetRequired) {
      if (state.uri.path != '/reset-password') {
        return '/reset-password';
      }
      return null;
    }

    // KYC Progress
    if (authState is AuthenticatedEmailVerifiedKycIncomplete) {
      final user = authState.user;
      if (user.firstName.isEmpty) {
        if (state.uri.path != AppConstants.personalDetails) return AppConstants.personalDetails;
      } else {
        if (state.uri.path != AppConstants.panDetails) return AppConstants.panDetails;
      }
      return null;
    }

    // Full Authorized State
    if (authState is AuthenticatedKycComplete) {
      // If they were originally trying to go somewhere and hit splash, let them through
      if (state.uri.path == AppConstants.splash) {
        final redirect = state.uri.queryParameters['redirect_to'];
        if (redirect != null && redirect.isNotEmpty) return redirect;
      }
      // If they go to login/auth pages while fully authenticated, bounce to home
      if (isAuthRoute) return AppConstants.home;
      return null;
    }

    return null;
  },
  routes: [
    GoRoute(
      path: AppConstants.splash,
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: AppConstants.welcome,
      builder: (context, state) => const WelcomePage(),
    ),
    GoRoute(
      path: AppConstants.login,
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(path: '/signup', builder: (context, state) => const SignupPage()),
    GoRoute(
      path: AppConstants.otp,
      builder: (context, state) {
        final phone = state.extra as String? ?? '';
        return OtpPage(phone: phone);
      },
    ),
    GoRoute(
      path: AppConstants.personalDetails,
      builder: (context, state) => const PersonalDetailsPage(),
    ),
    GoRoute(
      path: AppConstants.panDetails,
      builder: (context, state) => const PanDetailsPage(),
    ),
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
    GoRoute(
      path: AppConstants.processing,
      builder: (context, state) => const ProcessingPage(),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) => const ResetPasswordPage(),
    ),
    GoRoute(
      path: AppConstants.home,
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: AppConstants.myLoans,
      builder: (context, state) => const MyLoansPage(),
    ),
    GoRoute(
      path: AppConstants.loansGiven,
      builder: (context, state) => const LoansGivenPage(),
    ),
    GoRoute(
      path: AppConstants.insights,
      builder: (context, state) => const InsightsPage(),
    ),
    GoRoute(
      path: AppConstants.profile,
      builder: (context, state) => const ProfilePage(),
    ),
    GoRoute(
      path: AppConstants.notifications,
      builder: (context, state) => const NotificationsPage(),
    ),
    GoRoute(
      path: '/close-loan-approval/:intentId',
      builder: (context, state) {
        final intentId = state.pathParameters['intentId'] ?? '';
        final loanId = state.uri.queryParameters['loanId'] ?? '';
        return CloseLoanApprovalPage(
          loanId: loanId,
          intentId: intentId,
        );
      },
    ),
    GoRoute(
      path: '/add-credit-approval/:intentId',
      builder: (context, state) {
        final intentId = state.pathParameters['intentId'] ?? '';
        final loanId = state.uri.queryParameters['loanId'] ?? '';
        final amountStr = state.uri.queryParameters['amount'] ?? '0';
        final amountRupees = double.tryParse(amountStr) ?? 0;
        return AddCreditApprovalPage(
          loanId: loanId,
          intentId: intentId,
          amountRupees: amountRupees,
        );
      },
    ),
    GoRoute(
      path: '${AppConstants.loanApproval}/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        // UI layer will fetch the actual loan using ID
        return LoanApprovalPage(loanId: id);
      },
    ),
    GoRoute(
      path: AppConstants.loanSuccess,
      builder: (context, state) => const LoanSuccessPage(),
    ),
    GoRoute(
      path: AppConstants.loanCloseSuccess,
      builder: (context, state) => const LoanCloseSuccessPage(),
    ),
    GoRoute(
      path: '${AppConstants.loanDetails}/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return LoanDetailsPage(loanId: id);
      },
    ),

    GoRoute(
      path: '/auth-choice',
      builder: (context, state) => const AuthChoicePage(),
    ),
    GoRoute(
      path: '/chit-live-auction',
      builder: (context, state) {
        final ledgerId = state.uri.queryParameters['ledgerId'] ?? 'demo_ledger_123';
        return ChitLiveAuctionPage(ledgerId: ledgerId);
      },
    ),
    GoRoute(
      path: '/chit-home',
      builder: (context, state) => const ChitHomePage(),
    ),
    GoRoute(
      path: AppConstants.chitInvites,
      builder: (context, state) => const ChitInvitesPage(),
    ),
    GoRoute(
      path: AppConstants.myChits,
      builder: (context, state) => const MyChitsPage(),
    ),
    GoRoute(
      path: AppConstants.createChit,
      builder: (context, state) => const CreateChitGroupPage(),
    ),
    GoRoute(
      path: AppConstants.bidAuth,
      builder: (context, state) => const BidAuthorizationPage(),
    ),
    GoRoute(
      path: AppConstants.chitSuccess,
      builder: (context, state) => const ChitSuccessPage(),
    ),
    GoRoute(
      path: AppConstants.chitAdminDashboard,
      builder: (context, state) {
        final chitId = state.extra as String;
        return ChitGroupAdminPage(chitId: chitId);
      },
    ),
    GoRoute(
      path: '/chit-member-detail',
      builder: (context, state) {
        final chitId = state.extra as String;
        return ChitMemberDetailPage(chitId: chitId);
      },
    ),
    GoRoute(
      path: '/profile/security',
      builder: (context, state) => BlocProvider(
        create: (ctx) => SecurityCubit(SecurityRepository(ApiClient())),
        child: const SecurityHubPage(),
      ),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboardPage(),
    ),
  ],
);
