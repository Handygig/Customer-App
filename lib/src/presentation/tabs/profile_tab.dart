import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer_app/core/constants/app_assets.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/src/data/repositories/profile_repository_impl.dart';
import 'package:customer_app/src/domain/entities/user_profile.dart';
import 'package:customer_app/src/domain/entities/property.dart';
import 'package:customer_app/src/domain/entities/payment_card.dart';
import 'package:customer_app/src/presentation/screens/profile/edit_profile_screen.dart';
import 'package:customer_app/src/presentation/screens/profile/payment_methods_screen.dart';
import 'package:customer_app/src/presentation/screens/profile/properties_management_screen.dart';
import 'package:customer_app/src/presentation/screens/profile/help_support_screen.dart';
import 'package:customer_app/src/presentation/screens/profile/settings_screen.dart';

class ProfileTab extends StatelessWidget {
  final VoidCallback? onAddPropertyTap;

  const ProfileTab({super.key, this.onAddPropertyTap});

  @override
  Widget build(BuildContext context) {
    final repository = ProfileRepositoryImpl();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<UserProfile>(
        stream: repository.watchUserProfile(),
        builder: (context, profileSnapshot) {
          final profile = profileSnapshot.data ??
              const UserProfile(
                id: '1',
                firstName: 'Alex',
                lastName: 'Johnson',
                email: 'alex@example.com',
                phone: '+1 (555) 382-9102',
                gender: GenderType.male,
                membershipTier: 'Gold Member',
                rewardPoints: 1250,
                walletBalance: 45.00,
                referralCode: 'ALEX2026',
                isTwoFactorEnabled: false,
                languageCode: 'en',
                pushNotificationsEnabled: true,
                biometricsEnabled: true,
                memberSinceYear: '2026',
              );

          return SingleChildScrollView(
            child: Column(
              children: [
                // Profile Hero Image Header with Smooth Bottom Fade (Inspiration Layout)
                Stack(
                  children: [
                    // 1. Background Profile Header Image
                    SizedBox(
                      height: 320.h,
                      width: double.infinity,
                      child: Image.asset(
                        AppAssets.profileHeader,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [AppColors.primaryDark, AppColors.primary],
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.person_rounded,
                                size: 100.r,
                                color: Colors.white12,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // 2. Smooth Bottom Gradient Mask (Fades into Page Background)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.35, 0.72, 1.0],
                            colors: [
                              Colors.black.withValues(alpha: 0.30), // subtle dark top tint
                              Colors.transparent,
                              AppColors.background.withValues(alpha: 0.75),
                              AppColors.background, // Complete smooth fade into page background
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 3. Floating Edit Button (Top Right)
                    Positioned(
                      top: 50.h,
                      right: 18.w,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(Icons.edit_rounded,
                              color: AppColors.primaryDark, size: 20.r),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => EditProfileScreen(profile: profile),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // 4. Centered User Info Overlaid on Bottom Fade
                    Positioned(
                      left: 20.w,
                      right: 20.w,
                      bottom: 8.h,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Avatar Ring
                          Container(
                            width: 80.r,
                            height: 80.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(color: AppColors.primary, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                profile.firstName.isNotEmpty
                                    ? profile.firstName[0].toUpperCase()
                                    : 'A',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.primaryDark,
                                  fontSize: 32.sp,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 10.h),

                          // Full Name
                          Text(
                            profile.fullName,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.textHeadline,
                              fontSize: 24.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 4.h),

                          // Membership Badge
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: AppColors.cardSelectedBg,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              profile.membershipTier.toUpperCase(),
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.primary,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          SizedBox(height: 6.h),

                          // Subtitle Info
                          Text(
                            '${profile.phone} • Member since ${profile.memberSinceYear}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.textMuted,
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Main Content Options
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 110.h),
                  child: Column(
                    children: [
                      // Edit Personal Profile Tile
                      _buildOptionTile(
                        icon: Icons.person_outline_rounded,
                        title: 'Personal Details',
                        subtitle: 'Name, Email, Phone, Gender',
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => EditProfileScreen(profile: profile),
                            ),
                          );
                        },
                      ),

                      // Properties Management Stream Builder Subtitle
                      StreamBuilder<List<Property>>(
                        stream: repository.watchProperties(),
                        builder: (context, snapshot) {
                          final propCount = snapshot.data?.length ?? 3;
                          return _buildOptionTile(
                            icon: Icons.location_city_rounded,
                            title: 'Manage Properties',
                            subtitle: '$propCount properties registered',
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const PropertiesManagementScreen(),
                                ),
                              );
                            },
                          );
                        },
                      ),

                      // Payment Methods Stream Builder Subtitle
                      StreamBuilder<List<PaymentCard>>(
                        stream: repository.watchPaymentCards(),
                        builder: (context, snapshot) {
                          final cards = snapshot.data ?? [];
                          final defaultCard = cards.firstWhere(
                            (c) => c.isDefault,
                            orElse: () => cards.isNotEmpty
                                ? cards.first
                                : const PaymentCard(
                                    id: '0',
                                    cardholderName: '',
                                    lastFourDigits: '4920',
                                    expiryDate: '',
                                    brand: CardBrand.visa),
                          );
                          final subText = cards.isEmpty
                              ? 'No cards saved'
                              : '${defaultCard.brand.name.toUpperCase()} ending ${defaultCard.lastFourDigits}';

                          return _buildOptionTile(
                            icon: Icons.credit_card_rounded,
                            title: 'Payment Methods',
                            subtitle: subText,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const PaymentMethodsScreen(),
                                ),
                              );
                            },
                          );
                        },
                      ),

                      // Help & 24/7 Support
                      _buildOptionTile(
                        icon: Icons.support_agent_rounded,
                        title: 'Help & 24/7 Support',
                        subtitle: 'Emergency hotline, FAQ, Live Chat',
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const HelpSupportScreen(),
                            ),
                          );
                        },
                      ),

                      // Settings & Security (Language, Password, 2FA)
                      _buildOptionTile(
                        icon: Icons.settings_outlined,
                        title: 'Settings & Security',
                        subtitle: 'Language, Password, 2FA & Security',
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SettingsScreen(),
                            ),
                          );
                        },
                      ),

                      // Sign Out Button
                      _buildOptionTile(
                        icon: Icons.logout_rounded,
                        title: 'Sign Out',
                        subtitle: 'Log out of customer app account',
                        isDestructive: true,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          _showSignOutConfirmation(context);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderUnselected),
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onTap,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        leading: Container(
          padding: EdgeInsets.all(10.r),
          decoration: BoxDecoration(
            color: isDestructive ? Colors.red.shade50 : AppColors.cardSelectedBg,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(
            icon,
            color: isDestructive ? Colors.red : AppColors.primary,
            size: 22.r,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14.5.sp,
            fontWeight: FontWeight.w700,
            color: isDestructive ? Colors.red : AppColors.textHeadline,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.sp,
            color: AppColors.textMuted,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14.r,
          color: AppColors.borderUnselected,
        ),
      ),
      ),
    );
  }

  void _showSignOutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          'Sign Out',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            color: AppColors.textHeadline,
          ),
        ),
        content: Text(
          'Are you sure you want to log out of your account?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14.sp,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text(
              'Sign Out',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
