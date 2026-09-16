const fs = require("fs");
let code = fs.readFileSync("lib/features/profile/presentation/pages/security_hub_page.dart", "utf8");

code = code.replace("import '../../../../core/blocs/auth/auth_state.dart';\n", "");
fs.writeFileSync("lib/features/profile/presentation/pages/security_hub_page.dart", code);

