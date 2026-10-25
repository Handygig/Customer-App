import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/di/service_locator.dart';
import 'package:customer_app/src/data/repositories/profile/profile_repository_impl.dart';
import 'package:customer_app/src/domain/entities/profile/user_profile.dart';
import 'package:customer_app/src/domain/repositories/profile/profile_repository.dart';
import 'package:customer_app/src/domain/entities/job_requests/job_assignment_entity.dart';
import 'package:customer_app/src/presentation/cubits/job_assignments/job_assignment_cubit.dart';
import 'package:customer_app/src/presentation/cubits/job_assignments/job_assignment_state.dart';
import 'package:customer_app/src/presentation/cubits/services/service_category_cubit.dart';
import 'package:customer_app/src/presentation/cubits/services/service_category_state.dart';
import 'package:customer_app/src/domain/entities/services/service_category_entity.dart';
import 'package:customer_app/src/presentation/screens/services/all_services_screen.dart';
import 'package:customer_app/src/presentation/widgets/dynamic_island_toast.dart';
import 'package:customer_app/src/presentation/screens/jobs/job_details_screen.dart';
import 'package:customer_app/src/domain/repositories/offers/offer_repository.dart';
import 'package:customer_app/src/data/repositories/offers/offer_repository_impl.dart';
import 'package:customer_app/src/domain/entities/properties/property_entity.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_app/config/router/app_routes.dart';
import 'package:customer_app/src/presentation/cubits/properties/property_cubit.dart';
import 'package:customer_app/src/presentation/screens/profile/add_new_property_screen.dart';
import 'package:customer_app/src/presentation/screens/profile/properties_management_screen.dart';
import 'package:customer_app/core/utils/extensions.dart';

class HomeTab extends StatefulWidget {
  final VoidCallback? onAddPropertyTap;
  final Function(int index)? onNavigateTab;

  const HomeTab({super.key, this.onAddPropertyTap, this.onNavigateTab});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  int _selectedOfferIndex = 0;
  int _selectedPropertyIndex = 0;

  final PageController _offersPageController = PageController();
  final OfferRepository _offerRepository = OfferRepositoryImpl();
  final PageController _propertiesPageController = PageController(
    viewportFraction: 0.85,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JobAssignmentCubit>().loadAssignments();
      context.read<ServiceCategoryCubit>().loadCategories();
      context.read<PropertyCubit>().loadProperties();
      _loadOffers();
    });
  }

  Future<void> _loadOffers() async {
    final result = await _offerRepository.getExclusiveOffers();
    if (mounted) {
      result.fold(
        (failure) {
          debugPrint('⚠️ [_loadOffers] Error loading offers: ${failure.errorMessage}');
        },
        (offers) {
          debugPrint('🎯 [_loadOffers] Loaded ${offers.length} exclusive offers');
          setState(() {
            _offers = offers.map((o) => o.toMap()).toList();
            if (_selectedOfferIndex >= _offers.length) {
              _selectedOfferIndex = 0;
            }
          });
        },
      );
    }
  }

  void _claimOffer(Map<String, dynamic> offer) {
    HapticFeedback.lightImpact();
    final code = offer['code']?.toString() ?? '';
    if (code.isNotEmpty) {
      _offerRepository.claimOffer(code);
      Clipboard.setData(ClipboardData(text: code));
      DynamicIslandToast.showSuccess(
        context,
        'Offer code "$code" applied! Navigating to services...',
      );
    }
    widget.onNavigateTab?.call(2);
  }



  // Dynamically loaded offers from API
  List<Map<String, dynamic>> _offers = [];



  @override
  void dispose() {
    _offersPageController.dispose();
    _propertiesPageController.dispose();
    super.dispose();
  }

  void _copyCouponCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 8.w),
            Text(
              'Coupon "$code" copied to clipboard!',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13.sp,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final assignmentState = context.watch<JobAssignmentCubit>().state;
    final ongoingAssignments = assignmentState is JobAssignmentLoaded
        ? assignmentState.assignments.where((a) => a.isOngoing).toList()
        : context.watch<JobAssignmentCubit>().currentAssignments.where((a) => a.isOngoing).toList();
    final properties = context.watch<PropertyCubit>().currentProperties;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor(context),
      body: Column(
        children: [
          // 1. Static Non-Scrolling Top Header Banner
          _buildTopHeader(context),

          // 2. Scrollable Body Content
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primaryDark,
              backgroundColor: AppColors.surfaceColor(context),
              strokeWidth: 2.8,
              onRefresh: () async {
                HapticFeedback.mediumImpact();
                await Future.wait([
                  context.read<JobAssignmentCubit>().loadAssignments(forceRefresh: true),
                  context.read<ServiceCategoryCubit>().loadCategories(),
                  context.read<PropertyCubit>().loadProperties(forceRefresh: true),
                  _loadOffers(),
                ]);
                if (context.mounted) {
                  DynamicIslandToast.showSuccess(
                    context,
                    'Dashboard Refreshed',
                  );
                }
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 16.h),

                    // 1. Added Properties Carousel
                    _buildCoverFlowPropertiesSection(properties),

                    SizedBox(height: 16.h),

                    // 2. Explore Services (Horizontal Scrolling Section)
                    _buildServiceCategoriesSection(),

                    SizedBox(height: 16.h),

                    // 3. Ongoing Jobs Section
                    _buildOngoingJobsSection(ongoingAssignments),

                    SizedBox(height: 16.h),

                    // 4. Special Offers & Promos Section
                    _buildOffersSection(),

                    // Bottom space for floating navigation bar
                    SizedBox(height: 120.h),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. TOP HEADER & INTEGRATED SEARCH BAR (LIGHT MODE)
  // ---------------------------------------------------------------------------
  Widget _buildTopHeader(BuildContext context) {
    final double topInset = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceColor(context),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28.r),
          bottomRight: Radius.circular(28.r),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.isDark(context)
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20.w, topInset + 12.h, 20.w, 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: StreamBuilder<UserProfile>(
                  stream: (sl.isRegistered<ProfileRepository>()
                          ? sl<ProfileRepository>()
                          : ProfileRepositoryImpl())
                      .watchUserProfile(),
                  builder: (context, snapshot) {
                    final firstName = snapshot.data?.firstName.trim() ?? '';
                    final displayName = firstName.isNotEmpty
                        ? firstName
                        : (snapshot.data?.fullName.trim().isNotEmpty == true
                            ? snapshot.data!.fullName.trim()
                            : '');
                    final greeting = displayName.isNotEmpty
                        ? context.loc.goodMorningUser(displayName)
                        : context.loc.goodMorning;
                    final initial = displayName.isNotEmpty
                        ? displayName[0].toUpperCase()
                        : 'U';
                    final profileImage = snapshot.data?.profileImageUrl;

                    return Row(
                      children: [
                        // Avatar
                        Container(
                          width: 44.r,
                          height: 44.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary, width: 2),
                            color: AppColors.primary,
                            image: (profileImage != null && profileImage.isNotEmpty)
                                ? DecorationImage(
                                    image: NetworkImage(profileImage),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: (profileImage == null || profileImage.isEmpty)
                              ? Center(
                                  child: Text(
                                    initial,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      greeting,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        color: AppColors.headlineColor(context),
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 4.w),
                                  Text('👋', style: TextStyle(fontSize: 14.sp)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Notification bell button (Light Mode)
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onNavigateTab?.call(3);
                },
                child: Container(
                  width: 42.r,
                  height: 42.r,
                  decoration: BoxDecoration(
                    color: AppColors.cardSelectedColor(context),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: AppColors.borderColor(context)),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.notifications_outlined,
                        color: AppColors.iconColor(context),
                        size: 22.r,
                      ),
                      Positioned(
                        top: 10.h,
                        right: 10.w,
                        child: Container(
                          width: 8.r,
                          height: 8.r,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 18.h),

          // Integrated Search Bar (Light Mode)
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onNavigateTab?.call(2);
            },
            child: Container(
              height: 48.h,
              decoration: BoxDecoration(
                color: AppColors.searchBarColor(context),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: AppColors.borderColor(context)),
              ),
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: AppColors.iconColor(context),
                    size: 20.r,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      context.loc.homeSearchPlaceholder,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.mutedTextColor(context),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(6.r),
                    decoration: BoxDecoration(
                      color: AppColors.cardColor(context),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: AppColors.borderColor(context)),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      color: AppColors.iconColor(context),
                      size: 16.r,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. COVER FLOW ADDED PROPERTIES SECTION (MATCHING DESIGN REFERENCE)
  // ---------------------------------------------------------------------------
  // 1. ADDED PROPERTIES SECTION (COVER FLOW CAROUSEL)
  // ---------------------------------------------------------------------------
  Widget _buildCoverFlowPropertiesSection(List<PropertyEntity> properties) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4.w,
                    height: 16.h,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    context.loc.addedProperties,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.headlineColor(context),
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    '(${properties.length})',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mutedTextColor(context),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push(AppRoutes.properties);
                },
                child: Text(
                  context.loc.manage,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),

        if (properties.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                if (widget.onAddPropertyTap != null) {
                  widget.onAddPropertyTap!();
                } else {
                  context.push(AppRoutes.addNewProperty);
                }
              },
              child: Container(
                height: 140.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surfaceColor(context),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: AppColors.borderColor(context),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_home_work_rounded,
                        color: AppColors.primary,
                        size: 26.r,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      context.loc.noPropertiesAdded,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.headlineColor(context),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      context.loc.tapToRegisterFirstProperty,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.sp,
                        color: AppColors.mutedTextColor(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else if (properties.length == 1)
          // Single Property Hero Card - full width without slider or cloning
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: SizedBox(
              height: 270.h,
              child: _buildPropertyCoverCard(properties.first, 0, true),
            ),
          )
        else ...[
          // Cover Flow Card Carousel with Left/Right Navigation Arrow Buttons
          SizedBox(
            height: 270.h,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PageView.builder(
                  controller: _propertiesPageController,
                  itemCount: properties.length,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _selectedPropertyIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final prop = properties[index];
                    final isSelected = index == _selectedPropertyIndex;

                    return AnimatedScale(
                      scale: isSelected ? 1.0 : 0.86,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      child: AnimatedOpacity(
                        opacity: isSelected ? 1.0 : 0.65,
                        duration: const Duration(milliseconds: 250),
                        child: _buildPropertyCoverCard(prop, index, isSelected),
                      ),
                    );
                  },
                ),

                // Left Arrow Navigation Button
                Positioned(
                  left: 12.w,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      if (_selectedPropertyIndex > 0) {
                        _propertiesPageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                        );
                      } else {
                        _propertiesPageController.animateToPage(
                          properties.length - 1,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                        );
                      }
                    },
                    child: Container(
                      width: 44.r,
                      height: 44.r,
                      decoration: BoxDecoration(
                        color: const Color(0xFF282B2E).withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.chevron_left_rounded,
                        color: Colors.white,
                        size: 28.r,
                      ),
                    ),
                  ),
                ),

                // Right Arrow Navigation Button
                Positioned(
                  right: 12.w,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      if (_selectedPropertyIndex < properties.length - 1) {
                        _propertiesPageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                        );
                      } else {
                        _propertiesPageController.animateToPage(
                          0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                        );
                      }
                    },
                    child: Container(
                      width: 44.r,
                      height: 44.r,
                      decoration: BoxDecoration(
                        color: const Color(0xFF282B2E).withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white,
                        size: 28.r,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 12.h),

          // Page Indicator Dots below Carousel
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              properties.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: EdgeInsets.symmetric(horizontal: 3.w),
                width: _selectedPropertyIndex == index ? 22.w : 7.w,
                height: 7.h,
                decoration: BoxDecoration(
                  color: _selectedPropertyIndex == index
                      ? AppColors.primary
                      : AppColors.sage.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6.r),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPropertyCoverCard(PropertyEntity prop, int index, bool isSelected) {
    const images = [
      'assets/images/property_cottage.png',
      'assets/images/property_villa.png',
      'assets/images/property_apartment.png',
    ];
    final String imagePath = images[index % images.length];
    final String title = prop.label;
    final String type = prop.city.isNotEmpty
        ? prop.city.toUpperCase()
        : (prop.isDefault ? 'PRIMARY' : 'RESIDENCE');
    final String address = prop.fullAddress;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 22,
              offset: const Offset(0, 10),
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22.r),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Property Photo Asset
            Image.asset(
              imagePath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppColors.primary,
                  child: const Center(
                    child: Icon(
                      Icons.home_work_rounded,
                      size: 64,
                      color: Colors.white54,
                    ),
                  ),
                );
              },
            ),

            // 2. Backdrop Blur Filter on Inactive Background Cards (matching design reference)
            if (!isSelected)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4.5, sigmaY: 4.5),
                  child: Container(color: Colors.black.withValues(alpha: 0.15)),
                ),
              ),

            // 3. Dark Gradient Overlay for Title readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.85),
                  ],
                ),
              ),
            ),

            // 4. Card Text & Badges Overlay (matching reference design bottom placement)
            Padding(
              padding: EdgeInsets.all(18.r),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type Badge (#636B2F Palette)
                  if (isSelected && type.isNotEmpty) ...[
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary, // #636B2F Palette Primary
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        type,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    SizedBox(height: 6.h),
                  ],

                  // Title
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isSelected ? 20.sp : 16.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),

                  // Location Subtitle with Pin Icon
                  if (isSelected && address.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14.r,
                          color: Colors.white70,
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            address,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (isSelected) ...[
                    SizedBox(height: 10.h),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onNavigateTab?.call(2);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_task_rounded,
                              size: 14.r,
                              color: AppColors.primaryDark,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              'Book a Service',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. ONGOING JOBS SECTION
  // ---------------------------------------------------------------------------
  Widget _buildOngoingJobsSection(List<JobAssignmentEntity> ongoingJobs) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4.w,
                    height: 16.h,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    context.loc.ongoingJobs,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.headlineColor(context),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      context.loc.activeCount(ongoingJobs.length),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onNavigateTab?.call(1); // Jobs tab
                },
                child: Text(
                  context.loc.viewAll,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          if (ongoingJobs.isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
              decoration: BoxDecoration(
                color: AppColors.cardColor(context),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: AppColors.borderColor(context)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    size: 36.r,
                    color: AppColors.mutedTextColor(context),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    context.loc.noOngoingJobs,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.headlineColor(context),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    context.loc.noOngoingJobsSubtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.sp,
                      color: AppColors.mutedTextColor(context),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ongoingJobs.length,
              separatorBuilder: (context, index) => SizedBox(height: 12.h),
              itemBuilder: (context, index) {
                final job = ongoingJobs[index];
                return _buildOngoingJobCard(job);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildOngoingJobCard(JobAssignmentEntity job) {
    final int currentStep = job.isInProgress ? 2 : 1;
    final steps = const ['Requested', 'Approved', 'In Progress', 'Completed'];

    final serviceName = job.jobRequest?.serviceCategory?.name ??
        (job.jobRequest?.description.isNotEmpty == true
            ? job.jobRequest!.description
            : 'Service Assignment #${job.id}');

    final propertyText = job.jobRequest?.property?.label.isNotEmpty == true
        ? '${job.jobRequest!.property!.label} • ${job.jobRequest!.property!.fullAddress}'
        : (job.jobRequest?.property?.fullAddress.isNotEmpty == true
            ? job.jobRequest!.property!.fullAddress
            : 'Service Location');

    final statusText = job.isInProgress
        ? 'IN PROGRESS'
        : (job.isScheduled
            ? 'SCHEDULED'
            : job.status.replaceAll('_', ' ').toUpperCase());

    final statusColor = job.isInProgress
        ? AppColors.accentLime
        : const Color(0xFFE5A00D);

    final providerName = job.providerName ?? (job.companyName ?? 'Assigned Pro');

    final scheduledTimeStr = job.startDate != null
        ? DateFormat('MMM dd, yyyy • hh:mm a').format(job.startDate!)
        : (job.assignedAt != null
            ? DateFormat('MMM dd, yyyy').format(job.assignedAt!)
            : 'Scheduled');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardColor(context),
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: AppColors.borderColor(context), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(20.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52.r,
                height: 52.r,
                decoration: BoxDecoration(
                  color: AppColors.cardSelectedColor(context),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Icon(
                  Icons.handyman_rounded,
                  color: AppColors.iconColor(context),
                  size: 26.r,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      serviceName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.headlineColor(context),
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 13.r,
                          color: AppColors.mutedTextColor(context),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Text(
                            propertyText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondaryTextColor(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  statusText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    color: statusColor == AppColors.accentLime
                        ? AppColors.primary
                        : statusColor,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 18.h),
          Divider(height: 1, color: AppColors.borderColor(context)),
          SizedBox(height: 18.h),

          // Schedule and Provider in a clean layout
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 18.r,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: Icon(
                  Icons.person_rounded,
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
                      providerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.headlineColor(context),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(
                          Icons.event_available_rounded,
                          size: 13.r,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            scheduledTimeStr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.mutedTextColor(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push(AppRoutes.jobDetails, extra: job);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.buttonBackground,
                    borderRadius: BorderRadius.circular(10.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.buttonBackground.withValues(
                          alpha: 0.3,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    context.loc.trackService,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.buttonText,
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 18.h),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.loc.serviceProgress,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mutedTextColor(context),
                ),
              ),
              SizedBox(height: 12.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(steps.length, (index) {
                  final isPassed = index <= currentStep;
                  final isCurrent = index == currentStep;

                  return Expanded(
                    child: Row(
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 24.r,
                              height: 24.r,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isPassed
                                    ? (isCurrent
                                        ? AppColors.primary
                                        : AppColors.primaryDark)
                                    : AppColors.borderColor(context),
                                border: isCurrent
                                    ? Border.all(
                                        color: AppColors.accentLime,
                                        width: 2.5,
                                      )
                                    : null,
                              ),
                              child: Center(
                                child: isPassed
                                    ? Icon(
                                        Icons.check_rounded,
                                        size: 14.r,
                                        color: Colors.white,
                                      )
                                    : Text(
                                        '${index + 1}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.mutedTextColor(
                                            context,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              steps[index],
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.sp,
                                fontWeight: isPassed
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isPassed
                                    ? AppColors.headlineColor(context)
                                    : AppColors.mutedTextColor(context),
                              ),
                            ),
                          ],
                        ),
                        if (index < steps.length - 1)
                          Expanded(
                            child: Container(
                              height: 2.h,
                              margin: EdgeInsets.only(bottom: 18.h),
                              color: index < currentStep
                                  ? AppColors.primaryDark
                                  : AppColors.borderColor(context),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. EXCLUSIVE OFFERS & PROMOS SECTION
  // ---------------------------------------------------------------------------
  Widget _buildOffersSection() {
    if (_offers.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4.w,
                    height: 16.h,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    context.loc.exclusiveOffers,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.headlineColor(context),
                    ),
                  ),
                ],
              ),
              Row(
                children: List.generate(
                  _offers.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: EdgeInsets.only(left: 4.w),
                    width: _selectedOfferIndex == index ? 16.w : 6.w,
                    height: 6.h,
                    decoration: BoxDecoration(
                      color: _selectedOfferIndex == index
                          ? AppColors.primary
                          : AppColors.borderUnselected,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        SizedBox(
          height: 168.h,
          child: PageView.builder(
            controller: _offersPageController,
            onPageChanged: (index) {
              setState(() {
                _selectedOfferIndex = index;
              });
            },
            itemCount: _offers.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final offer = _offers[index];
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: _buildOfferBannerCard(offer),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOfferBannerCard(Map<String, dynamic> offer) {
    final List<Color> gradientColors = offer['gradient'] as List<Color>;
    final Color accentColor = offer['accent'] as Color;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: EdgeInsets.all(18.r),
      child: Stack(
        children: [
          Positioned(
            right: -10.w,
            bottom: -15.h,
            child: Icon(
              offer['icon'] as IconData,
              size: 110.r,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.local_offer_rounded,
                          size: 12.r,
                          color: accentColor,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          (offer['badge'] ?? 'EXCLUSIVE OFFER').toString(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5.sp,
                            fontWeight: FontWeight.w800,
                            color: accentColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    (offer['discount'] ?? '').toString(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w900,
                      color: accentColor,
                    ),
                  ),
                ],
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (offer['title'] ?? '').toString(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    (offer['description'] ?? '').toString(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => _copyCouponCode((offer['code'] ?? '').toString()),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 5.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'CODE: ${offer['code']}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Icon(
                            Icons.copy_rounded,
                            size: 13.r,
                            color: accentColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _claimOffer(offer),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        'Claim Now',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textHeadline,
                        ),
                      ),
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

  // ---------------------------------------------------------------------------
  // HORIZONTAL SCROLLING SERVICE CATEGORIES SECTION
  // ---------------------------------------------------------------------------
  Widget _buildServiceCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4.w,
                    height: 16.h,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    context.loc.exploreServices,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.headlineColor(context),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push(AppRoutes.allServices);
                },
                child: Text(
                  context.loc.exploreAll,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),

        // Horizontal Scrolling Services List dynamically fetched from ServiceCategoryCubit
        SizedBox(
          height: 120.h,
          child: BlocBuilder<ServiceCategoryCubit, ServiceCategoryState>(
            builder: (context, state) {
              if (state is ServiceCategoryLoading) {
                return ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 4,
                  separatorBuilder: (context, index) => SizedBox(width: 12.w),
                  itemBuilder: (context, index) => Container(
                    width: 110.w,
                    decoration: BoxDecoration(
                      color: AppColors.cardColor(context),
                      borderRadius: BorderRadius.circular(18.r),
                      border: Border.all(color: AppColors.borderColor(context)),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 20.r,
                        height: 20.r,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                );
              }

              final activeCategories = (state is ServiceCategoryLoaded)
                  ? state.categories.where((c) => c.isActive).toList()
                  : <ServiceCategoryEntity>[];

              if (activeCategories.isEmpty) {
                return Center(
                  child: Text(
                    'No categories available',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: activeCategories.length,
                separatorBuilder: (context, index) => SizedBox(width: 12.w),
                itemBuilder: (context, index) {
                  final cat = activeCategories[index];
                  final String titleStr = cat.name;
                  final String? networkImageUrl = cat.imageUrl;
                  final visuals = _resolveCategoryVisuals(cat.name);
                  final String localAsset = (visuals['image'] ?? '').toString();
                  final IconData fallbackIcon =
                      (visuals['icon'] as IconData?) ?? Icons.design_services_rounded;

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.push(AppRoutes.allServices, extra: titleStr);
                    },
                    child: Container(
                      width: 110.w,
                      decoration: BoxDecoration(
                        color: AppColors.cardColor(context),
                        borderRadius: BorderRadius.circular(18.r),
                        border: Border.all(color: AppColors.borderColor(context)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.025),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 10.h,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 58.r,
                            height: 58.r,
                            child: networkImageUrl != null && networkImageUrl.isNotEmpty
                                ? Image.network(
                                    networkImageUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      if (localAsset.isNotEmpty) {
                                        return Image.asset(
                                          localAsset,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, _, _) => Icon(
                                            fallbackIcon,
                                            color: AppColors.primary,
                                            size: 36.r,
                                          ),
                                        );
                                      }
                                      return Icon(
                                        fallbackIcon,
                                        color: AppColors.primary,
                                        size: 36.r,
                                      );
                                    },
                                  )
                                : localAsset.isNotEmpty
                                    ? Image.asset(
                                        localAsset,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(
                                            fallbackIcon,
                                            color: AppColors.primary,
                                            size: 36.r,
                                          );
                                        },
                                      )
                                    : Icon(
                                        fallbackIcon,
                                        color: AppColors.primary,
                                        size: 36.r,
                                      ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            titleStr,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.headlineColor(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _resolveCategoryVisuals(String name) {
    final key = name.toLowerCase().trim();
    if (key.contains('clean')) {
      return {
        'image': 'assets/images/icon_cleaning.png',
        'icon': Icons.cleaning_services_rounded,
      };
    } else if (key.contains('plumb')) {
      return {
        'image': 'assets/images/icon_plumbing.png',
        'icon': Icons.plumbing_rounded,
      };
    } else if (key.contains('electr')) {
      return {
        'image': 'assets/images/icon_electrical.png',
        'icon': Icons.electrical_services_rounded,
      };
    } else if (key.contains('paint')) {
      return {
        'image': 'assets/images/icon_painting.png',
        'icon': Icons.format_paint_rounded,
      };
    } else if (key.contains('garden')) {
      return {
        'image': 'assets/images/icon_gardening.png',
        'icon': Icons.yard_rounded,
      };
    } else if (key.contains('appliance')) {
      return {
        'image': 'assets/images/icon_appliances.png',
        'icon': Icons.kitchen_rounded,
      };
    } else if (key.contains('hvac') || key.contains('ac')) {
      return {
        'image': 'assets/images/icon_electrical.png',
        'icon': Icons.hvac_rounded,
      };
    } else if (key.contains('secur')) {
      return {
        'image': 'assets/images/icon_electrical.png',
        'icon': Icons.shield_rounded,
      };
    }
    return {
      'image': '',
      'icon': Icons.design_services_rounded,
    };
  }

}
