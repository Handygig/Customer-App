import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer_app/core/constants/app_assets.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/utils/extensions.dart';
import 'package:customer_app/src/presentation/blocs/auth/auth_bloc.dart';
import 'package:customer_app/src/presentation/blocs/auth/auth_event.dart';
import 'package:customer_app/src/presentation/blocs/auth/auth_state.dart';
import 'package:customer_app/src/presentation/screens/auth/customer_details_screen.dart';
import 'package:customer_app/src/presentation/screens/auth/widgets/auth_animated_sheet.dart';
import 'package:customer_app/src/presentation/screens/auth/widgets/auth_back_button.dart';
import 'package:customer_app/src/presentation/screens/auth/widgets/auth_header_banner.dart';
import 'package:customer_app/src/presentation/screens/auth/widgets/auth_primary_button.dart';
import 'package:customer_app/src/presentation/screens/main_navigation_screen.dart';
import 'package:customer_app/src/presentation/widgets/dynamic_island_toast.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;
  final int? forceResendingToken;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
    this.forceResendingToken,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  late String _verificationId;
  int? _forceResendingToken;
  int _resendCountdown = 30;
  Timer? _timer;
  bool _canResend = false;
  bool _isComplete = false;
  String? _submittedCode;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
    _forceResendingToken = widget.forceResendingToken;
    _startResendTimer();

    for (final node in _focusNodes) {
      node.addListener(_refreshFocusState);
    }

    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted) _focusNodes.first.requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.removeListener(_refreshFocusState);
      node.dispose();
    }
    super.dispose();
  }

  void _refreshFocusState() {
    if (mounted) setState(() {});
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() {
      _resendCountdown = 30;
      _canResend = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_resendCountdown > 1) {
        setState(() => _resendCountdown--);
      } else {
        setState(() {
          _resendCountdown = 0;
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  String get _otpCode =>
      _controllers.map((controller) => controller.text).join();

  void _onDigitEntered(int index, String value) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    } else if (index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    final complete = _otpCode.length == 6;
    if (complete != _isComplete) {
      setState(() => _isComplete = complete);
    }

    if (complete) _verifyOtp();
  }

  void _verifyOtp() {
    final code = _otpCode;
    if (code.length != 6 || _submittedCode == code) return;

    HapticFeedback.mediumImpact();
    _submittedCode = code;
    context.read<AuthBloc>().add(
      VerifyOtpRequested(verificationId: _verificationId, smsCode: code),
    );
  }

  void _resendOtp() {
    if (!_canResend) return;
    HapticFeedback.lightImpact();
    context.read<AuthBloc>().add(
      ResendOtpRequested(
        phoneNumber: widget.phoneNumber,
        forceResendingToken: _forceResendingToken,
      ),
    );
  }

  void _clearOtpAfterError() {
    for (final controller in _controllers) {
      controller.clear();
    }
    _submittedCode = null;
    _isComplete = false;
    _focusNodes.first.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (_, state) =>
          state is AuthOtpResent ||
          state is AuthAuthenticated ||
          (state is AuthFailure &&
              (state.operation == AuthOperation.verifyOtp ||
                  state.operation == AuthOperation.resendOtp)),
      listener: (context, state) {
        if (state is AuthOtpResent) {
          _verificationId = state.session.verificationId;
          _forceResendingToken = state.session.forceResendingToken;
          _startResendTimer();
          DynamicIslandToast.showSuccess(
            context,
            context.loc.codeSentSuccess,
          );
          return;
        }

        if (state is AuthAuthenticated) {
          final needsProfile =
              state.result.isNewUser || !state.result.isProfileComplete;

          if (needsProfile) {
            Navigator.of(context).pushAndRemoveUntil(
              CupertinoPageRoute(builder: (_) => const CustomerDetailsScreen()),
              (route) => route.isFirst,
            );
          } else {
            Navigator.of(context).pushAndRemoveUntil(
              CupertinoPageRoute(builder: (_) => const MainNavigationScreen()),
              (_) => false,
            );
          }
          return;
        }

        if (state is AuthFailure) {
          _submittedCode = null;
          DynamicIslandToast.showError(context, state.message);
          if (state.operation == AuthOperation.verifyOtp) {
            _clearOtpAfterError();
          }
        }
      },
      builder: (context, state) {
        final verifying =
            state is AuthLoading && state.operation == AuthOperation.verifyOtp;
        final resending =
            state is AuthLoading && state.operation == AuthOperation.resendOtp;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
          ),
          child: Scaffold(
            backgroundColor: AppColors.darkHeaderBg,
            body: Stack(
              children: [
                const AuthHeaderBanner(
                  assetPath: AppAssets.otpHeader,
                  fallbackIcon: Icons.mark_email_read_rounded,
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
                                  context.loc.verificationTitle,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 30.sp,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textHeadline,
                                    height: 1.15,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                SizedBox(height: 10.h),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text.rich(
                                        TextSpan(
                                          text: context.loc.verificationSubtitle,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.textSecondary,
                                            height: 1.4,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: widget.phoneNumber,
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        AppColors.textHeadline,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => Navigator.of(context).pop(),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10.w,
                                          vertical: 4.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.08,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10.r,
                                          ),
                                        ),
                                        child: Text(
                                          context.loc.edit,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12.5.sp,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 28.h),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: List.generate(
                                    6,
                                    (index) => _buildOtpBox(index),
                                  ),
                                ),
                                SizedBox(height: 24.h),
                                Center(
                                  child: _canResend
                                      ? InkWell(
                                          onTap: resending ? null : _resendOtp,
                                          borderRadius: BorderRadius.circular(
                                            8.r,
                                          ),
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8.w,
                                              vertical: 4.h,
                                            ),
                                            child: Text(
                                              resending
                                                  ? context.loc.loading
                                                  : '${context.loc.didNotReceiveCode}${context.loc.resendCode}',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                    fontSize: 13.5.sp,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.primary,
                                                  ),
                                            ),
                                          ),
                                        )
                                      : Text(
                                          context.loc.resendCodeIn(
                                            _resendCountdown,
                                          ),
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13.5.sp,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                ),
                                const Spacer(),
                                Padding(
                                  padding: EdgeInsets.only(
                                    bottom: 20.h,
                                    top: 16.h,
                                  ),
                                  child: AuthPrimaryButton(
                                    label: context.loc.verifyAndContinue,
                                    onPressed: _verifyOtp,
                                    enabled: _isComplete,
                                    loading: verifying,
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

  Widget _buildOtpBox(int index) {
    final controller = _controllers[index];
    final focusNode = _focusNodes[index];
    final focused = focusNode.hasFocus;
    final hasValue = controller.text.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 44.w,
      height: 52.h,
      decoration: BoxDecoration(
        color: focused ? Colors.white : const Color(0xFFF6F8F3),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: focused
              ? AppColors.primary
              : (hasValue
                    ? AppColors.primary.withValues(alpha: 0.5)
                    : AppColors.borderUnselected),
          width: focused ? 2 : 1.2,
        ),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 12,
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
      child: Center(
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(1),
          ],
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.textHeadline,
          ),
          onChanged: (value) => _onDigitEntered(index, value),
          decoration: const InputDecoration(
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }
}
