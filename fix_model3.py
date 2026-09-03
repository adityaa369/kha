with open('lib/data/models/loan_model.dart', 'r', encoding='utf-8') as f:
    c = f.read()

c = c.replace("    }';\n    }", "    }")
c = c.replace("    }';", "    }")

with open('lib/data/models/loan_model.dart', 'w', encoding='utf-8') as f:
    f.write(c)
