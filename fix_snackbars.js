const fs = require('fs');
const path = require('path');

function replaceErrorSnackBars(dir) {
    const list = fs.readdirSync(dir);
    list.forEach(file => {
        const filePath = path.join(dir, file);
        if (fs.statSync(filePath).isDirectory()) { 
            replaceErrorSnackBars(filePath);
        } else if (filePath.endsWith('.dart')) {
            let code = fs.readFileSync(filePath, 'utf8');
            let modified = false;

            // Match from ScaffoldMessenger to the end of the statement, only if it contains red or dangerRed
            const regex = /ScaffoldMessenger\.of\([^)]+\)\.showSnackBar\(\s*SnackBar\([\s\S]*?(?:dangerRed|Colors\.red)[^;]*;/g;
            
            code = code.replace(regex, (match) => {
                modified = true;
                const textMatch = match.match(/content:\s*Text\(\s*(.*?)\s*\)/);
                const message = textMatch ? textMatch[1] : "'An error occurred'";
                return `ErrorHandler.showError(context, ${message});`;
            });

            if (modified) {
                if (!code.includes('ErrorHandler')) {
                    // Try to inject at the last import
                    const lastImportIndex = code.lastIndexOf('import ');
                    if (lastImportIndex !== -1) {
                        const endOfLine = code.indexOf('\n', lastImportIndex);
                        code = code.substring(0, endOfLine + 1) + "import 'package:khataa/core/utils/error_handler.dart';\n" + code.substring(endOfLine + 1);
                    } else {
                        code = "import 'package:khataa/core/utils/error_handler.dart';\n" + code;
                    }
                }
                fs.writeFileSync(filePath, code);
                console.log('Fixed ' + filePath);
            }
        }
    });
}
replaceErrorSnackBars('lib');
