import 'dart:io';

void main() {
  final file = File('lib/features/loans/presentation/pages/loan_approval_page.dart');
  var content = file.readAsStringSync();
  content = content.replaceFirst(
    '''
  void _approveLoan() async {
    if (_loan == null || _verificationId == null || _currentOtp.length != 6) return;

    final authenticated = await BiometricAuthService.authenticate();
    if (!authenticated) {
      if (mounted) {
''',
    '''
  void _approveLoan() async {
    if (_loan == null || _verificationId == null || _currentOtp.length != 6) return;
    if (_isApproving) return;
    
    setState(() => _isApproving = true);
    
    final authenticated = await BiometricAuthService.authenticate();
    if (!authenticated) {
      if (mounted) {
        setState(() => _isApproving = false);
'''
  );
  file.writeAsStringSync(content);
}