import 'dart:io';

void main() {
  final file = File('lib/features/loans/presentation/pages/create_loan_page.dart');
  var content = file.readAsStringSync();
  content = content.replaceAll(RegExp(r"Principal: [^\$]*"), "Principal: \u20B9");
  content = content.replaceAll(RegExp(r"Total Interest: [^\$]*"), "Total Interest: \u20B9");
  content = content.replaceAll(RegExp(r"Total Repayment: [^\$]*"), "Total Repayment: \u20B9");
  file.writeAsStringSync(content);
}