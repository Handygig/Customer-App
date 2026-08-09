import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/src/data/repositories/profile_repository_impl.dart';
import 'package:customer_app/src/domain/entities/user_profile.dart';
import 'package:customer_app/src/presentation/screens/language/language_selection_screen.dart';
import 'package:customer_app/src/presentation/widgets/dynamic_island_toast.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = ProfileRepositoryImpl();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.darkHeaderBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Settings & Security',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<UserProfile>(
        stream: repository.watchUserProfile(),
        builder: (context, snapshot) {
          final profile = snapshot.data;
          if (profile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Header - Account Security
                _buildSectionHeader('ACCOUNT SECURITY'),
                SizedBox(height: 12.h),

                // Password Change Tile
                _buildSettingTile(
                  icon: Icons.lock_outline_rounded,
                  title: 'Change Password',
                  subtitle: 'Update account password',
                  onTap: () => _showChangePasswordModal(context, repository),
                ),

                // 2FA Toggle Tile
                Container(
                  margin: EdgeInsets.only(bottom: 12.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AppColors.borderUnselected),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: AppColors.cardSelectedBg,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(Icons.verified_user_outlined,
                          color: AppColors.primary, size: 22.r),
                    ),
                    title: Text(
                      'Two-Factor Authentication (2FA)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textHeadline,
                      ),
                    ),
                    subtitle: Text(
                      profile.isTwoFactorEnabled
                          ? 'SMS OTP Protection Enabled'
                          : 'Extra layer of security for logins',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.sp,
                        color: profile.isTwoFactorEnabled
                            ? AppColors.primary
                            : AppColors.textMuted,
                      ),
                    ),
                    trailing: Switch.adaptive(
                      value: profile.isTwoFactorEnabled,
                      activeTrackColor: AppColors.primary,
                      onChanged: (val) {
                        HapticFeedback.selectionClick();
                        if (val) {
                          _show2FASetupModal(context, repository);
                        } else {
                          repository.toggleTwoFactorAuth(false);
                        }
                      },
                    ),
                  ),
                ),

                // Biometrics Switch Tile
                Container(
                  margin: EdgeInsets.only(bottom: 12.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AppColors.borderUnselected),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: AppColors.cardSelectedBg,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(Icons.fingerprint_rounded,
                          color: AppColors.primary, size: 22.r),
                    ),
                    title: Text(
                      'Biometric Login (Face ID / Touch ID)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textHeadline,
                      ),
                    ),
                    subtitle: Text(
                      'Sign in quickly using biometrics',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.sp,
                        color: AppColors.textMuted,
                      ),
                    ),
                    trailing: Switch.adaptive(
                      value: profile.biometricsEnabled,
                      activeTrackColor: AppColors.primary,
                      onChanged: (val) {
                        HapticFeedback.selectionClick();
                        repository.toggleBiometrics(val);
                      },
                    ),
                  ),
                ),

                SizedBox(height: 24.h),

                // Section Header - Preferences
                _buildSectionHeader('PREFERENCES & APP'),
                SizedBox(height: 12.h),

                // Language Selection Tile (3-way switch)
                Container(
                  margin: EdgeInsets.only(bottom: 12.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AppColors.borderUnselected),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: AppColors.cardSelectedBg,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(Icons.language_rounded,
                          color: AppColors.primary, size: 22.r),
                    ),
                    title: Text(
                      'App Language',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textHeadline,
                      ),
                    ),
                    subtitle: Text(
                      profile.languageCode == 'si' ? 'සිංහල' : (profile.languageCode == 'ta' ? 'தமிழ்' : 'English'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.sp,
                        color: AppColors.textMuted,
                      ),
                    ),
                    trailing: Container(
                      padding: EdgeInsets.all(3.r),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: AppColors.borderUnselected, width: 0.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildLanguageSegment('en', 'EN', profile.languageCode, repository),
                          _buildLanguageSegment('si', 'SI', profile.languageCode, repository),
                          _buildLanguageSegment('ta', 'TA', profile.languageCode, repository),
                        ],
                      ),
                    ),
                  ),
                ),
                // Push Notifications Switch Tile
                Container(
                  margin: EdgeInsets.only(bottom: 12.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AppColors.borderUnselected),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: AppColors.cardSelectedBg,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(Icons.notifications_none_rounded,
                          color: AppColors.primary, size: 22.r),
                    ),
                    title: Text(
                      'Push Notifications',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textHeadline,
                      ),
                    ),
                    subtitle: Text(
                      'Service updates, job alerts, and receipts',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.sp,
                        color: AppColors.textMuted,
                      ),
                    ),
                    trailing: Switch.adaptive(
                      value: profile.pushNotificationsEnabled,
                      activeTrackColor: AppColors.primary,
                      onChanged: (val) {
                        HapticFeedback.selectionClick();
                        repository.toggleNotifications(val);
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12.sp,
        fontWeight: FontWeight.w800,
        color: AppColors.primary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildLanguageSegment(String code, String display, String currentCode, ProfileRepositoryImpl repository) {
    final isSelected = code == currentCode;
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          HapticFeedback.selectionClick();
          repository.updateLanguage(code);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
          boxShadow: isSelected 
             ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
             : null,
        ),
        child: Text(
          display,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.sp,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? AppColors.primary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? trailingText,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderUnselected),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: EdgeInsets.all(10.r),
          decoration: BoxDecoration(
            color: AppColors.cardSelectedBg,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22.r),
        ),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14.5.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textHeadline,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.sp,
            color: AppColors.textMuted,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailingText != null)
              Container(
                margin: EdgeInsets.only(right: 8.w),
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppColors.cardSelectedBg,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  trailingText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14.r, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordModal(
    BuildContext context,
    ProfileRepositoryImpl repository,
  ) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24.w,
            right: 24.w,
            top: 24.h,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.borderUnselected,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Change Password',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textHeadline,
                ),
              ),
              SizedBox(height: 16.h),
              _buildModalTextField('Current Password', currentCtrl),
              SizedBox(height: 12.h),
              _buildModalTextField('New Password', newCtrl),
              SizedBox(height: 12.h),
              _buildModalTextField('Confirm New Password', confirmCtrl),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: () async {
                    if (newCtrl.text.length < 6) {
                      DynamicIslandToast.showError(context, 'Password must be at least 6 characters.');
                      return;
                    }
                    if (newCtrl.text != confirmCtrl.text) {
                      DynamicIslandToast.showError(context, 'New passwords do not match.');
                      return;
                    }

                    await repository.changePassword(
                      currentPassword: currentCtrl.text,
                      newPassword: newCtrl.text,
                    );

                    if (ctx.mounted) {
                      Navigator.of(ctx).pop();
                      DynamicIslandToast.showSuccess(context, 'Password updated successfully!');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26.r),
                    ),
                  ),
                  child: Text(
                    'Update Password',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModalTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      obscureText: true,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14.5.sp,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.textMuted,
          fontSize: 13.5.sp,
        ),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: const BorderSide(color: AppColors.borderUnselected),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: const BorderSide(color: AppColors.borderUnselected),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  void _show2FASetupModal(
    BuildContext context,
    ProfileRepositoryImpl repository,
  ) {
    final otpCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24.w,
            right: 24.w,
            top: 24.h,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shield_outlined, size: 54.r, color: AppColors.primary),
              SizedBox(height: 12.h),
              Text(
                'Verify 2FA Phone Number',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textHeadline,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'We sent a 4-digit code to +1 (555) ***-9102',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.sp,
                  color: AppColors.textMuted,
                ),
              ),
              SizedBox(height: 20.h),
              TextField(
                controller: otpCtrl,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 8.0,
                ),
                decoration: InputDecoration(
                  hintText: '• • • •',
                  hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 22.sp),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    borderSide: const BorderSide(color: AppColors.borderUnselected),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: () {
                    repository.toggleTwoFactorAuth(true);
                    Navigator.of(ctx).pop();
                    DynamicIslandToast.showSuccess(context, '2FA Authentication enabled!');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26.r),
                    ),
                  ),
                  child: Text(
                    'Confirm & Enable 2FA',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
