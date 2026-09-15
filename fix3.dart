import 'dart:io';

void main() {
  final file = File('lib/features/loans/presentation/pages/create_loan_page.dart');
  var content = file.readAsStringSync();
  content = content.replaceFirst(
    "void _processLoanCreation() async {\n    setState(() => _isLoading = true);",
    "void _processLoanCreation() async {\n    if (_isLoading) return;\n    setState(() => _isLoading = true);"
  );
  content = content.replaceFirst(
    "void _processLoanCreation() async {\r\n    setState(() => _isLoading = true);",
    "void _processLoanCreation() async {\n    if (_isLoading) return;\n    setState(() => _isLoading = true);"
  );
  file.writeAsStringSync(content);
}