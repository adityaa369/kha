class MoneyUtils {
  static int parseRupeesToPaise(String input) {
    if (input.isEmpty) {
      throw const FormatException('Amount cannot be empty');
    }
    
    final regex = RegExp(r'^\d+(\.\d{1,2})?$');
    if (!regex.hasMatch(input)) {
      throw const FormatException('Invalid amount format');
    }
    
    if (input.contains('.')) {
      final parts = input.split('.');
      final rupees = int.parse(parts[0]);
      var paiseStr = parts[1];
      if (paiseStr.length == 1) {
        paiseStr += '0';
      }
      final paise = int.parse(paiseStr);
      return (rupees * 100) + paise;
    } else {
      return int.parse(input) * 100;
    }
  }
}
