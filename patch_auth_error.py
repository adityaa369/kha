
import re

with open("lib/core/blocs/auth/auth_cubit.dart", "r") as f:
    code = f.read()

def replace_catch(match):
    return """catch (e) {
        String msg = "Authentication failed";
        if (e is Failure) msg = e.message;
        else if (e is DioException && e.error is Failure) msg = (e.error as Failure).message;
        else msg = e.toString();
        emit(AuthError(msg));"""

code = re.sub(r"catch \(e\) \{\s*String msg = e is Failure \? e\.message : e\.toString\(\);\s*emit\(AuthError\(msg\)\);", replace_catch, code)

with open("lib/core/blocs/auth/auth_cubit.dart", "w") as f:
    f.write(code)

