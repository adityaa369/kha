with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

replacement = '''
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
'''

content = content.replace('''    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).then((_) async {''', replacement + '''    try {''')

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)
