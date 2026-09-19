with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('''    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }''', '''    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );''')

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)
