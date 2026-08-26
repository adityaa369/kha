import os

file_path = 'lib/data/models/loan_model.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add isPending and isFinished to LoanStatus
content = content.replace("  factory LoanStatus.fromString(String status) {", """  bool get isPending => this == LoanStatus.pendingApproval || this == LoanStatus.pendingOtp;
  bool get isFinished => this == LoanStatus.completed || this == LoanStatus.closed || this == LoanStatus.defaulted || this == LoanStatus.rejected;

  factory LoanStatus.fromString(String status) {""")

# Add missing getters to LoanModel (otp, statusColor, loanStatus, totalPayable)
# Put them near remainingAmount
new_getters = """
  String? get otp => id.length >= 6 ? id.substring(0, 6) : null;
  LoanStatus get loanStatus => LoanStatus.fromString(status);
  double? get totalPayable => totalPayablePaise > 0 ? totalPayableAmount : null;
  Color get statusColor {
    switch (status) {
      case 'pending_approval':
      case 'pending_otp':
        return const Color(0xFFF59E0B);
      case 'active':
      case 'completed':
      case 'closed':
        return const Color(0xFF10B981);
      case 'due_soon':
        return const Color(0xFFF59E0B);
      case 'overdue':
      case 'defaulted':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF10B981);
    }
  }
"""

content = content.replace("double get remainingAmount {", new_getters + "\n  double get remainingAmount {")
# Add flutter/material.dart import for Color
content = "import 'package:flutter/material.dart';\n" + content

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Fixed loan_model.dart")
