import glob
import re

def fix(path):
    with open(path, 'r', encoding='utf-8') as f:
        c = f.read()

    # The block looks like:
    #                 ],
    #               ),
    #             ),
    #           );
    
    # We want to replace `),\n          );` with `),\n            ),\n          );`
    c = re.sub(r'            \),\n          \);', '            ),\n            ),\n          );', c)
        
    with open(path, 'w', encoding='utf-8') as f:
        f.write(c)

for path in [
    'lib/features/loans/presentation/pages/hand_loan_details_page.dart',
    'lib/features/loans/presentation/pages/business_loan_details_page.dart',
    'lib/features/loans/presentation/pages/interest_loan_details_page.dart',
]:
    fix(path)
print("Fixed paren")
