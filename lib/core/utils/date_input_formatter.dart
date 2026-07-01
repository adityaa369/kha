import 'package:flutter/services.dart';

class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;
    
    // Allow deleting (backspace) without forcing formatting issues
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    // Only allow digits and slashes
    var newText = '';
    for (int i = 0; i < text.length; i++) {
      if (RegExp(r'[0-9/]').hasMatch(text[i])) {
        newText += text[i];
      }
    }
    text = newText;
    
    // Remove existing slashes to re-format
    text = text.replaceAll('/', '');

    if (text.length > 8) {
      text = text.substring(0, 8);
    }

    var out = '';
    for (var i = 0; i < text.length; i++) {
      out += text[i];
      if ((i == 1 || i == 3) && i != text.length - 1) {
        out += '/';
      }
    }

    // If the user typed 2 characters and hasn't typed the slash, append it.
    if (text.length == 2 && oldValue.text.length < newValue.text.length && !newValue.text.endsWith('/')) {
        out += '/';
    } else if (text.length == 4 && oldValue.text.length < newValue.text.length && !newValue.text.endsWith('/')) {
        out += '/';
    }

    return TextEditingValue(
      text: out,
      selection: TextSelection.collapsed(offset: out.length),
    );
  }
}
