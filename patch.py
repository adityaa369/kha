
import re

with open("lib/features/loans/presentation/pages/loan_approval_page.dart", "r") as f:
    code = f.read()

if "dialog_utils.dart" not in code:
    code = code.replace("import 'package:flutter_bloc/flutter_bloc.dart';", "import 'package:flutter_bloc/flutter_bloc.dart';\nimport '../../../core/utils/dialog_utils.dart';")

code = re.sub(r"ScaffoldMessenger\.of\(context\)\.showSnackBar\([\s\S]*?Biometric signature required to accept agreement\.[\s\S]*?\);", "DialogUtils.showErrorDialog(context, 'Biometric signature required to accept agreement.');", code)
code = re.sub(r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(const SnackBar\(content: Text\('Failed to initialize acceptance process'\)\)\);", "DialogUtils.showErrorDialog(context, 'Failed to initialize acceptance process.');", code)
code = re.sub(r"ScaffoldMessenger\.of\(context\)\.showSnackBar\([\s\S]*?Agreement accepted successfully![\s\S]*?\);", "DialogUtils.showSuccessDialog(context, 'Agreement accepted successfully!', onOk: () => context.pop(true));", code)
code = re.sub(r"ScaffoldMessenger\.of\(context\)\.showSnackBar\([\s\S]*?Failed to accept agreement\.[\s\S]*?\);", "DialogUtils.showErrorDialog(context, 'Failed to accept agreement. Please try again.');", code)

with open("lib/features/loans/presentation/pages/loan_approval_page.dart", "w") as f:
    f.write(code)

