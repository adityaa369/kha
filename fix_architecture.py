import os

file_path = 'lib/main.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# I will write a regex to safely replace from `child: ScreenUtilInit(` up to the closing `);` of the builder.
# To be absolutely safe without regex pitfalls, I'll do string matching.

start_marker = "child: ScreenUtilInit("
end_marker = """              }
            );
          },
        ),
      ),
    );"""

new_block = """child: ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) {
            return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              title: 'Khaata',
              theme: KhaataTheme.lightTheme,
              routerConfig: router,
              builder: (context, routerWidget) {
                return BlocBuilder<SystemStateCubit, SystemState>(
                  builder: (context, systemState) {
                    return Stack(
                      children: [
                        if (routerWidget != null) routerWidget,
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
                                    const BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))
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
                                            if (context.mounted) {
                                              context.read<SystemStateCubit>().resumeOperations();
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Operations resumed successfully!'))
                                              );
                                            }
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
                  },
                );
              },
            );
          },
        ),
      ),
    );"""

start_idx = content.find(start_marker)
end_idx = content.find(end_marker) + len(end_marker)

if start_idx != -1 and end_idx != -1:
    content = content[:start_idx] + new_block + content[end_idx:]
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Successfully replaced ScreenUtilInit block")
else:
    print("Could not find markers")
