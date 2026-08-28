import os

file_path = 'lib/main.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

replacement = """              builder: (context, systemState) {
                return Directionality(
                  textDirection: TextDirection.ltr,
                  child: Stack(
                    children: [
                      if (child != null) child,
                      if (systemState == SystemState.financialOperationsPaused)
                        Positioned(
"""

content = content.replace("""              builder: (context, systemState) {
                return Stack(
                  children: [
                    if (child != null) child,
                    if (systemState == SystemState.financialOperationsPaused)
                      Positioned(
""", replacement)

# Don't forget to close the Directionality parenthesis where the Stack closes!
# The stack ends at:
#                      ),
#                  ],
#                );

end_replacement = """                      ),
                  ],
                ),
                );"""

content = content.replace("""                      ),
                  ],
                );""", end_replacement)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Wrapped Stack in Directionality")
