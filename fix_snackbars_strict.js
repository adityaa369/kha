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

            // Strict regex: match ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(<message>), backgroundColor: <color>));
            // Ensure we don't bleed across lines uncontrollably
            const regex = /ScaffoldMessenger\.of\([^)]+\)\.showSnackBar\(\s*SnackBar\(\s*content:\s*Text\(([^)]+)\)[^;]+(?:dangerRed|Colors\.red)[^;]+;\s*\)/g;
            
            code = code.replace(regex, (match, messageContent) => {
                modified = true;
                return `ErrorHandler.showError(context, ${messageContent});`;
            });
            
            // Also handle const SnackBar
            const regex2 = /ScaffoldMessenger\.of\([^)]+\)\.showSnackBar\(\s*const SnackBar\(\s*content:\s*Text\(([^)]+)\)[^;]+(?:dangerRed|Colors\.red)[^;]+;\s*\)/g;
            code = code.replace(regex2, (match, messageContent) => {
                modified = true;
                return `ErrorHandler.showError(context, ${messageContent});`;
            });

            if (modified) {
                if (!code.includes('ErrorHandler')) {
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
