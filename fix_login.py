import re

with open('lib/features/auth/presentation/pages/login_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace(
    "SvgPicture.asset(\n                    'assets/images/logo_offwhite.svg',\n                    height: 80.h,\n                  ),",
    "Image.asset(\n                    'assets/images/splash_logo.png',\n                    height: 80.h,\n                  ),"
)

with open('lib/features/auth/presentation/pages/login_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)
