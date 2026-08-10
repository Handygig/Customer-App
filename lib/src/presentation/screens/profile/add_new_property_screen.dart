import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer_app/core/constants/app_assets.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/src/data/repositories/profile_repository_impl.dart';
import 'package:customer_app/src/domain/entities/property.dart';
import 'package:customer_app/src/presentation/screens/auth/map_selector_screen.dart';
import 'package:customer_app/src/presentation/widgets/dynamic_island_toast.dart';

class AddNewPropertyScreen extends StatefulWidget {
  final Property? propertyToEdit;

  const AddNewPropertyScreen({super.key, this.propertyToEdit});

  @override
  State<AddNewPropertyScreen> createState() => _AddNewPropertyScreenState();
}

class _AddNewPropertyScreenState extends State<AddNewPropertyScreen> {
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

  final ProfileRepositoryImpl _repository = ProfileRepositoryImpl();

  @override
  void initState() {
    super.initState();
    if (widget.propertyToEdit != null) {
      final p = widget.propertyToEdit!;
      _nameController.text = p.title;
      _addressLine1Controller.text = p.address;
      
      if (p.type == PropertyType.office) {
        _selectedType = 'Office';
      } else if (p.type == PropertyType.apartment) {
        _selectedType = 'Apartment';
      } else if (p.type == PropertyType.villa) {
        _selectedType = 'Other';
      } else {
        _selectedType = 'Home';
      }
      
      _selectedImagePath = p.imagePath;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  void _saveProperty() async {
    final name = _nameController.text.trim();
    final line1 = _addressLine1Controller.text.trim();
    final line2 = _addressLine2Controller.text.trim();
    final city = _cityController.text.trim();
    final province = _provinceController.text.trim();
    final postalCode = _postalCodeController.text.trim();

    if (name.isEmpty || line1.isEmpty || city.isEmpty || province.isEmpty || postalCode.isEmpty) {
      DynamicIslandToast.showError(context, 'Please fill in all required fields.');
      return;
    }

    if (_selectedImagePath == null) {
      DynamicIslandToast.showError(context, 'Please upload a property photo.');
      return;
    }

    final fullAddress = line2.isNotEmpty
        ? '$line1, $line2, $city, $province, $postalCode'
        : '$line1, $city, $province, $postalCode';

    PropertyType propType = PropertyType.house;
    if (_selectedType == 'Office') propType = PropertyType.office;
    if (_selectedType == 'Apartment') propType = PropertyType.apartment;
    if (_selectedType == 'Other') propType = PropertyType.villa;

    final isEditing = widget.propertyToEdit != null;
    final newProperty = Property(
      id: isEditing ? widget.propertyToEdit!.id : 'prop_${DateTime.now().millisecondsSinceEpoch}',
      title: name,
      address: fullAddress,
      type: propType,
      bedrooms: isEditing ? widget.propertyToEdit!.bedrooms : 3,
      areaSqft: isEditing ? widget.propertyToEdit!.areaSqft : 1850,
      isPrimary: isEditing ? widget.propertyToEdit!.isPrimary : false,
      imagePath: _selectedImagePath,
    );

    HapticFeedback.mediumImpact();
    
    if (isEditing) {
      await _repository.updateProperty(newProperty);
    } else {
      await _repository.addProperty(newProperty);
    }

    if (mounted) {
      DynamicIslandToast.showSuccess(context, isEditing ? 'Property updated successfully!' : 'New property added successfully!');
      Navigator.of(context).pop();
    }
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
        _addressLine1Controller.text = "Market Street";
        _addressLine2Controller.text = "Suite 100";
        _cityController.text = "San Francisco";
        _provinceController.text = "CA";
        _postalCodeController.text = "94103";
        _selectedLatitude = result['latitude'] as double;
        _selectedLongitude = result['longitude'] as double;
      });
    }
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
                    setState(() {
                      _selectedImagePath = AppAssets.propertiesHeader;
                    });
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
                    setState(() {
                      _selectedImagePath = AppAssets.welcomeHero;
                    });
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

  @override
  Widget build(BuildContext context) {
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
          widget.propertyToEdit != null ? 'Edit Property' : 'Add New Property',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: AppColors.borderUnselected, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.propertyToEdit != null ? 'Edit Property' : 'Register Property',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textHeadline,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                widget.propertyToEdit != null 
                    ? 'Update location and address details for your property.' 
                    : 'Enter location and address details to add a new home or workspace.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 20.h),

              // 1. Location Type (Moved to Top)
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

              // 3. Location on Map
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
                  height: 110.h,
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
                              size: 32.r,
                            ),
                            SizedBox(height: 4.h),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Text(
                                _selectedLatitude != null && _selectedLongitude != null
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

              // 6. City & Province
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

              // 7. Postal / ZIP Code
              _buildFormTextField(
                label: 'Postal / ZIP Code',
                controller: _postalCodeController,
                hintText: '94103',
                prefixIcon: Icons.local_post_office_rounded,
              ),
              SizedBox(height: 16.h),

              // 8. Property Photo Upload Card (Moved to Bottom)
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
                  height: 135.h,
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
                              _selectedImagePath!.startsWith('assets/')
                                  ? Image.asset(
                                      _selectedImagePath!,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      File(_selectedImagePath!),
                                      fit: BoxFit.cover,
                                    ),
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
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(
            top: BorderSide(color: AppColors.borderUnselected, width: 1.0),
          ),
        ),
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 52.h,
            child: ElevatedButton(
              onPressed: _saveProperty,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonBackground,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26.r),
                ),
              ),
              child: Text(
                widget.propertyToEdit != null ? 'Save Changes' : 'Save Property',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
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
}
