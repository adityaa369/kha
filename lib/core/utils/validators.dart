class Validators {
  // Phone: Indian format, starts with 6-9, exactly 10 digits
  static final RegExp phoneRegex = RegExp(r'^[6-9]\d{9}$');

  // Email: Standard format
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    caseSensitive: false,
  );

  // PAN: 5 letters + 4 digits + 1 letter
  static final RegExp panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$');

  // Aadhar: 12 digits, starts with 2-9
  static final RegExp aadharRegex = RegExp(r'^[2-9]{1}[0-9]{3}\s?[0-9]{4}\s?[0-9]{4}$');

  // Password: Min 8, 1 upper, 1 lower, 1 digit, 1 special
  static final RegExp passwordRegex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$'
  );

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Phone number required';
    if (!phoneRegex.hasMatch(value)) return 'Enter valid 10-digit mobile number';
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email required';
    if (!emailRegex.hasMatch(value)) return 'Enter valid email address';
    return null;
  }

  static String? validatePAN(String? value) {
    if (value == null || value.isEmpty) return 'PAN required';
    if (!panRegex.hasMatch(value.toUpperCase())) return 'Invalid PAN (ABCDE1234F)';
    return null;
  }

  static String? validateAadhar(String? value) {
    if (value == null || value.isEmpty) return 'Aadhar required';
    String clean = value.replaceAll(' ', '');
    if (clean.length != 12) return 'Aadhar must be 12 digits';
    if (!aadharRegex.hasMatch(value)) return 'Invalid Aadhar number';
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password required';
    if (value.length < 8) return 'Minimum 8 characters';
    if (!passwordRegex.hasMatch(value)) {
      return 'Need: A-Z, a-z, 0-9, Special char (@\$!%*?&)';
    }
    return null;
  }
}