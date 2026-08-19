import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:customer_app/core/constants/app_colors.dart';

class AuthHeaderBanner extends StatelessWidget {
  final String assetPath;
  final IconData fallbackIcon;
  final double heightRatio;
  final double minHeight;
  final double maxHeight;

  const AuthHeaderBanner({
    super.key,
    required this.assetPath,
    required this.fallbackIcon,
    this.heightRatio = 0.38,
    this.minHeight = 200,
    this.maxHeight = 360,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: (screenHeight * heightRatio).clamp(minHeight, maxHeight),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            assetPath,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (_, _, _) {
              return Container(
                color: AppColors.darkHeaderBg,
                child: Center(
                  child: Icon(fallbackIcon, size: 64, color: Colors.white24),
                ),
              );
            },
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 100.h,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.45),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
