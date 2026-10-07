import sys

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    target = """                          : Image.network(
                              url,
                              fit: BoxFit.cover,
                              loadingBuilder: (ctx, child, p) => p == null
                                  ? child
                                  : const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.image,
                                color: theme.primary,
                                size: 22,
                              ),
                            ),"""
    replacement = """                          : Icon(
                              Icons.image,
                              color: theme.primary,
                              size: 22,
                            ),"""
    if target in content:
        content = content.replace(target, replacement)
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print("Fixed " + filepath)
    else:
        print("Target not found in " + filepath)

fix_file('lib/features/loans/presentation/pages/lender_loan_details_page.dart')
fix_file('lib/features/loans/presentation/pages/interest_loan_details_page.dart')
