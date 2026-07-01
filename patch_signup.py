import os

file_path = "lib/features/auth/presentation/pages/signup_page.dart"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

if "import '../../../../core/utils/date_input_formatter.dart';" not in content:
    content = content.replace(
        "import '../../../../core/blocs/auth/auth_cubit.dart';",
        "import '../../../../core/blocs/auth/auth_cubit.dart';\nimport '../../../../core/utils/date_input_formatter.dart';"
    )

target = """            GestureDetector(
              onTap: () => _selectDOB(context),
              child: AbsorbPointer(
                child: TextFormField(
                  controller: _dobController,
                  validator: (val) => val == null || val.isEmpty
                      ? 'Date of birth is required'
                      : null,"""

replacement = """            TextFormField(
              controller: _dobController,
              keyboardType: TextInputType.number,
              inputFormatters: [DateInputFormatter()],
              validator: (val) {
                if (val == null || val.isEmpty) return 'Date of birth is required';
                if (val.length != 10) return 'Enter a valid date (DD/MM/YYYY)';
                return null;
              },"""

content = content.replace(target, replacement)

closing_target = """                        color: KhaataTheme.primaryBlue,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 12.h,
                    ),
                  ),
                ),
              ),
            ),"""

closing_replacement = """                        color: KhaataTheme.primaryBlue,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 12.h,
                    ),
                  ),
            ),"""

content = content.replace(closing_target, closing_replacement, 1)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

print("patched")
