
import re

with open("lib/core/utils/error_handler.dart", "r") as f:
    code = f.read()

code = code.replace("if (error is Failure) {", "if (error is Failure) {\\n      message = error.message;\\n    } else if (error is DioException && error.error is Failure) {\\n      message = (error.error as Failure).message;\\n    } else if (error is DioException && error.response?.data?['message'] != null) {\\n      message = error.response!.data['message'];\\n    } else if (error is DioException) {\\n      message = error.message ?? 'Network error';\\n    } else if (error is Failure) {")

with open("lib/core/utils/error_handler.dart", "w") as f:
    f.write(code)

