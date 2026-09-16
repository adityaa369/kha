const fs = require("fs");
let code = fs.readFileSync("lib/config/routes.dart", "utf8");
code = code.replace(
    "import '../features/auth/presentation/pages/mpin_setup_page.dart';",
    "import '../features/auth/presentation/pages/mpin_setup_page.dart';\nimport '../features/auth/presentation/pages/change_mpin_page.dart';"
);
code = code.replace(
    /GoRoute\(\s*path: AppConstants\.mpinSetup,\s*builder: \(context, state\) => const MpinSetupPage\(\),\s*\),/,
    `GoRoute(
      path: AppConstants.mpinSetup,
      builder: (context, state) => const MpinSetupPage(),
    ),
    GoRoute(
      path: "/change-mpin",
      builder: (context, state) => const ChangeMpinPage(),
    ),`
);
fs.writeFileSync("lib/config/routes.dart", code);

