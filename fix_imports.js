const fs = require('fs');
const path = require('path');
function walk(dir) {
    const list = fs.readdirSync(dir);
    list.forEach(file => {
        const filePath = path.join(dir, file);
        if (fs.statSync(filePath).isDirectory()) { 
            walk(filePath);
        } else if (filePath.endsWith('.dart')) {
            let code = fs.readFileSync(filePath, 'utf8');
            if (code.includes('ErrorHandler.showError') && !code.includes('error_handler.dart')) {
                code = "import 'package:khataa/core/utils/error_handler.dart';\n" + code;
                fs.writeFileSync(filePath, code);
                console.log('Added import to ' + filePath);
            }
        }
    });
}
walk('lib');
