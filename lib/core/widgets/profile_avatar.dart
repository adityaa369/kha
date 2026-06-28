import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class ProfileAvatar extends StatelessWidget {
  final String? gender;
  final double height;

  const ProfileAvatar({super.key, this.gender, required this.height});

  @override
  Widget build(BuildContext context) {
    final isFemale = gender?.toLowerCase() == 'female';

    // Quality 3D character animations
    final lottieUrl = isFemale
        ? 'https://assets2.lottiefiles.com/packages/lf20_wetez0a6.json'
        : 'https://assets9.lottiefiles.com/packages/lf20_yzoqyyqf.json';

    return SizedBox(
      height: height,
      width: height,
      child: Lottie.network(
        lottieUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to static asset if Lottie fails to load
          final assetPath = isFemale
              ? 'assets/images/avatar_female.png'
              : 'assets/images/avatar_male.png';
          return Image.asset(assetPath, fit: BoxFit.contain);
        },
      ),
    );
  }
}
