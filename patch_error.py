
import re

with open("lib/core/utils/error_handler.dart", "r") as f:
    code = f.read()

if "import '../error/failures.dart';" not in code:
    code = code.replace("import 'dialog_utils.dart';", "import 'dialog_utils.dart';\nimport '../error/failures.dart';")

code = code.replace("if (error is AppException) {", "if (error is Failure) {\n      message = error.message;\n    } else if (error is AppException) {")

with open("lib/core/utils/error_handler.dart", "w") as f:
    f.write(code)

