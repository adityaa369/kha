const fs = require("fs");
let code = fs.readFileSync("lib/features/auth/presentation/pages/change_mpin_page.dart", "utf8");

code = code.replace(`DialogUtils.showSuccessDialog(context, 'MPIN changed successfully.');
                    SecurityUtils.unsecureScreen(); 
                    context.pop(true);`, `SecurityUtils.unsecureScreen(); 
                    DialogUtils.showSuccessDialog(context, 'MPIN changed successfully.', onOk: () => context.pop(true));`);

fs.writeFileSync("lib/features/auth/presentation/pages/change_mpin_page.dart", code);

