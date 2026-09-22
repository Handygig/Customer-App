import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:customer_app/core/constants/app_colors.dart';

class AuthBackButton extends StatelessWidget {
  final VoidCallback? onTap;

  const AuthBackButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
          child: Container(
            width: 42.r,
            height: 42.r,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.8),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                splashColor: AppColors.primary.withValues(alpha: 0.15),
                highlightColor: AppColors.primary.withValues(alpha: 0.08),
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (onTap != null) {
                    onTap!();
                  } else {
                    Navigator.of(context).maybePop();
                  }
                },
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.only(left: 3.w),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18.r,
                      color: AppColors.textHeadline,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
