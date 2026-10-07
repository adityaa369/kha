import sys
filepath = 'lib/features/insights/presentation/pages/insights_page.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

target = """                          AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOut,
                            height: barH,
                            decoration: BoxDecoration("""

replacement = """                          AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOut,
                            height: barH,
                            width: double.infinity,
                            decoration: BoxDecoration("""

content = content.replace(target, replacement)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print('Fixed graph')
