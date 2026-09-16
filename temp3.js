const fs = require("fs");
let code = fs.readFileSync("lib/core/utils/error_handler.dart", "utf8");
code = code.replace(/} else if \(error is DioException && error\.response != null[\s\S]*?} else if \(error is AppException\) {/, "} else if (error is DioException && error.response != null && error.response!.data is Map && error.response!.data['message'] != null) {\n      message = error.response!.data['message'];\n    } else if (error is DioException) {\n      message = error.message ?? 'Network error';\n    } else if (error is AppException) {");
fs.writeFileSync("lib/core/utils/error_handler.dart", code);

