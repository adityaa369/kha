with open('lib/firebase_options.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("apiKey: 'AIzaSyDWwG-t0JdGQ98rmkIsWQSZsCRRJhzMoAw',", "apiKey: 'AIzaSyBKxIa04MRXrOqvdW41djDwSSsxoDCTe8c',")

with open('lib/firebase_options.dart', 'w', encoding='utf-8') as f:
    f.write(content)
