import glob

def fix(path):
    with open(path, 'r', encoding='utf-8') as f:
        c = f.read()

    # Fix dates in summary/stats cards
    date_logic_old = """final start = loan.startDate != null ? _dateStr(loan.startDate!) : '-';
    final end = loan.endDate != null ? _dateStr(loan.endDate!) : '-';"""
    date_logic_new = """final actualStart = loan.startDate ?? loan.activatedAt ?? loan.createdAt ?? DateTime.now();
    final start = _dateStr(actualStart);
    final end = loan.endDate != null ? _dateStr(loan.endDate!) : _dateStr(actualStart.add(Duration(days: (loan.durationMonths ?? duration) * 30)));"""
    
    date_logic_old2 = """final startStr = loan.startDate != null ? _dateStr(loan.startDate!) : '-';
    final endStr = loan.endDate != null ? _dateStr(loan.endDate!) : '-';"""
    date_logic_new2 = """final actualStart = loan.startDate ?? loan.activatedAt ?? loan.createdAt ?? DateTime.now();
    final startStr = _dateStr(actualStart);
    final endStr = loan.endDate != null ? _dateStr(loan.endDate!) : _dateStr(actualStart.add(Duration(days: (loan.durationMonths ?? duration) * 30)));"""

    c = c.replace(date_logic_old, date_logic_new)
    c = c.replace(date_logic_old2, date_logic_new2)

    # Fix Mojibake strings
    replacements = {
        "dY'3": "\U0001F4B0", # ??
        "marked as paid \ufffdo\"": "marked as paid \u2705", # ?
        "\u00e2\u20ac\u201d": "\u2014",
    }
    
    for bad, good in replacements.items():
        c = c.replace(bad, good)
        
    with open(path, 'w', encoding='utf-8') as f:
        f.write(c)

for path in glob.glob('lib/features/loans/presentation/**/*.dart', recursive=True):
    fix(path)
    
print("Fixed details")
