import 'dart:io';

void main() {
  final file = File('lib/features/loans/presentation/pages/create_loan_page.dart');
  var content = file.readAsStringSync();
  content = content.replaceAll(RegExp(r"Text\('Principal:[^$]*"), "Text('Principal: \u20B9");
  content = content.replaceAll(RegExp(r"Text\('Total Interest:[^$]*"), "Text('Total Interest: \u20B9");
  content = content.replaceAll(RegExp(r"Text\('Total Repayment:[^$]*"), "Text('Total Repayment: \u20B9");
  file.writeAsStringSync(content);
}