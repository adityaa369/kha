import os

# 1. Fix BOM in loan_model.dart
file_path = 'lib/data/models/loan_model.dart'
with open(file_path, 'rb') as f:
    content = f.read()
if content.startswith(b'\xef\xbb\xbf'):
    content = content[3:]
    with open(file_path, 'wb') as f:
        f.write(content)

# 2. Fix nudge_widget.dart missing imports
nudge_path = 'nudge_widget.dart'
# Wait, is nudge_widget.dart in root or lib/? The error says: "nudge_widget.dart:26:89". It's in the root folder??
