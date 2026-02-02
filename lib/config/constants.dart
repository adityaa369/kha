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

  // Mock Data for UI
  static const Map<String, dynamic> mockCreditScore = {
    'cibil': 763,
    'experian': 764,
    'status': 'Good',
    'nextUpdateCibil': 16,
    'nextUpdateExperian': 32,
  };

  static const List<Map<String, dynamic>> mockLoans = [
    {
      'lender': 'SBI',
      'accountNumber': '1072',
      'amount': null,
      'type': 'Credit Card',
      'status': 'active',
    },
    {
      'lender': 'SBI',
      'accountNumber': '2353',
      'amount': 684000,
      'type': 'Personal Loan',
      'status': 'active',
    },
  ];
}