import 'dart:io';

void main() {
  final files = [
    'assets/images/new_splash.png',
    'assets/images/splash_logo.png',
    'assets/images/splash_title.png',
    'assets/images/splash_subtitle.png'
  ];
  for (final file in files) {
    final f = File(file);
    if (f.existsSync()) {
      print('$file - ${f.lengthSync()} bytes');
    }
  }
}
