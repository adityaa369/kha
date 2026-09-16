const fs = require("fs");
let code = fs.readFileSync("lib/features/profile/presentation/pages/security_hub_page.dart", "utf8");

// Add WidgetsBindingObserver mixin
if (!code.includes("WidgetsBindingObserver")) {
    code = code.replace("class _SecurityHubPageState extends State<SecurityHubPage> {", "class _SecurityHubPageState extends State<SecurityHubPage> with WidgetsBindingObserver {");
}

// Register observer
if (!code.includes("WidgetsBinding.instance.addObserver(this);")) {
    code = code.replace("super.initState();", "super.initState();\n    WidgetsBinding.instance.addObserver(this);");
}

// Unregister observer
if (!code.includes("WidgetsBinding.instance.removeObserver(this);")) {
    let disposeCode = `
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
`;
    code = code.replace("  @override\n  Widget build", disposeCode + "  @override\n  Widget build");
}

// Add lifecycle hook
if (!code.includes("didChangeAppLifecycleState")) {
    let lifecycleCode = `
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final authState = context.read<AuthCubit>().state;
      if (authState is Authenticated && !(authState.user.isEmailVerified)) {
        context.read<AuthCubit>().syncFirebaseState();
      }
    }
  }
`;
    code = code.replace("  @override\n  Widget build", lifecycleCode + "  @override\n  Widget build");
}

// Add Email Verification UI
let emailCode = `
                  // Email Verification UI
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, authState) {
                      if (authState is Authenticated && !(authState.user.isEmailVerified)) {
                        return Container(
                          margin: EdgeInsets.only(bottom: 24.h),
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                                  SizedBox(width: 8.w),
                                  Text(
                                    "Email not verified",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade900,
                                      fontSize: 16.sp
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                "Verify your email to accept loans and unlock all features.",
                                style: TextStyle(color: Colors.orange.shade900, fontSize: 13.sp),
                              ),
                              SizedBox(height: 12.h),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange.shade600,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () async {
                                    try {
                                      await context.read<AuthCubit>().sendVerificationEmail();
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Verification email sent! Check your inbox.")),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(e.toString())),
                                        );
                                      }
                                    }
                                  },
                                  child: const Text("Verify Email"),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }
                  ),
`;

if (!code.includes("Email not verified")) {
    code = code.replace("children: [", "children: [\n" + emailCode);
}

fs.writeFileSync("lib/features/profile/presentation/pages/security_hub_page.dart", code);

