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
  static const String processing = '/processing';
  static const String home = '/home';
  static const String myLoans = '/my-loans';
  static const String loansGiven = '/loans-given';
  static const String insights = '/insights';
  static const String profile = '/profile';

  // API Configurations
  static const String baseUrl = 'http://10.0.2.2:5000/api'; 
  
  // Table Names
  static const String usersTable = 'users';
  static const String loansTable = 'loans';
  static const String loansGivenTable = 'loans_given';
  static const String creditScoresTable = 'credit_scores';
  static const String loanAgreementsTable = 'loan_agreements';

  // Supabase Storage Buckets
  static const String profileImagesBucket = 'profile-images';
  static const String loanDocumentsBucket = 'loan-documents';
}