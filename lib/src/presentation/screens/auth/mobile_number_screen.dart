import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer_app/core/constants/app_assets.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/src/data/models/auth/country_code_model.dart';
import 'package:customer_app/src/presentation/blocs/auth/auth_bloc.dart';
import 'package:customer_app/src/presentation/blocs/auth/auth_event.dart';
import 'package:customer_app/src/presentation/blocs/auth/auth_state.dart';
import 'package:customer_app/src/presentation/screens/auth/otp_verification_screen.dart';
import 'package:customer_app/src/presentation/screens/auth/widgets/auth_animated_sheet.dart';
import 'package:customer_app/src/presentation/screens/auth/widgets/auth_back_button.dart';
import 'package:customer_app/src/presentation/screens/auth/widgets/auth_header_banner.dart';
import 'package:customer_app/src/presentation/screens/auth/widgets/auth_primary_button.dart';
import 'package:customer_app/src/presentation/screens/auth/widgets/country_picker_sheet.dart';
import 'package:customer_app/src/presentation/widgets/dynamic_island_toast.dart';

class MobileNumberScreen extends StatefulWidget {
  const MobileNumberScreen({super.key});

  @override
  State<MobileNumberScreen> createState() => _MobileNumberScreenState();
}

class _MobileNumberScreenState extends State<MobileNumberScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();

  CountryCode _selectedCountry = CountryCode.supported.first;
  List<CountryCode> _countryList = CountryCode.supported;
  bool _isLoadingCountries = false;
  bool _isValidNumber = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _phoneFocusNode.addListener(_handleFocusChange);
    _phoneController.addListener(_validatePhone);
    _loadCountryCodes();
  }

  @override
  void dispose() {
    _phoneFocusNode.removeListener(_handleFocusChange);
    _phoneController.removeListener(_validatePhone);
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() => _isFocused = _phoneFocusNode.hasFocus);
    }
  }

  Future<void> _loadCountryCodes() async {
    setState(() => _isLoadingCountries = true);
    final countries = await CountryCode.fetchFromApi();
    if (!mounted) return;
    setState(() {
      _countryList = countries;
      _isLoadingCountries = false;
    });
  }

  void _validatePhone() {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    final valid = digits.length >= 6 && digits.length <= 14;
    if (valid != _isValidNumber && mounted) {
      setState(() => _isValidNumber = valid);
    }
  }

  String get _fullPhoneNumber {
    var digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');

    // A local Sri Lankan number is commonly typed with a leading zero.
    // Firebase expects E.164, so +94 077... must become +9477....
    if (_selectedCountry.code == '+94' && digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    return '${_selectedCountry.code}$digits';
  }

  Future<void> _showCountryPicker() async {
    HapticFeedback.selectionClick();
    final selected = await CountryPickerSheet.show(
      context: context,
      countries: _countryList,
      selectedCountry: _selectedCountry,
      loading: _isLoadingCountries,
    );

    if (selected != null && mounted) {
      setState(() => _selectedCountry = selected);
      _validatePhone();
    }
  }

  void _handleSendCode() {
    if (!_isValidNumber) return;
    HapticFeedback.mediumImpact();
    context.read<AuthBloc>().add(SendOtpRequested(_fullPhoneNumber));
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (_, state) =>
          state is AuthOtpSent ||
          (state is AuthFailure && state.operation == AuthOperation.sendOtp),
      listener: (context, state) {
        if (state is AuthOtpSent) {
          Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (_) => OtpVerificationScreen(
                phoneNumber: state.phoneNumber,
                verificationId: state.session.verificationId,
                forceResendingToken: state.session.forceResendingToken,
              ),
            ),
          );
        } else if (state is AuthFailure) {
          DynamicIslandToast.showError(context, state.message);
        }
      },
      builder: (context, state) {
        final sending =
            state is AuthLoading && state.operation == AuthOperation.sendOtp;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
          ),
          child: Scaffold(
            backgroundColor: AppColors.darkHeaderBg,
            body: Stack(
              children: [
                const AuthHeaderBanner(
                  assetPath: AppAssets.phoneHeader,
                  fallbackIcon: Icons.phone_android_rounded,
                ),
                const AuthBackButton(),
                AuthAnimatedSheet(
                  top: (screenHeight * 0.33).clamp(180.0, 320.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 16.h),
                                Text(
                                  'Enter your\nMobile Number',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 30.sp,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textHeadline,
                                    height: 1.15,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                SizedBox(height: 10.h),
                                Text(
                                  'We will send you a 6-digit verification code to confirm your number.',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14.5.sp,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                                SizedBox(height: 28.h),
                                _buildPhoneInputField(),
                                SizedBox(height: 14.h),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.lock_outline_rounded,
                                      size: 15.r,
                                      color: AppColors.textSecondary,
                                    ),
                                    SizedBox(width: 6.w),
                                    Text(
                                      'Your info is safe and secured with us',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.5.sp,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12.h),
                                  child: Text.rich(
                                    TextSpan(
                                      text:
                                          'By continuing, you agree to JobHive\'s ',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textSecondary,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: 'Terms of Service',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                        const TextSpan(text: ' & '),
                                        TextSpan(
                                          text: 'Privacy Policy',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(
                                    bottom: 20.h,
                                    top: 4.h,
                                  ),
                                  child: AuthPrimaryButton(
                                    label: 'Send Code',
                                    onPressed: _handleSendCode,
                                    enabled: _isValidNumber,
                                    loading: sending,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
    );
  }

  Widget _buildPhoneInputField() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _isFocused ? Colors.white : const Color(0xFFF6F8F3),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: _isFocused
              ? AppColors.primary
              : (_isValidNumber
                    ? AppColors.primary.withValues(alpha: 0.6)
                    : AppColors.borderUnselected),
          width: _isFocused ? 2 : 1.2,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: Row(
        children: [
          InkWell(
            onTap: _showCountryPicker,
            borderRadius: BorderRadius.circular(12.r),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 10.h),
              child: Row(
                children: [
                  Text(
                    _selectedCountry.flag,
                    style: TextStyle(fontSize: 22.sp),
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    _selectedCountry.code,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHeadline,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20.r,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: 28.h,
            width: 1.2,
            margin: EdgeInsets.symmetric(horizontal: 10.w),
            color: const Color(0xFFE2E4DE),
          ),
          Expanded(
            child: TextField(
              controller: _phoneController,
              focusNode: _phoneFocusNode,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(14),
              ],
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textHeadline,
                letterSpacing: 1.2,
              ),
              decoration: InputDecoration(
                hintText: '77 123 4567',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                  letterSpacing: 0.5,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12.h),
              ),
            ),
          ),
          if (_phoneController.text.isNotEmpty)
            GestureDetector(
              onTap: _phoneController.clear,
              child: Padding(
                padding: EdgeInsets.all(4.r),
                child: Icon(
                  _isValidNumber
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: _isValidNumber
                      ? AppColors.primary
                      : Colors.grey.shade400,
                  size: 22.r,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
