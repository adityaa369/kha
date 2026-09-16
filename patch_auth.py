
import re

with open("lib/core/blocs/auth/auth_cubit.dart", "r") as f:
    code = f.read()

if "import '../../error/failures.dart';" not in code:
    code = code.replace("import 'package:equatable/equatable.dart';", "import 'package:equatable/equatable.dart';\nimport '../../error/failures.dart';")

code = re.sub(r"catch \(e\) \{\s*emit\(AuthError\(e\.toString\(\)\)\);", "catch (e) {\n        String msg = e is Failure ? e.message : e.toString();\n        emit(AuthError(msg));", code)

with open("lib/core/blocs/auth/auth_cubit.dart", "w") as f:
    f.write(code)

