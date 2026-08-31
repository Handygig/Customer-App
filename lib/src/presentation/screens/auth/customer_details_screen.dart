import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:customer_app/core/constants/app_assets.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/src/presentation/blocs/auth/auth_bloc.dart';
import 'package:customer_app/src/presentation/blocs/auth/auth_event.dart';
import 'package:customer_app/src/presentation/blocs/auth/auth_state.dart';
import 'package:customer_app/src/presentation/screens/auth/add_properties_screen.dart';
import 'package:customer_app/src/presentation/screens/auth/widgets/auth_back_button.dart';
import 'package:customer_app/src/presentation/screens/auth/widgets/auth_header_banner.dart';
import 'package:customer_app/src/presentation/screens/auth/widgets/auth_primary_button.dart';
import 'package:customer_app/src/presentation/widgets/dynamic_island_toast.dart';

enum Gender { male, female }

class CustomerDetailsScreen extends StatefulWidget {
  const CustomerDetailsScreen({super.key});

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  final FocusNode _firstNameFocus = FocusNode();
  final FocusNode _lastNameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();

  Gender _selectedGender = Gender.male;
  String? _profileImagePath;
  bool _formValid = false;

  double? _sheetTop;
  bool _isDragging = false;
  bool _hasCalculatedDefaultTop = false;
  double _defaultTop = 220;

  late AnimationController _animController;
  late Animation<Offset> _sheetSlideAnimation;
  late Animation<double> _sheetFadeAnimation;
  late Animation<Offset> _contentSlideAnimation;
  late Animation<double> _contentFadeAnimation;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _sheetSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0, 0.85, curve: Curves.easeOutCubic),
    ));

    _sheetFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0, 0.60, curve: Curves.easeOut),
      ),
    );

    _contentSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.20, 1, curve: Curves.easeOutCubic),
    ));

    _contentFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.20, 0.85, curve: Curves.easeOut),
      ),
    );

    _animController.forward();
    _firstNameController.addListener(_validateForm);
    _lastNameController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _firstNameController.removeListener(_validateForm);
    _lastNameController.removeListener(_validateForm);
    _emailController.removeListener(_validateForm);
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _emailFocus.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _validateForm() {
    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    final valid = first.isNotEmpty && last.isNotEmpty && emailRegex.hasMatch(email);

    if (valid != _formValid && mounted) {
      setState(() => _formValid = valid);
    }
  }

  Future<void> _pickProfileImage(ImageSource source) async {
    try {
      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 88,
        maxWidth: 1200,
      );
      if (image != null && mounted) {
        setState(() => _profileImagePath = image.path);
      }
    } catch (_) {
      if (mounted) {
        DynamicIslandToast.showError(
          context,
          'Unable to open the image picker.',
        );
      }
    }
  }

  void _showImagePicker() {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.borderUnselected,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(height: 16.h),
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded),
                  title: const Text('Take Photo'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _pickProfileImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _pickProfileImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleSubmit() {
    if (!_formValid) return;
    HapticFeedback.mediumImpact();

    context.read<AuthBloc>().add(
          CompleteProfileRequested(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            email: _emailController.text.trim(),
            gender: _selectedGender.name,
            profileImagePath: _profileImagePath,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topSafeArea = MediaQuery.of(context).padding.top;
    final minTop = topSafeArea + 12.h;

    if (!_hasCalculatedDefaultTop) {
      _defaultTop = (screenHeight * 0.30).clamp(160.0, 300.0);
      _sheetTop = _defaultTop;
      _hasCalculatedDefaultTop = true;
    }

    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (_, state) =>
          state is AuthProfileCompleted ||
          (state is AuthFailure &&
              state.operation == AuthOperation.completeProfile),
      listener: (context, state) {
        if (state is AuthProfileCompleted) {
          DynamicIslandToast.showSuccess(context, 'Profile completed!');
          Navigator.of(context).pushReplacement(
            CupertinoPageRoute(
              builder: (_) => const AddPropertiesScreen(),
            ),
          );
        } else if (state is AuthFailure) {
          DynamicIslandToast.showError(context, state.message);
        }
      },
      builder: (context, state) {
        final submitting = state is AuthLoading &&
            state.operation == AuthOperation.completeProfile;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
          ),
          child: Scaffold(
            backgroundColor: AppColors.darkHeaderBg,
            body: Stack(
              children: [
                const AuthHeaderBanner(
                  assetPath: AppAssets.profileHeader,
                  fallbackIcon: Icons.person_add_alt_1_rounded,
                ),
                const AuthBackButton(),
                AnimatedPositioned(
                  duration: _isDragging
                      ? Duration.zero
                      : const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  top: _sheetTop ?? _defaultTop,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SlideTransition(
                    position: _sheetSlideAnimation,
                    child: FadeTransition(
                      opacity: _sheetFadeAnimation,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.sheetBackground,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(36.r),
                            topRight: Radius.circular(36.r),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.16),
                              blurRadius: 24,
                              offset: const Offset(0, -6),
                            ),
                          ],
                        ),
                        child: SafeArea(
                          top: false,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDragHandle(minTop),
                                Expanded(
                                  child: SingleChildScrollView(
                                    physics: const BouncingScrollPhysics(),
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 24.w),
                                    child: SlideTransition(
                                      position: _contentSlideAnimation,
                                      child: FadeTransition(
                                        opacity: _contentFadeAnimation,
                                        child: _buildFormContent(),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(
                                    left: 24.w,
                                    right: 24.w,
                                    bottom: 24.h,
                                    top: 12.h,
                                  ),
                                  child: SlideTransition(
                                    position: _contentSlideAnimation,
                                    child: FadeTransition(
                                      opacity: _contentFadeAnimation,
                                      child: AuthPrimaryButton(
                                        label: 'Complete Profile',
                                        onPressed: _handleSubmit,
                                        enabled: _formValid,
                                        loading: submitting,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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

  Widget _buildDragHandle(double minTop) {
    return GestureDetector(
      onVerticalDragStart: (_) => setState(() => _isDragging = true),
      onVerticalDragUpdate: (details) {
        setState(() {
          _sheetTop = (_sheetTop! + details.primaryDelta!)
              .clamp(minTop, _defaultTop);
        });
      },
      onVerticalDragEnd: (details) {
        setState(() {
          _isDragging = false;
          final velocity = details.primaryVelocity ?? 0;
          if (velocity < -300 || _sheetTop! < _defaultTop * 0.6) {
            _sheetTop = minTop;
          } else {
            _sheetTop = _defaultTop;
          }
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Center(
          child: Container(
            width: 38.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E4DE),
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 4.h),
        Text(
          'Complete Profile',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 30.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.textHeadline,
            height: 1.15,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Set up your customer profile to continue.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14.5.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        SizedBox(height: 20.h),
        Center(child: _buildImagePicker()),
        SizedBox(height: 24.h),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                label: 'First Name',
                controller: _firstNameController,
                focusNode: _firstNameFocus,
                nextFocus: _lastNameFocus,
                keyboardType: TextInputType.name,
                prefixIcon: Icons.person_outline_rounded,
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: _buildTextField(
                label: 'Last Name',
                controller: _lastNameController,
                focusNode: _lastNameFocus,
                nextFocus: _emailFocus,
                keyboardType: TextInputType.name,
                prefixIcon: Icons.person_outline_rounded,
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        _buildTextField(
          label: 'Email Address',
          controller: _emailController,
          focusNode: _emailFocus,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
        ),
        SizedBox(height: 20.h),
        Text(
          'Gender',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textHeadline,
          ),
        ),
        SizedBox(height: 8.h),
        _buildGenderSelector(),
        SizedBox(height: 20.h),
      ],
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _showImagePicker,
      child: Stack(
        children: [
          Container(
            width: 88.r,
            height: 88.r,
            decoration: BoxDecoration(
              color: const Color(0xFFF6F8F3),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.borderUnselected,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: _profileImagePath == null
                ? Icon(
                    Icons.person_rounded,
                    size: 44.r,
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                  )
                : Image.file(
                    File(_profileImagePath!),
                    fit: BoxFit.cover,
                  ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(6.r),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_a_photo_rounded,
                size: 13.r,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocus,
    required TextInputType keyboardType,
    required IconData prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textHeadline,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF6F8F3),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: AppColors.borderUnselected,
              width: 1.2,
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: [
              Icon(prefixIcon, size: 20.r, color: AppColors.textSecondary),
              SizedBox(width: 10.w),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: keyboardType,
                  textInputAction: nextFocus != null
                      ? TextInputAction.next
                      : TextInputAction.done,
                  onSubmitted: (_) {
                    if (nextFocus != null) {
                      nextFocus.requestFocus();
                    } else {
                      focusNode.unfocus();
                    }
                  },
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textHeadline,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 13.h),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildGenderCard(
            gender: Gender.male,
            title: 'Male',
            icon: Icons.male_rounded,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildGenderCard(
            gender: Gender.female,
            title: 'Female',
            icon: Icons.female_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildGenderCard({
    required Gender gender,
    required String title,
    required IconData icon,
  }) {
    final selected = _selectedGender == gender;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedGender = gender);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF6F8F3) : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderUnselected,
            width: selected ? 2 : 1.2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.01),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24.r,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            SizedBox(height: 6.h),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.sp,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
