import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/di/service_locator.dart';
import 'package:customer_app/src/data/repositories/profile/profile_repository_impl.dart';
import 'package:customer_app/src/domain/entities/profile/user_profile.dart';
import 'package:customer_app/src/domain/repositories/profile/profile_repository.dart';
import 'package:customer_app/src/presentation/widgets/dynamic_island_toast.dart';

class RewardsReferralScreen extends StatefulWidget {
  const RewardsReferralScreen({super.key});

  @override
  State<RewardsReferralScreen> createState() => _RewardsReferralScreenState();
}

class _RewardsReferralScreenState extends State<RewardsReferralScreen> {
  late final ProfileRepository _repository;
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoadingTransactions = false;
  int _redemptionRate = 100; // 100 points = $1.00
  double _referrerBonus = 20.00;
  double _refereeDiscount = 20.00;

  @override
  void initState() {
    super.initState();
    _repository = sl.isRegistered<ProfileRepository>()
        ? sl<ProfileRepository>()
        : ProfileRepositoryImpl();
    _repository.getUserProfile();
    _loadRewardsData();
  }

  Future<void> _loadRewardsData() async {
    setState(() => _isLoadingTransactions = true);
    final result = await _repository.getRewardsSummary();
    result.fold(
      (failure) {
        if (mounted) setState(() => _isLoadingTransactions = false);
      },
      (data) {
        if (mounted) {
          final settings = data['settings'] as Map<String, dynamic>? ?? {};
          final txList = (data['transactions'] as List<dynamic>? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();

          setState(() {
            _isLoadingTransactions = false;
            _transactions = txList;
            _redemptionRate = (settings['points_redemption_rate'] is num)
                ? (settings['points_redemption_rate'] as num).toInt()
                : (int.tryParse(settings['points_redemption_rate']?.toString() ?? '') ?? 100);
            _referrerBonus = (settings['referrer_bonus'] is num)
                ? (settings['referrer_bonus'] as num).toDouble()
                : (double.tryParse(settings['referrer_bonus']?.toString() ?? '') ?? 20.00);
            _refereeDiscount = (settings['referee_discount'] is num)
                ? (settings['referee_discount'] as num).toDouble()
                : (double.tryParse(settings['referee_discount']?.toString() ?? '') ?? 20.00);
          });
        }
      },
    );
  }

  void _showRedeemBottomSheet(BuildContext context, UserProfile profile) {
    int selectedPoints = 500;
    if (profile.rewardPoints < selectedPoints && profile.rewardPoints >= 100) {
      selectedPoints = (profile.rewardPoints ~/ 100) * 100;
    }
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final double creditValue = selectedPoints / _redemptionRate;
            final bool canRedeem = profile.rewardPoints >= 100 &&
                profile.rewardPoints >= selectedPoints;

            return Container(
              padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 32.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44.w,
                        height: 5.h,
                        decoration: BoxDecoration(
                          color: AppColors.borderUnselected,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 18.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Redeem Reward Points',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textHeadline,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentLime.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            '${profile.rewardPoints} pts avail',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'Exchange your reward points for instant wallet credits. Rate: $_redemptionRate pts = LKR 1.00 credit.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5.sp,
                        color: AppColors.textMuted,
                      ),
                    ),
                    SizedBox(height: 20.h),

                    // Quick Select Points
                    Text(
                      'SELECT AMOUNT TO REDEEM',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textMuted,
                        letterSpacing: 1.0,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      children: [250, 500, 1000].map((pts) {
                        final isSelected = selectedPoints == pts;
                        final isAvailable = profile.rewardPoints >= pts;
                        final val = pts / _redemptionRate;

                        return Expanded(
                          child: GestureDetector(
                            onTap: isAvailable
                                ? () {
                                    HapticFeedback.selectionClick();
                                    setModalState(() => selectedPoints = pts);
                                  }
                                : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: EdgeInsets.symmetric(horizontal: 4.w),
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : (isAvailable
                                        ? AppColors.background
                                        : Colors.grey.shade100),
                                borderRadius: BorderRadius.circular(14.r),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : (isAvailable
                                          ? AppColors.borderUnselected
                                          : Colors.grey.shade200),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '$pts pts',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w800,
                                      color: isSelected
                                          ? Colors.white
                                          : (isAvailable
                                              ? AppColors.textHeadline
                                              : Colors.grey.shade400),
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    'LKR ${val.toStringAsFixed(2)}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? AppColors.accentLime
                                          : (isAvailable
                                              ? AppColors.primary
                                              : Colors.grey.shade400),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 24.h),

                    // Conversion Preview Box
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: AppColors.borderUnselected),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Credit Added to Wallet',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              Text(
                                '+LKR ${creditValue.toStringAsFixed(2)}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primary,
                            size: 28.r,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Confirm Button
                    SizedBox(
                      width: double.infinity,
                      height: 52.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          elevation: 0,
                        ),
                        onPressed: (!canRedeem || isSubmitting)
                            ? null
                            : () async {
                                setModalState(() => isSubmitting = true);
                                HapticFeedback.mediumImpact();

                                final res = await _repository
                                    .redeemPoints(selectedPoints);

                                res.fold(
                                  (failure) {
                                    setModalState(() => isSubmitting = false);
                                    Navigator.pop(bottomSheetContext);
                                    DynamicIslandToast.showError(
                                      context,
                                      failure.errorMessage,
                                    );
                                  },
                                  (success) {
                                    Navigator.pop(bottomSheetContext);
                                    HapticFeedback.heavyImpact();
                                    DynamicIslandToast.showSuccess(
                                      context,
                                      'Redeemed $selectedPoints points for LKR ${creditValue.toStringAsFixed(2)} credit!',
                                    );
                                    _repository.getUserProfile();
                                    _loadRewardsData();
                                  },
                                );
                              },
                        child: isSubmitting
                            ? SizedBox(
                                height: 20.r,
                                width: 20.r,
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                canRedeem
                                    ? 'Confirm Redemption'
                                    : 'Insufficient Points (Min 100)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showApplyReferralDialog(BuildContext context) {
    final TextEditingController codeController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
              ),
              title: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.card_giftcard_rounded,
                      color: AppColors.primary,
                      size: 20.r,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'Apply Referral Code',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textHeadline,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter a friend\'s referral code to instantly claim LKR ${_refereeDiscount.toInt()} wallet credit toward your services!',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.sp,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  TextField(
                    controller: codeController,
                    textCapitalization: TextCapitalization.characters,
                    style: GoogleFonts.shareTechMono(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. HG-A8F2',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 14.sp,
                        letterSpacing: 0,
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF6F8F3),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(
                          color: AppColors.borderUnselected,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final code = codeController.text.trim();
                          if (code.isEmpty) {
                            DynamicIslandToast.showError(
                              context,
                              'Please enter a referral code.',
                            );
                            return;
                          }

                          setDialogState(() => isSubmitting = true);
                          HapticFeedback.mediumImpact();

                          final res = await _repository.applyReferralCode(code);

                          res.fold(
                            (failure) {
                              setDialogState(() => isSubmitting = false);
                              DynamicIslandToast.showError(
                                context,
                                failure.errorMessage,
                              );
                            },
                            (data) async {
                              Navigator.of(dialogContext).pop();
                              HapticFeedback.heavyImpact();
                              DynamicIslandToast.showSuccess(
                                context,
                                'Referral code applied! LKR ${_refereeDiscount.toInt()} credit added to your wallet.',
                              );
                              await _repository.getUserProfile();
                              await _loadRewardsData();
                            },
                          );
                        },
                  child: isSubmitting
                      ? SizedBox(
                          height: 16.r,
                          width: 16.r,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Apply Code',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.darkHeaderBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
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
        stream: _repository.watchUserProfile(),
        builder: (context, snapshot) {
          final profile = snapshot.data;
          if (profile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async {
              await _repository.getUserProfile();
              await _loadRewardsData();
            },
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 6.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accentLime,
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.stars_rounded,
                                    color: AppColors.primaryDark,
                                    size: 16.r,
                                  ),
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
                              'LKR ${profile.walletBalance.toStringAsFixed(2)} Credits',
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
                        SizedBox(height: 18.h),
                        // Quick Redeem Points Action Button
                        InkWell(
                          onTap: () => _showRedeemBottomSheet(context, profile),
                          borderRadius: BorderRadius.circular(14.r),
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14.r),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.bolt_rounded,
                                  color: AppColors.accentLime,
                                  size: 18.r,
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  'Redeem Points for Wallet Credit',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Refer & Earn Section
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
                            Icon(
                              Icons.card_giftcard_rounded,
                              color: AppColors.primary,
                              size: 28.r,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Invite Friends, Get LKR ${_referrerBonus.toInt()} Each',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textHeadline,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    'Give LKR ${_refereeDiscount.toInt()} off their 1st service & earn LKR ${_referrerBonus.toInt()} credit!',
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
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
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
                                    ClipboardData(text: profile.referralCode),
                                  );
                                  DynamicIslandToast.showSuccess(
                                    context,
                                    'Referral code copied to clipboard!',
                                  );
                                },
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.copy_rounded,
                                      color: AppColors.primary,
                                      size: 18.r,
                                    ),
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
                        SizedBox(height: 12.h),
                        InkWell(
                          onTap: () => _showApplyReferralDialog(context),
                          borderRadius: BorderRadius.circular(12.r),
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 11.h),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.redeem_rounded,
                                  size: 16.r,
                                  color: AppColors.primary,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  'Have a friend\'s referral code? Apply here',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Recent Rewards Activity Ledger
                  Text(
                    'RECENT REWARD ACTIVITY',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMuted,
                      letterSpacing: 1.0,
                    ),
                  ),
                  SizedBox(height: 12.h),

                  if (_isLoadingTransactions)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_transactions.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: AppColors.borderUnselected),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.history_rounded,
                              size: 32.r,
                              color: AppColors.textMuted.withValues(alpha: 0.5),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'No recent activity yet',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: AppColors.borderUnselected),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _transactions.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          color: AppColors.borderUnselected.withValues(alpha: 0.6),
                        ),
                        itemBuilder: (context, index) {
                          final tx = _transactions[index];
                          final int points = (tx['points'] is num)
                              ? (tx['points'] as num).toInt()
                              : (int.tryParse(tx['points']?.toString() ?? '') ?? 0);
                          final double amount = (tx['amount'] is num)
                              ? (tx['amount'] as num).toDouble()
                              : (double.tryParse(tx['amount']?.toString() ?? '') ?? 0.0);
                          final String desc = tx['description']?.toString() ?? '';
                          final bool isPositive = points > 0 || amount > 0;

                          return Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 14.h,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8.r),
                                  decoration: BoxDecoration(
                                    color: isPositive
                                        ? AppColors.primary.withValues(alpha: 0.1)
                                        : Colors.amber.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isPositive
                                        ? Icons.add_circle_outline_rounded
                                        : Icons.remove_circle_outline_rounded,
                                    color: isPositive
                                        ? AppColors.primary
                                        : Colors.amber.shade800,
                                    size: 20.r,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        desc,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textHeadline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (points != 0)
                                      Text(
                                        points > 0 ? '+$points pts' : '$points pts',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w800,
                                          color: points > 0
                                              ? AppColors.primaryDark
                                              : Colors.red.shade700,
                                        ),
                                      ),
                                    if (amount != 0)
                                      Text(
                                        amount > 0
                                            ? '+LKR ${amount.toStringAsFixed(2)}'
                                            : '-LKR ${amount.abs().toStringAsFixed(2)}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
