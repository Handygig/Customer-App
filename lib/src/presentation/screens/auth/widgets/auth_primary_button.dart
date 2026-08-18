import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer_app/core/constants/app_colors.dart';

class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool loading;
  final IconData trailingIcon;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.enabled,
    this.loading = false,
    this.trailingIcon = Icons.arrow_forward_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final active = enabled && !loading;

    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28.r),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : const [],
        ),
        child: ElevatedButton(
          onPressed: active ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                active ? AppColors.buttonBackground : const Color(0xFFE2E4DE),
            foregroundColor:
                active ? AppColors.buttonText : AppColors.textSecondary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28.r),
            ),
            padding: EdgeInsets.symmetric(horizontal: 24.w),
          ),
          child: loading
              ? SizedBox(
                  width: 24.r,
                  height: 24.r,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: active ? Colors.white : AppColors.textSecondary,
                        letterSpacing: 0.1,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Icon(
                      trailingIcon,
                      color: active ? Colors.white : AppColors.textSecondary,
                      size: 22,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
