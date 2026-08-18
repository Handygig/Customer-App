import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:customer_app/core/constants/app_assets.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/src/presentation/screens/auth/map_selector_screen.dart';
import 'package:customer_app/src/presentation/screens/main_navigation_screen.dart';
import 'package:customer_app/src/presentation/widgets/dynamic_island_toast.dart';

class PropertyItem {
  final String name;
  final String address;
  final String type; // Home, Office, Apartment, Other
  final double? latitude;
  final double? longitude;
  final String? imagePath;

  const PropertyItem({
    required this.name,
    required this.address,
    required this.type,
    this.latitude,
    this.longitude,
    this.imagePath,
  });
}

class AddPropertiesScreen extends StatefulWidget {
  const AddPropertiesScreen({super.key});

  @override
  State<AddPropertiesScreen> createState() => _AddPropertiesScreenState();
}

class _AddPropertiesScreenState extends State<AddPropertiesScreen>
    with SingleTickerProviderStateMixin {
  final List<PropertyItem> _properties = [];
  final ImagePicker _imagePicker = ImagePicker();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressLine1Controller = TextEditingController();
  final TextEditingController _addressLine2Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _provinceController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();

  String _selectedType = 'Home';
  double? _selectedLatitude;
  double? _selectedLongitude;
  String? _selectedImagePath;
  bool _isAddingNew = false;

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
      begin: const Offset(0.0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _sheetFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.60, curve: Curves.easeOut),
      ),
    );

    _contentSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.20, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _contentFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.20, 0.85, curve: Curves.easeOut),
      ),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _postalCodeController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _addNewProperty() {
    final name = _nameController.text.trim();
    final line1 = _addressLine1Controller.text.trim();
    final line2 = _addressLine2Controller.text.trim();
    final city = _cityController.text.trim();
    final province = _provinceController.text.trim();
    final postalCode = _postalCodeController.text.trim();

    if (name.isEmpty || line1.isEmpty || city.isEmpty || province.isEmpty || postalCode.isEmpty) {
      DynamicIslandToast.showError(context, 'Please fill all required fields.');
      return;
    }

    if (_selectedImagePath == null) {
      DynamicIslandToast.showError(context, 'Please upload a property photo.');
      return;
    }

    final combinedAddress = line2.isNotEmpty 
        ? '$line1, $line2, $city, $province, $postalCode'
        : '$line1, $city, $province, $postalCode';

    HapticFeedback.mediumImpact();
    setState(() {
      _properties.add(PropertyItem(
        name: name,
        address: combinedAddress,
        type: _selectedType,
        latitude: _selectedLatitude,
        longitude: _selectedLongitude,
        imagePath: _selectedImagePath,
      ));
      _nameController.clear();
      _addressLine1Controller.clear();
      _addressLine2Controller.clear();
      _cityController.clear();
      _provinceController.clear();
      _postalCodeController.clear();
      _selectedType = 'Home';
      _selectedLatitude = null;
      _selectedLongitude = null;
      _selectedImagePath = null;
      _isAddingNew = false;
    });
  }

  void _deleteProperty(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _properties.removeAt(index);
    });
  }

  void _handleSkip() {
    HapticFeedback.lightImpact();
    _finishRegistration('Registration skipped properties setup');
  }

  void _handleFinish() {
    HapticFeedback.mediumImpact();
    _finishRegistration('Registration finished. Added ${_properties.length} properties.');
  }

  void _finishRegistration(String message) {
    DynamicIslandToast.showSuccess(context, 'Account setup completed!');

    Navigator.of(context).pushAndRemoveUntil(
      CupertinoPageRoute(
        builder: (context) => const MainNavigationScreen(),
      ),
      (route) => false,
    );
  }

  void _openMapSelector() async {
    HapticFeedback.lightImpact();
    final result = await Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => const MapSelectorScreen(),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _addressLine1Controller.text =
            (result['address_line_1'] ?? result['address'] ?? '').toString();
        _addressLine2Controller.text =
            (result['address_line_2'] ?? '').toString();
        _cityController.text = (result['city'] ?? '').toString();
        _provinceController.text = (result['province'] ?? '').toString();
        _postalCodeController.text = (result['postal_code'] ?? '').toString();
        _selectedLatitude = (result['latitude'] as num?)?.toDouble();
        _selectedLongitude = (result['longitude'] as num?)?.toDouble();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.darkHeaderBg,
        body: Stack(
          children: [
            // Top Section - Header Photo Banner
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: (screenHeight * 0.38).clamp(200.0, 360.0),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    AppAssets.propertiesHeader,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.darkHeaderBg,
                        child: const Center(
                          child: Icon(
                            Icons.home_work_rounded,
                            size: 64,
                            color: Colors.white24,
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 100.h,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.45),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Top-Left Circular Back Button
            Positioned(
              top: 0,
              left: 0,
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 18.w,
                    vertical: 10.h,
                  ),
                  child: Container(
                    width: 42.r,
                    height: 42.r,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.8),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        splashColor: AppColors.primary.withValues(alpha: 0.15),
                        highlightColor:
                            AppColors.primary.withValues(alpha: 0.08),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).maybePop();
                        },
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.only(left: 3.w),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18.r,
                              color: AppColors.textHeadline,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Top-Right Circular "Skip" Button
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 18.w,
                    vertical: 10.h,
                  ),
                  child: Container(
                    height: 40.h,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.8),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20.r),
                      child: InkWell(
                        onTap: _handleSkip,
                        borderRadius: BorderRadius.circular(20.r),
                        splashColor: AppColors.primary.withValues(alpha: 0.15),
                        highlightColor:
                            AppColors.primary.withValues(alpha: 0.08),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 18.w),
                          child: Center(
                            child: Text(
                              'Skip',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textHeadline,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Section - Animated White Card Sheet
            Positioned(
              top: (screenHeight * 0.30).clamp(160.0, 300.0),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Grabber Pill (Static)
                          Center(
                            child: Container(
                              margin: EdgeInsets.only(
                                top: 12.h,
                                bottom: 6.h,
                              ),
                              width: 38.w,
                              height: 4.h,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E4DE),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                            ),
                          ),

                          // 2. Scrollable Body Content (Properties List or Add form)
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.symmetric(horizontal: 24.w),
                              child: SlideTransition(
                                position: _contentSlideAnimation,
                                child: FadeTransition(
                                  opacity: _contentFadeAnimation,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 12.h),

                                      // Title & Header section (Dynamic based on form state)
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _isAddingNew
                                                ? 'New Property'
                                                : 'Add your Properties',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 28.sp,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.textHeadline,
                                              height: 1.15,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                          if (_isAddingNew)
                                            IconButton(
                                              onPressed: () {
                                                HapticFeedback.lightImpact();
                                                setState(() {
                                                  _isAddingNew = false;
                                                });
                                              },
                                              icon: const Icon(
                                                Icons.close_rounded,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                        ],
                                      ),
                                      SizedBox(height: 6.h),

                                      // Subtitle
                                      Text(
                                        _isAddingNew
                                            ? 'Set up your home or workspace coordinates'
                                            : 'Add your homes, offices, or other locations to order cleaning or repairs faster.',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textSecondary,
                                          height: 1.4,
                                        ),
                                      ),
                                      SizedBox(height: 24.h),

                                      if (_isAddingNew)
                                        _buildAddPropertyForm()
                                      else ...[
                                        // Properties list
                                        ..._properties.asMap().entries.map((entry) {
                                          return _buildPropertyCard(
                                              entry.value, entry.key);
                                        }),

                                        // Dashed Add New Button Card
                                        _buildAddPropertyTriggerCard(),
                                      ],
                                      SizedBox(height: 24.h),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // 3. Static Bottom Button Bar (Non-scrolling footer)
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
                                  child: _isAddingNew
                                      ? Row(
                                          children: [
                                            Expanded(
                                              child: SizedBox(
                                                height: 52.h,
                                                child: OutlinedButton(
                                                  onPressed: () {
                                                    HapticFeedback.lightImpact();
                                                    setState(() {
                                                      _isAddingNew = false;
                                                    });
                                                  },
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor: AppColors.textHeadline,
                                                    side: const BorderSide(
                                                      color: AppColors.borderUnselected,
                                                      width: 1.5,
                                                    ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(26.r),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'Cancel',
                                                    style: GoogleFonts.plusJakartaSans(
                                                      fontSize: 16.sp,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 12.w),
                                            Expanded(
                                              flex: 2,
                                              child: SizedBox(
                                                height: 52.h,
                                                child: ElevatedButton(
                                                  onPressed: _addNewProperty,
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: AppColors.buttonBackground,
                                                    foregroundColor: Colors.white,
                                                    elevation: 0,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(26.r),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'Save Location',
                                                    style: GoogleFonts.plusJakartaSans(
                                                      fontSize: 16.sp,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      : _buildSubmitButton()),
                            ),
                          ),
                        ],
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
  }

  Future<void> _pickPropertyImage(ImageSource source) async {
    try {
      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 88,
        maxWidth: 1600,
      );
      if (image != null && mounted) {
        setState(() {
          _selectedImagePath = image.path;
        });
      }
    } catch (_) {
      if (mounted) {
        DynamicIslandToast.showError(context, 'Unable to open the image picker.');
      }
    }
  }

  Widget _buildSelectedPropertyImage() {
    final path = _selectedImagePath;
    if (path == null || path.isEmpty) {
      return const SizedBox.shrink();
    }

    if (path.startsWith('assets/')) {
      return Image.asset(path, fit: BoxFit.cover);
    }

    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFFF4F6EE),
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined),
        ),
      ),
    );
  }

  void _showImagePickerModal() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20.w),
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
                  'Upload Property Photo',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textHeadline,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Select or take a high-resolution photo of your property.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 20.h),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: const BoxDecoration(
                      color: AppColors.cardSelectedBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 20.r),
                  ),
                  title: Text(
                    'Take Photo (Camera)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHeadline,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickPropertyImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: const BoxDecoration(
                      color: AppColors.cardSelectedBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.photo_library_rounded, color: AppColors.primary, size: 20.r),
                  ),
                  title: Text(
                    'Choose from Gallery',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHeadline,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickPropertyImage(ImageSource.gallery);
                  },
                ),
                SizedBox(height: 14.h),
                Text(
                  'Sample Property Presets',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textHeadline,
                  ),
                ),
                SizedBox(height: 10.h),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPresetThumbnail(ctx, AppAssets.propertyVilla, 'Villa / House'),
                      SizedBox(width: 12.w),
                      _buildPresetThumbnail(ctx, AppAssets.propertyApartment, 'Apartment'),
                      SizedBox(width: 12.w),
                      _buildPresetThumbnail(ctx, AppAssets.propertyCottage, 'Cottage'),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPresetThumbnail(BuildContext modalContext, String assetPath, String title) {
    return GestureDetector(
      onTap: () {
        Navigator.of(modalContext).pop();
        setState(() {
          _selectedImagePath = assetPath;
        });
      },
      child: Column(
        children: [
          Container(
            width: 90.w,
            height: 65.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              image: DecorationImage(
                image: AssetImage(assetPath),
                fit: BoxFit.cover,
              ),
              border: Border.all(color: AppColors.primary, width: 1.5),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(PropertyItem item, int index) {
    IconData typeIcon = Icons.home_rounded;
    if (item.type == 'Office') typeIcon = Icons.domain_rounded;
    if (item.type == 'Apartment') typeIcon = Icons.apartment_rounded;
    if (item.type == 'Other') typeIcon = Icons.location_on_rounded;

    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: AppColors.borderUnselected,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14.r),
            child: SizedBox(
              width: 62.w,
              height: 62.h,
              child: item.imagePath != null && item.imagePath!.isNotEmpty
                  ? (item.imagePath!.startsWith('assets/')
                      ? Image.asset(
                          item.imagePath!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: const Color(0xFFF4F6EE),
                            child: Center(
                              child: Icon(typeIcon, color: AppColors.primary, size: 24.r),
                            ),
                          ),
                        )
                      : Image.file(
                          File(item.imagePath!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: const Color(0xFFF4F6EE),
                            child: Center(
                              child: Icon(typeIcon, color: AppColors.primary, size: 24.r),
                            ),
                          ),
                        ))
                  : Container(
                      color: const Color(0xFFF4F6EE),
                      child: Center(
                        child: Icon(typeIcon, color: AppColors.primary, size: 24.r),
                      ),
                    ),
            ),
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
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textHeadline,
                        ),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F6EE),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        item.type,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  item.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              _deleteProperty(index);
            },
            icon: Icon(
              Icons.delete_outline_rounded,
              color: Colors.red.shade400,
              size: 20.r,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPropertyTriggerCard() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _isAddingNew = true;
        });
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 20.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline_rounded,
              color: AppColors.primary,
              size: 22.r,
            ),
            SizedBox(width: 10.w),
            Text(
              'Add New Property',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddPropertyForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Location Type selector row (Moved to Top)
        Text(
          'Location Type',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textHeadline,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildTypeOption('Home', Icons.home_rounded),
            _buildTypeOption('Office', Icons.domain_rounded),
            _buildTypeOption('Apartment', Icons.apartment_rounded),
            _buildTypeOption('Other', Icons.location_on_rounded),
          ],
        ),
        SizedBox(height: 16.h),

        // 2. Property Name Input
        _buildFormTextField(
          label: 'Property Name (e.g. Home, Office)',
          controller: _nameController,
          hintText: 'Home',
          prefixIcon: Icons.label_important_outline_rounded,
        ),
        SizedBox(height: 16.h),

        // 3. Map Visual Selector Card
        Text(
          'Location on Map',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textHeadline,
          ),
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: _openMapSelector,
          child: Container(
            height: 120.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2EC),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: AppColors.borderUnselected,
                width: 1.2,
              ),
              image: const DecorationImage(
                image: AssetImage(AppAssets.languageHeader),
                fit: BoxFit.cover,
                opacity: 0.65,
              ),
            ),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.r),
                    color: Colors.black.withValues(alpha: 0.15),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: AppColors.primary,
                        size: 34.r,
                      ),
                      SizedBox(height: 4.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          _selectedLatitude != null
                              ? 'Coordinates Selected'
                              : 'Tap to pinpoint on map ➔',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textHeadline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16.h),

        // 4. Address Line 1
        _buildFormTextField(
          label: 'Address Line 1',
          controller: _addressLine1Controller,
          hintText: '123 Main Street',
          prefixIcon: Icons.home_outlined,
        ),
        SizedBox(height: 14.h),

        // 5. Address Line 2 (Optional)
        _buildFormTextField(
          label: 'Address Line 2 (Optional)',
          controller: _addressLine2Controller,
          hintText: 'Apartment, suite, unit, etc.',
          prefixIcon: Icons.apartment_outlined,
        ),
        SizedBox(height: 14.h),

        // 6. City and Province (Row layout)
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _buildFormTextField(
                label: 'City',
                controller: _cityController,
                hintText: 'San Francisco',
                prefixIcon: Icons.location_city_rounded,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              flex: 2,
              child: _buildFormTextField(
                label: 'Province / State',
                controller: _provinceController,
                hintText: 'CA',
                prefixIcon: Icons.map_rounded,
              ),
            ),
          ],
        ),
        SizedBox(height: 14.h),

        // 7. Postal Code
        _buildFormTextField(
          label: 'Postal / ZIP Code',
          controller: _postalCodeController,
          hintText: '94103',
          prefixIcon: Icons.local_post_office_rounded,
        ),
        SizedBox(height: 16.h),

        // 8. Property Photo Upload Card (Moved to Bottom, Mandatory)
        Text.rich(
          TextSpan(
            text: 'Property Photo ',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textHeadline,
            ),
            children: [
              TextSpan(
                text: '*',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.red,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: _showImagePickerModal,
          child: Container(
            height: 140.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF6F8F3),
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(
                color: _selectedImagePath != null
                    ? AppColors.primary
                    : AppColors.borderUnselected,
                width: _selectedImagePath != null ? 2.0 : 1.2,
              ),
            ),
            child: _selectedImagePath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16.r),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildSelectedPropertyImage(),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.1),
                                Colors.black.withValues(alpha: 0.5),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 10.h,
                          right: 10.w,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(Icons.edit_rounded,
                                  size: 18.r, color: AppColors.primaryDark),
                              onPressed: _showImagePickerModal,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 12.h,
                          left: 14.w,
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(4.r),
                                decoration: const BoxDecoration(
                                  color: AppColors.accentLime,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.check_rounded,
                                    size: 14.r, color: AppColors.primaryDark),
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'Property photo attached',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 12.5.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add_a_photo_rounded,
                          color: AppColors.primary,
                          size: 26.r,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Upload Property Image',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textHeadline,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Tap to select or capture front photo (JPG, PNG)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        SizedBox(height: 24.h),
      ],
    );
  }

  Widget _buildTypeOption(String type, IconData icon) {
    final isSel = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedType = type;
          });
        },
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: isSel ? const Color(0xFFF6F8F3) : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSel ? AppColors.primary : AppColors.borderUnselected,
              width: isSel ? 1.8 : 1.2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20.r,
                color: isSel ? AppColors.primary : AppColors.textSecondary,
              ),
              SizedBox(height: 4.h),
              Text(
                type,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp,
                  fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                  color: isSel ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormTextField({
    required String label,
    required TextEditingController controller,
    required String hintText,
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
              Icon(
                prefixIcon,
                size: 20.r,
                color: AppColors.textSecondary,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: TextField(
                  controller: controller,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textHeadline,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
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

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: ElevatedButton(
        onPressed: _handleFinish,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonBackground,
          foregroundColor: AppColors.buttonText,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 24.w),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _properties.isEmpty ? 'Skip & Finish' : 'Finish Registration',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.1,
              ),
            ),
            SizedBox(width: 8.w),
            const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
