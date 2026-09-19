with open('lib/firebase_options.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("'1:119567932403:android:0825bf2ed995c992a91086'", "'1:119567932403:android:2cd11541818d97b2a91086'")
# The api key in google-services.json is "AIzaSyBKxIa04MRXrOqvdW41djDwSSsxoDCTe8c", let's check firebase_options.dart

with open('lib/firebase_options.dart', 'w', encoding='utf-8') as f:
    f.write(content)
