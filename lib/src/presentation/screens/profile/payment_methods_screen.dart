import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/src/domain/entities/profile/payment_card.dart';
import 'package:customer_app/src/presentation/cubits/payments/card_cubit.dart';
import 'package:customer_app/src/presentation/cubits/payments/card_state.dart';
import 'package:customer_app/src/presentation/screens/profile/add_card_screen.dart';
import 'package:customer_app/src/presentation/widgets/dynamic_island_toast.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  int _selectedCardCarouselIndex = 0;
  final PageController _pageController = PageController(viewportFraction: 0.9);

  String _selectedAlternativeMethod =
      'card'; // 'card', 'apple_pay', 'cash', 'bank'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CardCubit>().loadCards();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
          'Payment Methods',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Add New Card',
            icon: const Icon(
              Icons.add_card_rounded,
              color: AppColors.accentLime,
            ),
            onPressed: () => _navigateToAddCard(context),
          ),
        ],
      ),
      body: BlocConsumer<CardCubit, CardState>(
        listener: (context, state) {
          if (state is CardActionSuccess) {
            DynamicIslandToast.showSuccess(context, state.message);
          } else if (state is CardError) {
            DynamicIslandToast.showError(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is CardLoading && context.read<CardCubit>().cards.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final cardEntities = state is CardLoaded
              ? state.cards
              : context.read<CardCubit>().cards;
          final cards = cardEntities.map((c) => c.toPaymentCard()).toList();

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => context.read<CardCubit>().loadCards(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // 1. Section Header with "Add Card" Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Saved Cards (${cards.length})',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textHeadline,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Swipe to switch primary payment card',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5.sp,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () => _navigateToAddCard(context),
                      borderRadius: BorderRadius.circular(20.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: AppColors.primary,
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.add_rounded,
                              size: 16.r,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'Add Card',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                // 2. Interactive Card Showcase / Carousel
                if (cards.isEmpty)
                  _buildEmptyCardsState(context)
                else ...[
                  _buildCardsCarousel(cards),
                  SizedBox(height: 14.h),
                  _buildCarouselPageIndicators(cards.length),
                  SizedBox(height: 16.h),
                  _buildCardQuickActions(cards),
                ],

                SizedBox(height: 28.h),

                // 3. Saved Cards Quick Selection List
                Text(
                  'Manage Saved Cards',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.5.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textHeadline,
                  ),
                ),
                SizedBox(height: 12.h),

                if (cards.isNotEmpty)
                  ...cards.map((card) => _buildCardListTile(context, card)),

                // Add Card Trigger Tile
                _buildAddCardListTile(context),

                SizedBox(height: 24.h),

                // Security & Guarantee Notice
                Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F5EC),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: const Color(0xFFE2E6D5)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.shield_rounded,
                          color: AppColors.primary,
                          size: 20.r,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bank-Grade 256-Bit Encryption',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textHeadline,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'Your payment details are tokenized and protected by PCI-DSS security compliance.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5.sp,
                                color: AppColors.textMuted,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30.h),
              ],
            ),
          ),
        );
        },
      ),
    );
  }

  void _navigateToAddCard(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const AddCardScreen()));
  }

  Widget _buildEmptyCardsState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(28.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: AppColors.borderUnselected, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: AppColors.cardSelectedBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.credit_card_off_rounded,
              size: 40.r,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'No Payment Cards Added',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.textHeadline,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Add your Visa, Mastercard, or Amex to easily pay for bookings and maintenance.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.sp,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          SizedBox(height: 20.h),
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: ElevatedButton.icon(
              onPressed: () => _navigateToAddCard(context),
              icon: const Icon(
                Icons.add_card_rounded,
                color: Colors.white,
                size: 18,
              ),
              label: Text(
                'Add Your First Card',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsCarousel(List<PaymentCard> cards) {
    double stackHeight = 215.h;
    return SizedBox(
      height: stackHeight,
      child: PageView.builder(
        controller: _pageController,
        itemCount: cards.length,
        onPageChanged: (index) {
          setState(() {
            _selectedCardCarouselIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final card = cards[index];
          final isSelected = index == _selectedCardCarouselIndex;

          return AnimatedScale(
            scale: isSelected ? 1.0 : 0.94,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: _buildCreditCardVisual(card),
          );
        },
      ),
    );
  }

  Widget _buildCreditCardVisual(PaymentCard card) {
    List<Color> gradientColors = [
      const Color(0xFF0D253F),
      const Color(0xFF1E50A2),
    ];
    if (card.brand == CardBrand.mastercard) {
      gradientColors = [const Color(0xFF1A1A2E), const Color(0xFF8B1E26)];
    } else if (card.brand == CardBrand.amex) {
      gradientColors = [const Color(0xFF2C3E50), const Color(0xFF4CA1AF)];
    } else if (card.brand == CardBrand.discover) {
      gradientColors = [const Color(0xFF3E2723), const Color(0xFFD84315)];
    }

    final isDefault = card.isDefault;
    final isFrozen = card.isFrozen;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 6.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        border: Border.all(
          color: isDefault
              ? AppColors.accentLime.withValues(alpha: 0.5)
              : Colors.white24,
          width: isDefault ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha: 0.4),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Row: Chip, Contactless NFC & Brand Logo
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // Metallic EMV Chip
                      Container(
                        width: 38.w,
                        height: 28.h,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE8D499), Color(0xFFC7AC64)],
                          ),
                          borderRadius: BorderRadius.circular(6.r),
                          border: Border.all(
                            color: const Color(0xFF8C7536),
                            width: 0.8,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.nfc_rounded,
                            color: const Color(0xFF5C4C1E),
                            size: 16.r,
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Icon(
                        Icons.wifi_tethering_rounded,
                        color: Colors.white70,
                        size: 18.r,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (isDefault) ...[
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentLime,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 12.r,
                                color: AppColors.primaryDark,
                              ),
                              SizedBox(width: 3.w),
                              Text(
                                'PRIMARY',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.5.sp,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primaryDark,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8.w),
                      ],
                      _buildBrandBadge(card.brand),
                    ],
                  ),
                ],
              ),

              // Card Number Masked
              Text(
                '••••  ••••  ••••  ${card.lastFourDigits}',
                style: GoogleFonts.shareTechMono(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.5,
                ),
              ),

              // Bottom Info: Cardholder Name, Expiry & Limit
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CARDHOLDER',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFFC7CBC0),
                          fontSize: 9.5.sp,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        card.cardholderName.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'EXPIRES',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFFC7CBC0),
                          fontSize: 9.5.sp,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        card.expiryDate,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // Frozen Overlay if Frozen
          if (isFrozen)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF001A24).withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(22.r),
                ),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.cyan.shade900.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: Colors.cyanAccent, width: 1.2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.ac_unit_rounded,
                          color: Colors.cyanAccent,
                          size: 16.r,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'CARD FROZEN • BLOCKED',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.cyanAccent,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBrandBadge(CardBrand brand) {
    String label = 'VISA';
    Color badgeBg = Colors.white.withValues(alpha: 0.2);
    if (brand == CardBrand.mastercard) {
      label = 'MASTERCARD';
    } else if (brand == CardBrand.amex) {
      label = 'AMEX';
    } else if (brand == CardBrand.discover) {
      label = 'DISCOVER';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.white30, width: 0.8),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 11.sp,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildCarouselPageIndicators(int count) {
    if (count <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isSelected = index == _selectedCardCarouselIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          width: isSelected ? 22.w : 7.w,
          height: 6.h,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.borderUnselected,
            borderRadius: BorderRadius.circular(3.r),
          ),
        );
      }),
    );
  }

  Widget _buildCardQuickActions(List<PaymentCard> cards) {
    if (cards.isEmpty) return const SizedBox.shrink();

    final safeIndex = _selectedCardCarouselIndex.clamp(0, cards.length - 1);
    final activeCard = cards[safeIndex];
    final isFrozen = activeCard.isFrozen;
    final isDefault = activeCard.isDefault;

    return Row(
      children: [
        // 1. Set as Default Action
        if (!isDefault)
          Expanded(
            child: _buildActionButton(
              icon: Icons.star_outline_rounded,
              label: 'Make Default',
              onTap: () {
                HapticFeedback.lightImpact();
                final cardIdInt = int.tryParse(activeCard.id);
                final cardEntities = context.read<CardCubit>().cards;
                final entity = cardEntities.firstWhere(
                  (c) => c.id == cardIdInt,
                  orElse: () => cardEntities.first,
                );
                context.read<CardCubit>().selectCard(entity);
                DynamicIslandToast.showSuccess(
                  context,
                  'Card ending in ${activeCard.lastFourDigits} set as default.',
                );
              },
            ),
          )
        else
          Expanded(
            child: _buildActionButton(
              icon: Icons.verified_rounded,
              label: 'Default Card',
              isHighlight: true,
              onTap: () {},
            ),
          ),
        SizedBox(width: 10.w),

        // 2. Freeze / Unfreeze
        Expanded(
          child: _buildActionButton(
            icon: isFrozen ? Icons.lock_open_rounded : Icons.ac_unit_rounded,
            label: isFrozen ? 'Unfreeze' : 'Freeze Card',
            onTap: () {
              HapticFeedback.mediumImpact();
              final cardIdInt = int.tryParse(activeCard.id);
              if (cardIdInt != null) {
                context
                    .read<CardCubit>()
                    .toggleFreezeCard(cardIdInt, !isFrozen);
              }
            },
          ),
        ),
        SizedBox(width: 10.w),

        // 3. Card Details
        Expanded(
          child: _buildActionButton(
            icon: Icons.info_outline_rounded,
            label: 'Details',
            onTap: () => _showCardDetailsModal(context, activeCard),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isHighlight = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: isHighlight ? AppColors.accentLime : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isHighlight ? AppColors.primary : AppColors.borderUnselected,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20.r,
              color: isHighlight ? AppColors.primaryDark : AppColors.primary,
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: isHighlight
                    ? AppColors.primaryDark
                    : AppColors.textHeadline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardListTile(BuildContext context, PaymentCard card) {
    final isDefault = card.isDefault;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: isDefault ? AppColors.primary : AppColors.borderUnselected,
          width: isDefault ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Card Mini Gradient Icon Box
          Container(
            width: 50.w,
            height: 36.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: card.brand == CardBrand.visa
                    ? [const Color(0xFF0D253F), const Color(0xFF1E50A2)]
                    : card.brand == CardBrand.mastercard
                    ? [const Color(0xFF1A1A2E), const Color(0xFF8B1E26)]
                    : card.brand == CardBrand.amex
                    ? [const Color(0xFF2C3E50), const Color(0xFF4CA1AF)]
                    : [const Color(0xFF3E2723), const Color(0xFFD84315)],
              ),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Center(
              child: Text(
                card.brand == CardBrand.visa
                    ? 'VISA'
                    : card.brand == CardBrand.mastercard
                    ? 'MC'
                    : card.brand == CardBrand.amex
                    ? 'AMEX'
                    : 'DISC',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          SizedBox(width: 14.w),

          // Card Name & Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${card.brand.name.toUpperCase()} •••• ${card.lastFourDigits}',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textHeadline,
                        ),
                      ),
                    ),
                    if (isDefault) ...[
                      SizedBox(width: 6.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentLime,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          'DEFAULT',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 3.h),
                Text(
                  'Expires ${card.expiryDate} • ${card.cardholderName}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.sp,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Actions Menu
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              color: AppColors.textMuted,
              size: 20.r,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            onSelected: (value) async {
              if (value == 'default') {
                final cardIdInt = int.tryParse(card.id);
                final cardEntities = context.read<CardCubit>().cards;
                final entity = cardEntities.firstWhere(
                  (c) => c.id == cardIdInt,
                  orElse: () => cardEntities.first,
                );
                context.read<CardCubit>().selectCard(entity);
                DynamicIslandToast.showSuccess(
                  context,
                  'Card ending in ${card.lastFourDigits} set as default.',
                );
              } else if (value == 'freeze') {
                DynamicIslandToast.showSuccess(
                  context,
                  card.isFrozen
                      ? 'Card unfrozen. Online payments active.'
                      : 'Card temporarily frozen.',
                );
              } else if (value == 'details') {
                _showCardDetailsModal(context, card);
              } else if (value == 'delete') {
                _confirmDeleteCard(context, card);
              }
            },
            itemBuilder: (context) => [
              if (!isDefault)
                PopupMenuItem(
                  value: 'default',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        'Set as Default',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'freeze',
                child: Row(
                  children: [
                    Icon(
                      card.isFrozen
                          ? Icons.lock_open_rounded
                          : Icons.ac_unit_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      card.isFrozen ? 'Unfreeze Card' : 'Freeze Card',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'details',
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      'Card Details',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red,
                      size: 18,
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      'Remove Card',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddCardListTile(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToAddCard(context),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.35),
            width: 1.4,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: AppColors.cardSelectedBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_card_rounded,
                color: AppColors.primary,
                size: 22.r,
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add New Credit / Debit Card',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Visa, Mastercard, American Express, Discover',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.sp,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.primary,
              size: 16.r,
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildAlternativeMethodTile({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    String? badgeText,
  }) {
    final isSelected = _selectedAlternativeMethod == id;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedAlternativeMethod = id;
        });
      },
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderUnselected,
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.cardSelectedBg
                    : const Color(0xFFF6F8F3),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22.r),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textHeadline,
                          ),
                        ),
                      ),
                      if (badgeText != null) ...[
                        SizedBox(width: 6.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F5EC),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            badgeText,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.sp,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isSelected ? AppColors.primary : AppColors.radioUnselected,
              size: 22.r,
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildServicePaymentTile({
    required String title,
    required String provider,
    required String amount,
    required String dueDate,
    required String installmentInfo,
    required String status,
    required IconData icon,
    bool isPaid = false,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.borderUnselected, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: AppColors.cardSelectedBg,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22.r),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textHeadline,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      provider,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.sp,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amount,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textHeadline,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    dueDate,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5.sp,
                      color: isPaid
                          ? Colors.green.shade700
                          : AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12.h),
          const Divider(height: 1, color: AppColors.borderUnselected),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                installmentInfo,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (!isPaid) {
                    DynamicIslandToast.showSuccess(
                      context,
                      'Processing payment for $title...',
                    );
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: isPaid ? const Color(0xFFF2F5EC) : AppColors.primary,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    isPaid ? 'Receipt' : 'Pay Now',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w700,
                      color: isPaid ? AppColors.primary : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCardDetailsModal(BuildContext context, PaymentCard card) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: AppColors.borderUnselected,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 18.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Card Details',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textHeadline,
                      ),
                    ),
                    if (card.isDefault)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 3.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentLime,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          'DEFAULT',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 16.h),
                _buildDetailRow('Cardholder Name', card.cardholderName),
                const Divider(),
                _buildDetailRow(
                  'Card Number',
                  '•••• •••• •••• ${card.lastFourDigits}',
                ),
                const Divider(),
                _buildDetailRow('Card Network', card.brand.name.toUpperCase()),
                const Divider(),
                _buildDetailRow('Expiry Date', card.expiryDate),
                const Divider(),
                _buildDetailRow(
                  'Card Status',
                  card.isFrozen ? 'Frozen (Blocked)' : 'Active & Verified',
                ),
                SizedBox(height: 24.h),
                SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonBackground,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25.r),
                      ),
                    ),
                    child: Text(
                      'Done',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
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
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5.sp,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5.sp,
              color: AppColors.textHeadline,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCard(BuildContext context, PaymentCard card) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.borderUnselected,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(height: 20.h),
                Container(
                  padding: EdgeInsets.all(14.r),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.credit_card_off_rounded,
                    color: Colors.red.shade600,
                    size: 32.r,
                  ),
                ),
                SizedBox(height: 14.h),
                Text(
                  'Remove Card?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textHeadline,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Are you sure you want to remove card ending in ${card.lastFourDigits} (${card.cardholderName})?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5.sp,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 24.h),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50.h,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppColors.borderUnselected,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25.r),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textHeadline,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: SizedBox(
                        height: 50.h,
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.of(ctx).pop();
                            HapticFeedback.lightImpact();
                            final cardIdInt = int.tryParse(card.id);
                            if (cardIdInt != null) {
                              await context.read<CardCubit>().deleteCard(cardIdInt);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25.r),
                            ),
                          ),
                          child: Text(
                            'Remove',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
              ],
            ),
          ),
        );
      },
    );
  }
}
