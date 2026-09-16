const fs = require("fs");
let code = fs.readFileSync("lib/core/utils/error_handler.dart", "utf8");
code = "import 'package:dio/dio.dart';\n" + code;
let search = "if (error is Failure) {\n      message = error.message;\n    } else if (error is AppException) {";
let replace = "if (error is Failure) {\n      message = error.message;\n    } else if (error is DioException && error.error is Failure) {\n      message = (error.error as Failure).message;\n    } else if (error is DioException && error.response != null && error.response!.data is Map && error.response!.data['message'] != null) {\n      message = error.response!.data['message'];\n    } else if (error is DioException) {\n      message = error.message ?? 'Network error';\n    } else if (error is AppException) {";
code = code.replace(search, replace);
fs.writeFileSync("lib/core/utils/error_handler.dart", code);

