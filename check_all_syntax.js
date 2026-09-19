const fs = require('fs');
const { execSync } = require('child_process');
const glob = require('glob');

const files = [...glob.sync('server/controllers/**/*.js'), ...glob.sync('server/routes/**/*.js'), ...glob.sync('server/*.js')];
let failed = false;
for (const file of files) {
    try {
        execSync(
ode -c );
    } catch (e) {
        console.error(Syntax error in );
        failed = true;
    }
}
if (!failed) console.log("All syntax ok!");
