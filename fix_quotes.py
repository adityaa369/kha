with open('lib/data/models/loan_model.dart', 'r', encoding='utf-8') as f:
    c = f.read()
c = c.replace("NumberFormat(\\'#,##,##0\\', \\'en_IN\\')", "NumberFormat('#,##,##0', 'en_IN')")
c = c.replace("'\\u20B9 ${", '"\\u20B9 ${')
c = c.replace(")}';", ')}";')
with open('lib/data/models/loan_model.dart', 'w', encoding='utf-8') as f:
    f.write(c)
