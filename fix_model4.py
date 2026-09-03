with open('lib/data/models/loan_model.dart', 'r', encoding='utf-8') as f:
    c = f.read()

# Replace Mojibake in displayAmount
c = c.replace(",1 ${_formatNumber(amount)}", "\u20B9 ${_formatNumber(amount)}")
c = c.replace(",1", "\u20B9") # if any other weird char

old_format = """  static String _formatNumber(double number) {
    return number.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }"""

new_format = """  static String _formatNumber(double number) {
    return NumberFormat('#,##,##0', 'en_IN').format(number);
  }"""

c = c.replace(old_format, new_format)

if "import 'package:intl/intl.dart';" not in c:
    c = "import 'package:intl/intl.dart';\n" + c

with open('lib/data/models/loan_model.dart', 'w', encoding='utf-8') as f:
    f.write(c)
