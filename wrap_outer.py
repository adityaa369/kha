import os

file_path = 'lib/main.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Remove the inner Directionality
content = content.replace("""                return Directionality(
                  textDirection: TextDirection.ltr,
                  child: Stack(""", """                return Stack(""")

content = content.replace("""                      ),
                  ],
                ),
                );""", """                      ),
                  ],
                );""")

# Add the outer Directionality
content = content.replace("""          builder: (context, child) {
            return BlocBuilder<SystemStateCubit, SystemState>(""", """          builder: (context, child) {
            return Directionality(
              textDirection: TextDirection.ltr,
              child: BlocBuilder<SystemStateCubit, SystemState>(""")

content = content.replace("""                  ],
                );
              }
            );""", """                  ],
                );
              }
            ),
            );""")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Moved Directionality to wrap BlocBuilder")
