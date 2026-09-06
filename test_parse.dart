import 'dart:convert'; void main() { final json = jsonDecode('{\"amountPaise\": 68000000}'); print(json['amountPaise'] is int); }
