import os

file_path = 'lib/main.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

replacement = """        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          splitScreenMode: true,
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'Khaata',
            theme: KhaataTheme.lightTheme,
            routerConfig: router,
          ),
          builder: (context, child) {"""

content = content.replace("""        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) {""", replacement)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Restored MaterialApp.router child in ScreenUtilInit")
