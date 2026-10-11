import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/src/domain/entities/profile/payment_card.dart';
import 'package:customer_app/src/presentation/cubits/payments/card_cubit.dart';
import 'package:customer_app/src/presentation/widgets/dynamic_island_toast.dart';

class AddCardScreen extends StatefulWidget {
  final PaymentCard? cardToEdit;

  const AddCardScreen({super.key, this.cardToEdit});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardHolderController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final FocusNode _cvvFocusNode = FocusNode();

  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  bool _isDefault = true;
  CardBrand _detectedBrand = CardBrand.visa;
  bool _isSubmitting = false;
  bool _obscureCvv = true;

  @override
  void initState() {
    super.initState();
    _cardNumberController.addListener(_onCardNumberChanged);
    _cardHolderController.addListener(() => setState(() {}));
    _expiryController.addListener(() => setState(() {}));
    _cvvController.addListener(() => setState(() {}));

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutCubic),
    );

    _cvvFocusNode.addListener(() {
      if (_cvvFocusNode.hasFocus) {
        _flipController.forward();
      } else {
        _flipController.reverse();
      }
    });

    if (widget.cardToEdit != null) {
      final card = widget.cardToEdit!;
      _cardNumberController.text = '•••• •••• •••• ${card.lastFourDigits}';
      _cardHolderController.text = card.cardholderName;
      _expiryController.text = card.expiryDate;
      _cvvController.text = '123';
      _isDefault = card.isDefault;
      _detectedBrand = card.brand;
    }
  }

  @override
  void dispose() {
    _cvvFocusNode.dispose();
    _flipController.dispose();
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  void _onCardNumberChanged() {
    final clean = _cardNumberController.text.replaceAll(' ', '');
    CardBrand brand = CardBrand.visa;
    if (clean.startsWith('5') || clean.startsWith('2')) {
      brand = CardBrand.mastercard;
    } else if (clean.startsWith('3')) {
      brand = CardBrand.amex;
    } else if (clean.startsWith('6')) {
      brand = CardBrand.discover;
    } else {
      brand = CardBrand.visa;
    }

    if (brand != _detectedBrand) {
      setState(() => _detectedBrand = brand);
    } else {
      setState(() {});
    }
  }

  void _fillDemoCard(String number, String holder, String expiry, String cvv) {
    HapticFeedback.lightImpact();
    setState(() {
      _cardNumberController.text = number;
      _cardHolderController.text = holder;
      _expiryController.text = expiry;
      _cvvController.text = cvv;
    });
  }

  Future<void> _submitCard() async {
    final rawNumber = _cardNumberController.text.replaceAll(' ', '');
    final name = _cardHolderController.text.trim();
    final expiry = _expiryController.text.trim();
    final cvv = _cvvController.text.trim();

    if (widget.cardToEdit == null && rawNumber.length < 15) {
      _showErrorSnackBar('Please enter a valid 15-16 digit card number.');
      return;
    }

    if (name.isEmpty) {
      _showErrorSnackBar('Please enter the cardholder name.');
      return;
    }

    if (expiry.length < 5 || !expiry.contains('/')) {
      _showErrorSnackBar('Please enter a valid expiry date (MM/YY).');
      return;
    }

    if (cvv.length < 3) {
      _showErrorSnackBar('Please enter a valid 3 or 4 digit CVV code.');
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    final isEditing = widget.cardToEdit != null;
    final lastFour = rawNumber.length >= 4
        ? rawNumber.substring(rawNumber.length - 4)
        : (isEditing ? widget.cardToEdit!.lastFourDigits : '4920');

    final maskedCardNumber = '•••• •••• •••• $lastFour';

    final success = await context.read<CardCubit>().addCard(
          cardType: _detectedBrand.name,
          maskedCardNumber: maskedCardNumber,
          expiryDate: expiry,
          cardHolderName: name,
        );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        DynamicIslandToast.showSuccess(
          context,
          isEditing
              ? '${_detectedBrand.name.toUpperCase()} Card Updated'
              : '${_detectedBrand.name.toUpperCase()} Card Added Successfully',
        );
        Navigator.of(context).pop();
      }
    }
  }

  void _showErrorSnackBar(String message) {
    DynamicIslandToast.showError(context, message);
  }

  // ignore: unused_element
  List<int> _getBrandGradientColors(CardBrand brand) {
    switch (brand) {
      case CardBrand.visa:
        return [0xFF0D253F, 0xFF1E50A2];
      case CardBrand.mastercard:
        return [0xFF1A1A2E, 0xFF8B1E26];
      case CardBrand.amex:
        return [0xFF2C3E50, 0xFF4CA1AF];
      case CardBrand.discover:
        return [0xFF3E2723, 0xFFD84315];
    }
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
          widget.cardToEdit != null ? 'Edit Payment Card' : 'Add Payment Card',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Live Interactive Credit Card Preview
            _buildInteractiveCardPreview(),
            SizedBox(height: 18.h),

            // 2. Demo Card Quick-Fill Chips
            Text(
              'Quick Demo Card Fill:',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
            SizedBox(height: 8.h),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildDemoChip(
                    'Visa Card',
                    () => _fillDemoCard(
                      '4242 8821 9902 4920',
                      'ALEX JOHNSON',
                      '08/28',
                      '842',
                    ),
                  ),
                  SizedBox(width: 8.w),
                  _buildDemoChip(
                    'Mastercard',
                    () => _fillDemoCard(
                      '5520 3491 8812 7731',
                      'ALEX JOHNSON',
                      '11/27',
                      '391',
                    ),
                  ),
                  SizedBox(width: 8.w),
                  _buildDemoChip(
                    'Amex Platinum',
                    () => _fillDemoCard(
                      '3782 8224 9910 3049',
                      'ALEX JOHNSON',
                      '05/29',
                      '4928',
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),

            // 3. Card Number Field
            _buildInputField(
              label: 'Card Number',
              controller: _cardNumberController,
              hint: '4111 2222 3333 4920',
              icon: Icons.credit_card_rounded,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _CardNumberFormatter(),
                LengthLimitingTextInputFormatter(19),
              ],
              suffix: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                margin: EdgeInsets.only(right: 8.w),
                decoration: BoxDecoration(
                  color: AppColors.cardSelectedBg,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  _detectedBrand.name.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // 4. Cardholder Name Field
            _buildInputField(
              label: 'Cardholder Name',
              controller: _cardHolderController,
              hint: 'e.g. ALEX JOHNSON',
              icon: Icons.person_outline_rounded,
              textCapitalization: TextCapitalization.characters,
            ),
            SizedBox(height: 16.h),

            // 5. Expiry Date & CVV Row
            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    label: 'Expiry Date',
                    controller: _expiryController,
                    hint: 'MM/YY',
                    icon: Icons.calendar_today_rounded,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _CardExpiryFormatter(),
                      LengthLimitingTextInputFormatter(5),
                    ],
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: _buildInputField(
                    label: 'CVV / CVC',
                    controller: _cvvController,
                    focusNode: _cvvFocusNode,
                    hint: '123',
                    icon: Icons.lock_outline_rounded,
                    keyboardType: TextInputType.number,
                    obscureText: _obscureCvv,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    suffix: IconButton(
                      icon: Icon(
                        _obscureCvv
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: AppColors.textMuted,
                        size: 20.r,
                      ),
                      onPressed: () =>
                          setState(() => _obscureCvv = !_obscureCvv),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),

            // 6. Set as Default Switch Tile
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(
                  color: AppColors.borderUnselected,
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF7F8F0),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.star_rounded,
                      color: AppColors.primary,
                      size: 22.r,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Set as Default Card',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textHeadline,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Use automatically for bookings and subscriptions',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5.sp,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _isDefault,
                    activeTrackColor: AppColors.primary,
                    onChanged: (val) => setState(() => _isDefault = val),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32.h),

            // 7. Save Card Button
            SizedBox(
              width: double.infinity,
              height: 54.h,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitCard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(27.r),
                  ),
                  elevation: 3,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.lock_outline_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            widget.cardToEdit != null
                                ? 'Update Card Details'
                                : 'Save & Verify Card',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            SizedBox(height: 16.h),

            // Security disclaimer
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 16.r,
                    color: AppColors.textMuted,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    '256-Bit Encrypted & PCI-DSS Compliant',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoChip(String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.4),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flash_on_rounded, size: 14.r, color: AppColors.primary),
            SizedBox(width: 4.w),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveCardPreview() {
    final numberText = _cardNumberController.text.trim();
    final formattedNumber = numberText.isEmpty
        ? '••••  ••••  ••••  ••••'
        : numberText;

    List<Color> gradientColors = [
      const Color(0xFF0D253F),
      const Color(0xFF1E50A2),
    ];
    if (_detectedBrand == CardBrand.mastercard) {
      gradientColors = [const Color(0xFF1A1A2E), const Color(0xFF8B1E26)];
    } else if (_detectedBrand == CardBrand.amex) {
      gradientColors = [const Color(0xFF2C3E50), const Color(0xFF4CA1AF)];
    } else if (_detectedBrand == CardBrand.discover) {
      gradientColors = [const Color(0xFF3E2723), const Color(0xFFD84315)];
    }

    return AnimatedBuilder(
      animation: _flipAnimation,
      builder: (context, child) {
        final double angle = _flipAnimation.value * math.pi;
        final bool isBack = angle >= math.pi / 2;

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          alignment: Alignment.center,
          child: isBack
              ? Transform(
                  transform: Matrix4.identity()..rotateY(math.pi),
                  alignment: Alignment.center,
                  child: _buildCardBackView(gradientColors),
                )
              : _buildCardFrontView(gradientColors, formattedNumber),
        );
      },
    );
  }

  Widget _buildCardFrontView(
    List<Color> gradientColors,
    String formattedNumber,
  ) {
    return Container(
      width: double.infinity,
      height: 205.h,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        border: Border.all(
          color: _isDefault
              ? AppColors.accentLime.withValues(alpha: 0.5)
              : Colors.white24,
          width: _isDefault ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha: 0.4),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Row: Chip, Contactless NFC & Brand
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
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
                  if (_isDefault) ...[
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
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 9.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.white30, width: 0.8),
                    ),
                    child: Text(
                      _detectedBrand.name.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Card Number
          Text(
            formattedNumber,
            style: GoogleFonts.shareTechMono(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.2,
            ),
          ),

          // Bottom Info
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
                    _cardHolderController.text.isEmpty
                        ? 'FULL NAME'
                        : _cardHolderController.text.toUpperCase(),
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
                    _expiryController.text.isEmpty
                        ? 'MM/YY'
                        : _expiryController.text,
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
    );
  }

  Widget _buildCardBackView(List<Color> gradientColors) {
    final cvvText = _cvvController.text.isEmpty ? '•••' : _cvvController.text;

    return Container(
      width: double.infinity,
      height: 205.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        border: Border.all(
          color: _isDefault
              ? AppColors.accentLime.withValues(alpha: 0.5)
              : Colors.white24,
          width: _isDefault ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha: 0.4),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 22.h),

          // Black Magnetic Stripe
          Container(
            width: double.infinity,
            height: 40.h,
            color: const Color(0xFF1E1E1E),
          ),
          SizedBox(height: 16.h),

          // Signature Panel & CVV Box
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.w),
            child: Row(
              children: [
                // Signature strip
                Expanded(
                  child: Container(
                    height: 36.h,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(6.r),
                        bottomLeft: Radius.circular(6.r),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'AUTHORIZED SIGNATURE',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
                // CVV White Box
                Container(
                  width: 65.w,
                  height: 36.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(6.r),
                      bottomRight: Radius.circular(6.r),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _obscureCvv ? ('•' * cvvText.length) : cvvText,
                      style: GoogleFonts.shareTechMono(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textHeadline,
                        letterSpacing: 1.8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Bottom Info Row
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: Colors.white70,
                      size: 14.r,
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      'CVV SECURITY CODE',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFFC7CBC0),
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                Text(
                  _detectedBrand.name.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white70,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
    Widget? suffix,
    FocusNode? focusNode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textHeadline,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.borderUnselected, width: 1.2),
          ),
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          child: Row(
            children: [
              Icon(icon, size: 20.r, color: AppColors.primary),
              SizedBox(width: 10.w),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: keyboardType,
                  obscureText: obscureText,
                  textCapitalization: textCapitalization,
                  inputFormatters: inputFormatters,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textHeadline,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: AppColors.textMuted,
                      fontSize: 14.sp,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 14.h),
                  ),
                ),
              ),
              ?suffix,
            ],
          ),
        ),
      ],
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.replaceAll(' ', '');
    if (text.length > 16) {
      text = text.substring(0, 16);
    }
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }
    final string = buffer.toString();
    return TextEditingValue(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class _CardExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.replaceAll('/', '').replaceAll(' ', '');
    if (text.length > 4) {
      text = text.substring(0, 4);
    }
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i == 2) {
        buffer.write('/');
      }
      buffer.write(text[i]);
    }
    final string = buffer.toString();
    return TextEditingValue(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
