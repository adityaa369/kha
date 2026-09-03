import glob

def fix(path):
    with open(path, 'r', encoding='utf-8') as f:
        c = f.read()

    # The block looks exactly like:
    #                 ],
    #               ),
    #             ),
    #           );
    #         },
    #       );
    #     }
    # We need to turn the `),` before `);` into `), ),`
    
    # Let's just find:
    #             ),
    #           );
    #         },
    
    old_end = "            ),\n          );\n        },\n      );\n    }"
    new_end = "            ),\n            ),\n          );\n        },\n      );\n    }"
    
    if old_end in c:
        c = c.replace(old_end, new_end)
    else:
        # Try a more forgiving replacement if whitespace differs
        c = c.replace("            ),\n          );", "            ),\n            ),\n          );")
        
    with open(path, 'w', encoding='utf-8') as f:
        f.write(c)

for path in [
    'lib/features/loans/presentation/pages/hand_loan_details_page.dart',
    'lib/features/loans/presentation/pages/business_loan_details_page.dart',
    'lib/features/loans/presentation/pages/interest_loan_details_page.dart',
]:
    fix(path)
print("Fixed paren")
