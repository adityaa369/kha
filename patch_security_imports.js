const fs = require("fs");
let code = fs.readFileSync("lib/features/profile/presentation/pages/security_hub_page.dart", "utf8");

let imports = `import '../../../../core/blocs/auth/auth_cubit.dart';
import '../../../../core/blocs/auth/auth_state.dart';
`;

if (!code.includes("auth_cubit.dart")) {
    code = code.replace("import '../../../../config/constants.dart';", "import '../../../../config/constants.dart';\n" + imports);
}

fs.writeFileSync("lib/features/profile/presentation/pages/security_hub_page.dart", code);

