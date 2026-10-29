import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/src/domain/entities/properties/property_entity.dart';
import 'package:customer_app/src/presentation/cubits/properties/property_cubit.dart';
import 'package:customer_app/src/presentation/cubits/properties/property_state.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_app/config/router/app_routes.dart';
import 'package:customer_app/src/presentation/widgets/dynamic_island_toast.dart';

class PropertiesManagementScreen extends StatelessWidget {
  const PropertiesManagementScreen({super.key});

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
          'Properties Management',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<PropertyCubit, PropertyState>(
        listener: (context, state) {
          if (state is PropertyActionSuccess) {
            DynamicIslandToast.showSuccess(context, state.message);
          } else if (state is PropertyError) {
            DynamicIslandToast.showError(context, state.message);
          }
        },
        builder: (context, state) {
          final properties = context.read<PropertyCubit>().currentProperties;
          final isLoading = state is PropertyLoading && properties.isEmpty;

          if (isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => context.read<PropertyCubit>().loadProperties(forceRefresh: true),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Registered Properties (${properties.length})',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textHeadline,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  if (properties.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(32.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24.r),
                        border: Border.all(color: AppColors.borderUnselected),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(16.r),
                            decoration: const BoxDecoration(
                              color: AppColors.cardSelectedBg,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.location_city_rounded,
                              size: 40.r,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'No Properties Added Yet',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textHeadline,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            'Add your first property to schedule home services easily.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...properties.map(
                      (prop) => _buildPropertyTile(context, prop),
                    ),
                ],
              ),
            ),
          );
        },
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
            height: 54.h,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                context.push(AppRoutes.addNewProperty);
              },
              icon: const Icon(Icons.add_home_rounded, color: Colors.white),
              label: Text(
                'Add New Property',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(27.r),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyTile(
    BuildContext context,
    PropertyEntity property,
  ) {
    IconData typeIcon = Icons.home_rounded;
    String typeLabel = property.label;
    final lower = property.label.toLowerCase();
    if (lower.contains('apartment')) {
      typeIcon = Icons.apartment_rounded;
      typeLabel = 'Apartment';
    } else if (lower.contains('villa')) {
      typeIcon = Icons.villa_rounded;
      typeLabel = 'Villa';
    } else if (lower.contains('office')) {
      typeIcon = Icons.domain_rounded;
      typeLabel = 'Office';
    } else if (lower.contains('home') || lower.contains('house')) {
      typeIcon = Icons.home_rounded;
      typeLabel = 'Home';
    }

    final isPrimary = property.isDefault;

    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isPrimary ? AppColors.primary : const Color(0xFFE8ECE1),
          width: isPrimary ? 2.0 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFF3D4127,
            ).withValues(alpha: isPrimary ? 0.08 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hero Image Banner with Floating Badges
            SizedBox(
              height: 155.h,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background Property Photo
                  _buildPropertyImage(null, typeIcon),

                  // Top & Bottom Subtle Gradients for visual contrast
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.55),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.35),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),

                  // Top Left: Property Type Tag Pill
                  Positioned(
                    top: 12.h,
                    left: 14.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 5.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(typeIcon, color: Colors.white, size: 14.r),
                          SizedBox(width: 5.w),
                          Text(
                            typeLabel,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Top Right: Primary Badge & Delete Action
                  Positioned(
                    top: 12.h,
                    right: 14.w,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isPrimary) ...[
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 5.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentLime,
                              borderRadius: BorderRadius.circular(20.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 14.r,
                                  color: AppColors.primaryDark,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  'PRIMARY',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5.sp,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primaryDark,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8.w),
                        ],

                        // Edit Action Button
                        InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            context.push(
                              AppRoutes.addNewProperty,
                              extra: property,
                            );
                          },
                          borderRadius: BorderRadius.circular(20.r),
                          child: Container(
                            padding: EdgeInsets.all(7.r),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.edit_rounded,
                              color: AppColors.primary,
                              size: 18.r,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),

                        // Delete Action Button
                        InkWell(
                          onTap: () => _confirmDeleteProperty(
                            context,
                            property,
                          ),
                          borderRadius: BorderRadius.circular(20.r),
                          child: Container(
                            padding: EdgeInsets.all(7.r),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.red.shade600,
                              size: 18.r,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. Card Content Body
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Default indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          property.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textHeadline,
                          ),
                        ),
                      ),
                      if (isPrimary)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F5EC),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 13.r,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                'Default',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 6.h),

                  // Location Address
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 15.r,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          property.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  // Specs Badges Row
                  Row(children: [_buildSpecBadge(typeIcon, typeLabel)]),
                  SizedBox(height: 14.h),

                  // Divider
                  Container(height: 1, color: const Color(0xFFEFF2E7)),
                  SizedBox(height: 10.h),

                  // Bottom Action Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (!isPrimary)
                        InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            context.read<PropertyCubit>().setDefaultProperty(property.id);
                          },
                          borderRadius: BorderRadius.circular(8.r),
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 4.h),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.star_outline_rounded,
                                  size: 17.r,
                                  color: AppColors.primary,
                                ),
                                SizedBox(width: 5.w),
                                Text(
                                  'Set as Primary',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Row(
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              size: 16.r,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 5.w),
                            Text(
                              'Primary Residence',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),

                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 5.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F8F3),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          'Active Property',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecBadge(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6EE),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.r, color: AppColors.primary),
          SizedBox(width: 5.w),
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyImage(String? imagePath, IconData fallbackIcon) {
    if (imagePath != null && imagePath.isNotEmpty) {
      if (imagePath.startsWith('assets/')) {
        return Image.asset(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildFallbackImage(fallbackIcon),
        );
      } else {
        try {
          final file = File(imagePath);
          if (file.existsSync()) {
            return Image.file(
              file,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildFallbackImage(fallbackIcon),
            );
          }
        } catch (_) {}
      }
    }
    return _buildFallbackImage(fallbackIcon);
  }

  Widget _buildFallbackImage(IconData fallbackIcon) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE5E9D8), Color(0xFFC7CEA8)],
        ),
      ),
      child: Center(
        child: Icon(fallbackIcon, color: AppColors.primary, size: 48.r),
      ),
    );
  }

  void _confirmDeleteProperty(
    BuildContext context,
    PropertyEntity property,
  ) {
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
                    Icons.delete_outline_rounded,
                    color: Colors.red.shade600,
                    size: 32.r,
                  ),
                ),
                SizedBox(height: 14.h),
                Text(
                  'Remove Property?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textHeadline,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Are you sure you want to remove "${property.title}"? You can re-add it anytime.',
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
                            await context.read<PropertyCubit>().deleteProperty(property.id);
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
