import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/src/data/models/language/language_model.dart';

class LanguageOptionCard extends StatelessWidget {
  final LanguageModel language;
  final bool isSelected;
  final VoidCallback onTap;

  const LanguageOptionCard({
    super.key,
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      margin: EdgeInsets.only(bottom: 14.h),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.cardSelectedBg
            : AppColors.cardUnselectedBg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isSelected
              ? AppColors.borderSelected
              : AppColors.borderUnselected,
          width: isSelected ? 1.6 : 1.2,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(20.r),
          splashColor: AppColors.primary.withValues(alpha: 0.08),
          highlightColor: AppColors.primary.withValues(alpha: 0.04),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        language.nativeName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        language.englishName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5.sp,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isSelected
                              ? AppColors.primaryAccent
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildRadioIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRadioIndicator() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: 26.r,
      height: 26.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? AppColors.radioSelected : Colors.transparent,
        border: Border.all(
          color: isSelected
              ? AppColors.radioSelected
              : AppColors.radioUnselected,
          width: isSelected ? 0 : 1.8,
        ),
      ),
      child: isSelected
          ? const Center(
              child: Icon(Icons.check_rounded, size: 16, color: Colors.white),
            )
          : null,
    );
  }
}
