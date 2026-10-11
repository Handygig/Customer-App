import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/src/presentation/screens/services/all_services_screen.dart';
import 'package:customer_app/src/presentation/widgets/dynamic_island_toast.dart';
import 'package:customer_app/src/presentation/screens/jobs/job_details_screen.dart';

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
  final PageController _propertiesPageController = PageController(
    viewportFraction: 0.78,
    initialPage:
        999, // 999 is a multiple of 3 (999 % 3 == 0) for seamless infinite looping
  );

  // Mock properties data with high quality cover image assets
  final List<Map<String, dynamic>> _properties = [
    {
      'title': 'Rosewood Cottage',
      'type': 'VILLA',
      'address': 'Kandy Suburbs',
      'sqft': '3,400 sq ft',
      'image': 'assets/images/property_cottage.png',
      'color': AppColors.primary,
      'activeJobs': 2,
      'isPrimary': true,
    },
    {
      'title': 'Sunset Luxury Villa',
      'type': 'RESORT',
      'address': '742 Evergreen Terrace, SF',
      'sqft': '4,200 sq ft',
      'image': 'assets/images/property_villa.png',
      'color': AppColors.primaryLight,
      'activeJobs': 1,
      'isPrimary': false,
    },
    {
      'title': 'Astra Tower Penthouse',
      'type': 'APARTMENT',
      'address': '104 Market St, Suite 4B, SF',
      'sqft': '1,850 sq ft',
      'image': 'assets/images/property_apartment.png',
      'color': AppColors.primaryDark,
      'activeJobs': 0,
      'isPrimary': false,
    },
  ];

  // Mock ongoing jobs data
  final List<Map<String, dynamic>> _ongoingJobs = [
    {
      'id': 'JOB-9842',
      'service': 'Deep Home Sanitization & Cleaning',
      'property': 'Rosewood Cottage',
      'providerName': 'David Miller (Pro Cleaner)',
      'providerRating': '4.9 ★',
      'status': 'In Progress',
      'progress': 0.65,
      'statusColor': AppColors.accentLime,
      'scheduledTime': 'Today • 02:00 PM - 05:00 PM',
      'category': 'Cleaning',
      'icon': Icons.cleaning_services_rounded,
    },
    {
      'id': 'JOB-9845',
      'service': 'HVAC Filter & Air Quality Service',
      'property': 'Sunset Luxury Villa',
      'providerName': 'Marcus Vance (Certified Tech)',
      'providerRating': '4.8 ★',
      'status': 'Pro En Route',
      'progress': 0.35,
      'statusColor': const Color(0xFFE5A00D),
      'scheduledTime': 'Today • 04:30 PM',
      'category': 'AC & HVAC',
      'icon': Icons.hvac_rounded,
    },
  ];

  // Mock offers data using user palette colors (#636B2F, #BAC095, #D4DE95, #3D4127)
  final List<Map<String, dynamic>> _offers = [
    {
      'badge': 'EXCLUSIVE OFFER',
      'title': 'Spring Deep Cleaning',
      'discount': '30% OFF',
      'description': 'Complete home sanitization with eco-safe solutions',
      'code': 'CLEAN30',
      'gradient': [
        AppColors.primaryDark, // #3D4127
        AppColors.primary, // #636B2F
        AppColors.sage, // #BAC095
      ],
      'accent': AppColors.accentLime, // #D4DE95
      'icon': Icons.auto_awesome_rounded,
    },
    {
      'badge': 'SEASONAL SPECIAL',
      'title': 'Lawn & Garden Care',
      'discount': 'FREE SOIL TEST',
      'description': 'Book 2 garden trimming sessions & get free soil analysis',
      'code': 'GARDENFREE',
      'gradient': [
        AppColors.primary, // #636B2F
        AppColors.primaryDark, // #3D4127
        AppColors.sage, // #BAC095
      ],
      'accent': AppColors.accentLime,
      'icon': Icons.yard_rounded,
    },
    {
      'badge': 'MAINTENANCE PACK',
      'title': 'HVAC & Plumbing Check',
      'discount': '\$50 CASHBACK',
      'description': 'Certified inspection for air filters and water pipes',
      'code': 'SECURE50',
      'gradient': [
        AppColors.primaryDark,
        AppColors.primary,
        AppColors.primaryDark,
      ],
      'accent': AppColors.accentLime,
      'icon': Icons.shield_rounded,
    },
  ];

  // Service categories with custom line art clip arts matching palette (#636B2F)
  final List<Map<String, dynamic>> _serviceCategories = [
    {
      'title': 'Cleaning',
      'image': 'assets/images/icon_cleaning.png',
      'icon': Icons.cleaning_services_rounded,
      'color': const Color(0xFFF2F5ED),
    },
    {
      'title': 'Plumbing',
      'image': 'assets/images/icon_plumbing.png',
      'icon': Icons.plumbing_rounded,
      'color': const Color(0xFFF2F5ED),
    },
    {
      'title': 'Electrical',
      'image': 'assets/images/icon_electrical.png',
      'icon': Icons.electrical_services_rounded,
      'color': const Color(0xFFF2F5ED),
    },
    {
      'title': 'Painting',
      'image': 'assets/images/icon_painting.png',
      'icon': Icons.format_paint_rounded,
      'color': const Color(0xFFF2F5ED),
    },
    {
      'title': 'Gardening',
      'image': 'assets/images/icon_gardening.png',
      'icon': Icons.yard_rounded,
      'color': const Color(0xFFF2F5ED),
    },
    {
      'title': 'Appliances',
      'image': 'assets/images/icon_appliances.png',
      'icon': Icons.kitchen_rounded,
      'color': const Color(0xFFF2F5ED),
    },
  ];

  @override
  void initState() {
    super.initState();
  }

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
                await Future.delayed(const Duration(milliseconds: 1200));
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
                    _buildCoverFlowPropertiesSection(),

                    SizedBox(height: 16.h),

                    // 2. Explore Services (Horizontal Scrolling Section)
                    _buildServiceCategoriesSection(),

                    SizedBox(height: 16.h),

                    // 3. Ongoing Jobs Section
                    _buildOngoingJobsSection(),

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
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 44.r,
                      height: 44.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2),
                        color: AppColors.primary,
                      ),
                      child: Center(
                        child: Text(
                          'A',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Good Morning, Alex',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.headlineColor(context),
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w800,
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
                      'Search for cleaning, repairs, plumbing...',
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
  Widget _buildCoverFlowPropertiesSection() {
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
                    'Added Properties',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.headlineColor(context),
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    '(${_properties.length})',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mutedTextColor(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),

        // Cover Flow Card Carousel with Left/Right Navigation Arrow Buttons
        SizedBox(
          height: 270.h,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // PageView Carousel with Infinite Looping & Blurred Background Depth
              PageView.builder(
                controller: _propertiesPageController,
                onPageChanged: (index) {
                  setState(() {
                    _selectedPropertyIndex = index % _properties.length;
                  });
                },
                itemBuilder: (context, index) {
                  final realIndex = index % _properties.length;
                  final prop = _properties[realIndex];
                  final isSelected = realIndex == _selectedPropertyIndex;

                  return AnimatedScale(
                    scale: isSelected ? 1.0 : 0.84,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    child: AnimatedOpacity(
                      opacity: isSelected ? 1.0 : 0.6,
                      duration: const Duration(milliseconds: 250),
                      child: _buildPropertyCoverCard(prop, isSelected),
                    ),
                  );
                },
              ),

              // Left Infinite Arrow Navigation Button
              Positioned(
                left: 12.w,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _propertiesPageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                    );
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

              // Right Infinite Arrow Navigation Button
              Positioned(
                right: 12.w,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _propertiesPageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                    );
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
            _properties.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: EdgeInsets.symmetric(horizontal: 3.w),
              width: _selectedPropertyIndex == index ? 22.w : 7.w,
              height: 7.h,
              decoration: BoxDecoration(
                color: _selectedPropertyIndex == index
                    ? AppColors
                          .primary // #636B2F
                    : AppColors.sage.withValues(alpha: 0.5), // #BAC095
                borderRadius: BorderRadius.circular(6.r),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyCoverCard(Map<String, dynamic> prop, bool isSelected) {
    final String imagePath = (prop['image'] ?? '').toString();
    final String title = (prop['title'] ?? '').toString();
    final String type = (prop['type'] ?? '').toString();
    final String address = (prop['address'] ?? '').toString();

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
                  color: (prop['color'] as Color?) ?? AppColors.primary,
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
  Widget _buildOngoingJobsSection() {
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
                    'Ongoing Jobs',
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
                      '${_ongoingJobs.length} Active',
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
                  'View All',
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

          ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _ongoingJobs.length,
            separatorBuilder: (context, index) => SizedBox(height: 12.h),
            itemBuilder: (context, index) {
              final job = _ongoingJobs[index];
              return _buildOngoingJobCard(job);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOngoingJobCard(Map<String, dynamic> job) {
    final String type = job['type'] as String? ?? 'ongoing';
    final int currentStep = switch (type) {
      'waiting' => 0,
      'to_approve' => 1,
      'ongoing' => 2,
      'completed' => 3,
      _ => 2,
    };

    final steps = ['Requested', 'Approved', 'In Progress', 'Completed'];

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
                  job['icon'] as IconData,
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
                      job['service'] as String,
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
                        Text(
                          job['property'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryTextColor(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: (job['statusColor'] as Color).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: (job['statusColor'] as Color).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  job['status'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    color: (job['statusColor'] as Color) == AppColors.accentLime
                        ? AppColors.primary
                        : job['statusColor'] as Color,
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
                      job['providerName'] as String,
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
                        Text(
                          job['scheduledTime'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.mutedTextColor(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => JobDetailsScreen(job: job),
                    ),
                  );
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
                    'Track',
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
                'Service Progress',
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
                    'Exclusive Offers & Discounts',
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
                          offer['badge'] as String,
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
                    offer['discount'] as String,
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
                    offer['title'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    offer['description'] as String,
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
                    onTap: () => _copyCouponCode(offer['code'] as String),
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
                    onTap: () {
                      HapticFeedback.lightImpact();
                      widget.onNavigateTab?.call(2);
                    },
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
                    'Explore Services',
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
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AllServicesScreen(),
                    ),
                  );
                },
                child: Text(
                  'Explore All',
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

        // Horizontal Scrolling Services List without circle containers & larger clip arts
        SizedBox(
          height: 120.h,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _serviceCategories.length,
            separatorBuilder: (context, index) => SizedBox(width: 12.w),
            itemBuilder: (context, index) {
              final cat = _serviceCategories[index];
              final String imagePath = (cat['image'] ?? '').toString();
              final String titleStr = (cat['title'] ?? '').toString();

              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          AllServicesScreen(initialCategory: titleStr),
                    ),
                  );
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
                      // Prominent Large Line Art Clip Art (without background circle)
                      SizedBox(
                        width: 58.r,
                        height: 58.r,
                        child: Image.asset(
                          imagePath,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              (cat['icon'] as IconData?) ??
                                  Icons.design_services_rounded,
                              color: AppColors.primary,
                              size: 36.r,
                            );
                          },
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
          ),
        ),
      ],
    );
  }

}
