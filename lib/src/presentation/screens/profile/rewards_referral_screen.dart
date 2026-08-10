import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/src/data/repositories/profile_repository_impl.dart';
import 'package:customer_app/src/domain/entities/user_profile.dart';
import 'package:customer_app/src/presentation/widgets/dynamic_island_toast.dart';

class RewardsReferralScreen extends StatelessWidget {
  const RewardsReferralScreen({super.key});

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
          'Rewards & Wallet',
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
          if (profile == null) return const Center(child: CircularProgressIndicator());

          return SingleChildScrollView(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // VIP Membership & Points Header Card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(22.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24.r),
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryDark, AppColors.primary],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryDark.withValues(alpha: 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: AppColors.accentLime,
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.stars_rounded,
                                    color: AppColors.primaryDark, size: 16.r),
                                SizedBox(width: 6.w),
                                Text(
                                  profile.membershipTier.toUpperCase(),
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppColors.primaryDark,
                                    fontSize: 11.5.sp,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '\$${profile.walletBalance.toStringAsFixed(2)} Credits',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20.h),
                      Text(
                        '${profile.rewardPoints}',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 42.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'AVAILABLE REWARD POINTS',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFFC7CBC0),
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),

                // Refer & Earn $20 Section
                Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: AppColors.borderUnselected),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.card_giftcard_rounded,
                              color: AppColors.primary, size: 28.r),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Invite Friends, Get \$20 Each',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textHeadline,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  'Give \$20 off their 1st service & earn \$20 credit!',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5.sp,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 18.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(color: AppColors.borderUnselected),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              profile.referralCode,
                              style: GoogleFonts.shareTechMono(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDark,
                                letterSpacing: 2.0,
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                Clipboard.setData(
                                    ClipboardData(text: profile.referralCode));
                                DynamicIslandToast.showSuccess(context, 'Referral code copied to clipboard!');
                              },
                              child: Row(
                                children: [
                                  Icon(Icons.copy_rounded,
                                      color: AppColors.primary, size: 18.r),
                                  SizedBox(width: 4.w),
                                  Text(
                                    'Copy',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.5.sp,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
}
