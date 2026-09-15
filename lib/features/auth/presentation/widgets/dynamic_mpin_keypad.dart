import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math';

class DynamicMpinKeypad extends StatefulWidget {
  final ValueChanged<String> onMpinEntered;
  final int maxLength;

  const DynamicMpinKeypad({
    super.key,
    required this.onMpinEntered,
    this.maxLength = 6,
  });

  @override
  State<DynamicMpinKeypad> createState() => DynamicMpinKeypadState();
}

class DynamicMpinKeypadState extends State<DynamicMpinKeypad> {
  List<int> _keypadDigits = [];
  String _currentMpin = '';

  @override
  void initState() {
    super.initState();
    _shuffleKeypad();
  }

  void _shuffleKeypad() {
    final random = Random.secure();
    final digits = List<int>.generate(10, (i) => i);
    digits.shuffle(random);
    setState(() {
      _keypadDigits = digits;
      _currentMpin = '';
    });
  }
  
  void clear() {
    setState(() {
      _currentMpin = '';
    });
  }
  
  void reshuffle() {
    _shuffleKeypad();
  }

  void _onKeyPress(int digit) {
    if (_currentMpin.length < widget.maxLength) {
      setState(() {
        _currentMpin += digit.toString();
      });
      if (_currentMpin.length == widget.maxLength) {
        widget.onMpinEntered(_currentMpin);
      }
    }
  }

  void _onBackspace() {
    if (_currentMpin.isNotEmpty) {
      setState(() {
        _currentMpin = _currentMpin.substring(0, _currentMpin.length - 1);
      });
    }
  }

  Widget _buildKey(Widget child, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade100,
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Dots indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.maxLength, (index) {
            final isFilled = index < _currentMpin.length;
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 8.w),
              width: 16.w,
              height: 16.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFilled ? Theme.of(context).primaryColor : Colors.grey.shade300,
                border: Border.all(
                  color: isFilled ? Theme.of(context).primaryColor : Colors.grey.shade400,
                  width: 1,
                ),
              ),
            );
          }),
        ),
        SizedBox(height: 32.h),
        // Grid
        Flexible(
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.2,
              crossAxisSpacing: 16.w,
              mainAxisSpacing: 16.h,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              if (index < 9) {
                final digit = _keypadDigits[index];
                return _buildKey(
                  Text(
                    digit.toString(),
                    style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
                  ),
                  () => _onKeyPress(digit),
                );
              } else if (index == 9) {
                return const SizedBox.shrink(); // Empty space
              } else if (index == 10) {
                final digit = _keypadDigits[9];
                return _buildKey(
                  Text(
                    digit.toString(),
                    style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
                  ),
                  () => _onKeyPress(digit),
                );
              } else {
                return _buildKey(
                  Icon(Icons.backspace_outlined, size: 24.sp, color: Colors.grey.shade700),
                  _onBackspace,
                );
              }
            },
          ),
        ),
      ],
    );
  }
}