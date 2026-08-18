import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  static const String appName = 'Khaata';
  static const String tagline = 'Digital Loan Agreements Made Simple';

  // Routes
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String personalDetails = '/personal-details';
  static const String panDetails = '/pan-details';
  static const String registrationOtp = '/registration-otp';
  static const String processing = '/processing';
  static const String home = '/home';
  static const String myLoans = '/my-loans';
  static const String loansGiven = '/loans-given';
  static const String insights = '/insights';
  static const String profile = '/profile';
  static const String notifications = '/notifications';
  static const String loanApproval = '/loan-approval';
  static const String chitInvites = '/chit-invites';
  static const String myChits = '/my-chits';
  static const String createChit = '/create-chit';
  static const String bidAuth = '/bid-authorization';
  static const String loanSuccess = '/loan-success';
  static const String loanCloseSuccess = '/loan-close-success';
  static const String loanDetails = '/loan-details';
  static const String lenderLoanDetails = '/lender-loan-details';
  static const String chitSuccess = '/chit-success';
  static const String chitAdminDashboard = '/chit-admin-dashboard';
  static const String chitMemberDetail = '/chit-member-detail';

  // API Configurations
  static const String _prodUrl = 'https://khataa-backend.onrender.com';

  static String get baseUrl {
    return dotenv.env['BASE_URL'] ?? '$_prodUrl/api';
  }
}
