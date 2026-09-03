import os
import glob
import re

for path in glob.glob('lib/features/loans/presentation/**/*.dart', recursive=True):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    content = content.replace("'?${_fmt(", "'\u20B9${_fmt(")
    content = content.replace("'$sign?${_fmt(", "'$sign\u20B9${_fmt(")
    
    # Let's fix the loan model too
    # Replace displayAmount
    if "String get displayAmount" in content:
        pass # Handle separately

    # Replace the _fmt function
    old_fmt = """  String _fmt(double v) {
    if (v.isNaN || v.isInfinite) return '0';
    return v
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }"""
    
    new_fmt = """  String _fmt(double v) {
    if (v.isNaN || v.isInfinite) return '0';
    return NumberFormat('#,##,##0', 'en_IN').format(v);
  }"""
    
    if old_fmt in content:
        content = content.replace(old_fmt, new_fmt)
        if "import 'package:intl/intl.dart';" not in content:
            content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:intl/intl.dart';")
            
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
