import 'package:flutter/material.dart';

class LoopingAvatar extends StatefulWidget {
  final String? gender;
  final double height;
  
  const LoopingAvatar({super.key, this.gender, required this.height});

  @override
  State<LoopingAvatar> createState() => _LoopingAvatarState();
}

class _LoopingAvatarState extends State<LoopingAvatar> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine)
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFemale = widget.gender?.toLowerCase() == 'female';
    final assetPath = isFemale ? 'assets/images/avatar_female.png' : 'assets/images/avatar_male.png';
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: child,
        );
      },
      child: Image.asset(assetPath, height: widget.height, fit: BoxFit.contain),
    );
  }
}
