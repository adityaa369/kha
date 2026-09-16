const fs = require("fs");
let code = fs.readFileSync("lib/features/auth/presentation/pages/mpin_setup_page.dart", "utf8");

code = code.replace(`DialogUtils.showSuccessDialog(context, 'MPIN set successfully.');
                    SecurityUtils.unsecureScreen(); 
                    // Pop true so the caller knows setup succeeded
                    context.pop(true);`, `SecurityUtils.unsecureScreen(); 
                    DialogUtils.showSuccessDialog(context, 'MPIN set successfully.', onOk: () => context.pop(true));`);

fs.writeFileSync("lib/features/auth/presentation/pages/mpin_setup_page.dart", code);

