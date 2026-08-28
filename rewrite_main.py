import os

file_path = 'lib/main.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# I will replace the entire ScreenUtilInit block to make it perfectly clean and robust.

new_screen_util_block = """        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) {
            return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              title: 'Khaata',
              theme: KhaataTheme.lightTheme,
              routerConfig: router,
              builder: (context, widget) {
                return BlocBuilder<SystemStateCubit, SystemState>(
                  builder: (context, systemState) {
                    return Stack(
                      children: [
                        if (widget != null) widget,
                        if (systemState == SystemState.financialOperationsPaused)
                          Positioned(
                            top: 40.h,
                            left: 16.w,
                            right: 16.w,
                            child: Material(
                              color: Colors.transparent,
                              child: Container(
                                padding: EdgeInsets.all(16.w),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade900,
                                  borderRadius: BorderRadius.circular(12.r),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))
                                  ]
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24.sp),
                                        SizedBox(width: 12.w),
                                        Expanded(
                                          child: Text(
                                            '🔴 SERVICE PAUSED\\nFinancial operations are temporarily unavailable. Your funds are safe.',
                                            style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 12.h),
                                    ElevatedButton(
                                      onPressed: () async {
                                        try {
                                          final response = await ApiClient().get('/health/live');
                                          if (response.statusCode == 200) {
                                            context.read<SystemStateCubit>().resumeOperations();
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Operations resumed successfully!'))
                                            );
                                          }
                                        } catch (e) {}
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: Colors.red.shade900,
                                        minimumSize: Size(double.infinity, 36.h),
                                      ),
                                      child: const Text('Check Status / Retry'),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  }
                );
              },
            );
          },
        ),
"""

import re
pattern = re.compile(r'        child: ScreenUtilInit\([\s\S]*?        \),', re.MULTILINE)
content = re.sub(pattern, new_screen_util_block.strip() + ',', content)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Replaced ScreenUtilInit with proper MaterialApp.builder implementation")
