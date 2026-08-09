import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer_app/core/constants/app_colors.dart';

class ServiceProvider {
  final String id;
  final String name;
  final String serviceType;
  final String rating;
  final int reviewsCount;
  final String price;
  final String distance;
  final String address;
  final String locationArea;
  final double lat; // offset relative to map center (-1.0 to 1.0)
  final double lng; // offset relative to map center (-1.0 to 1.0)
  final bool isAvailable;
  final IconData icon;

  const ServiceProvider({
    required this.id,
    required this.name,
    required this.serviceType,
    required this.rating,
    required this.reviewsCount,
    required this.price,
    required this.distance,
    required this.address,
    required this.locationArea,
    required this.lat,
    required this.lng,
    required this.isAvailable,
    required this.icon,
  });
}

class SearchTab extends StatefulWidget {
  final VoidCallback? onBackTap;

  const SearchTab({super.key, this.onBackTap});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final TextEditingController _serviceController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  String _selectedCategory = 'All';
  ServiceProvider? _selectedProvider;

  final List<String> _serviceCategories = [
    'All',
    'Cleaning',
    'Plumbing',
    'Electrical',
    'Painting',
    'Gardening',
    'HVAC',
  ];

  final List<ServiceProvider> _allProviders = const [
    ServiceProvider(
      id: 'p1',
      name: 'Alex Rivera',
      serviceType: 'Plumbing',
      rating: '4.9',
      reviewsCount: 142,
      price: '\$45/hr',
      distance: '0.8 km away',
      address: '742 Evergreen Terrace, Downtown',
      locationArea: 'Downtown',
      lat: -0.10,
      lng: -0.28,
      isAvailable: true,
      icon: Icons.plumbing_rounded,
    ),
    ServiceProvider(
      id: 'p2',
      name: 'CleanSpace Pro',
      serviceType: 'Cleaning',
      rating: '4.95',
      reviewsCount: 310,
      price: '\$55/hr',
      distance: '1.2 km away',
      address: '128 Pine Street, Midtown',
      locationArea: 'Midtown',
      lat: 0.20,
      lng: -0.12,
      isAvailable: true,
      icon: Icons.cleaning_services_rounded,
    ),
    ServiceProvider(
      id: 'p3',
      name: 'VoltExpert Electrical',
      serviceType: 'Electrical',
      rating: '4.8',
      reviewsCount: 98,
      price: '\$60/hr',
      distance: '2.4 km away',
      address: '55 Oak Avenue, Westside',
      locationArea: 'Westside',
      lat: 0.08,
      lng: 0.28,
      isAvailable: false,
      icon: Icons.electrical_services_rounded,
    ),
    ServiceProvider(
      id: 'p4',
      name: 'GreenThumb Landscaping',
      serviceType: 'Gardening',
      rating: '4.7',
      reviewsCount: 84,
      price: '\$40/hr',
      distance: '3.1 km away',
      address: '101 Birch Road, Eastside',
      locationArea: 'Eastside',
      lat: 0.35,
      lng: 0.42,
      isAvailable: true,
      icon: Icons.yard_rounded,
    ),
    ServiceProvider(
      id: 'p5',
      name: 'ProCoat Painters',
      serviceType: 'Painting',
      rating: '4.85',
      reviewsCount: 215,
      price: '\$50/hr',
      distance: '1.7 km away',
      address: '304 Maple Drive, Downtown',
      locationArea: 'Downtown',
      lat: -0.05,
      lng: 0.12,
      isAvailable: true,
      icon: Icons.format_paint_rounded,
    ),
    ServiceProvider(
      id: 'p6',
      name: 'CoolAir HVAC Solutions',
      serviceType: 'HVAC',
      rating: '4.9',
      reviewsCount: 176,
      price: '\$65/hr',
      distance: '2.0 km away',
      address: '88 Cedar Lane, Midtown',
      locationArea: 'Midtown',
      lat: -0.22,
      lng: -0.45,
      isAvailable: true,
      icon: Icons.hvac_rounded,
    ),
  ];

  @override
  void dispose() {
    _serviceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  List<ServiceProvider> get _filteredProviders {
    final serviceQuery = _serviceController.text.trim().toLowerCase();
    final locationQuery = _locationController.text.trim().toLowerCase();

    return _allProviders.where((provider) {
      final matchesCategory =
          _selectedCategory == 'All' ||
          provider.serviceType.toLowerCase() == _selectedCategory.toLowerCase();

      final matchesServiceQuery =
          serviceQuery.isEmpty ||
          provider.serviceType.toLowerCase().contains(serviceQuery) ||
          provider.name.toLowerCase().contains(serviceQuery);

      final matchesLocationQuery =
          locationQuery.isEmpty ||
          provider.address.toLowerCase().contains(locationQuery) ||
          provider.locationArea.toLowerCase().contains(locationQuery);

      return matchesCategory && matchesServiceQuery && matchesLocationQuery;
    }).toList();
  }

  void _showProviderDetails(ServiceProvider provider) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildProviderDetailSheet(provider),
    );
  }

  @override
  Widget build(BuildContext context) {
    final providers = _filteredProviders;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Top Search Header Block (with back button & dual-input card)
          _buildTopSearchHeaderBlock(),

          // Category Chips Bar
          _buildCategoryChipsBar(),

          // Map Area taking up remaining space
          Expanded(child: _buildMapView(providers)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TOP SEARCH HEADER BLOCK (DESIGN INTEGRATED AT TOP WITH BRAND COLOURS)
  // ---------------------------------------------------------------------------
  Widget _buildTopSearchHeaderBlock() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.borderUnselected, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        16.w,
        MediaQuery.of(context).padding.top + 6.h,
        16.w,
        16.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Bar Row: Back Button + Title
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (widget.onBackTap != null) {
                    widget.onBackTap!();
                  } else {
                    Navigator.maybePop(context);
                  }
                },
                child: Container(
                  width: 38.r,
                  height: 38.r,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F5F0),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.borderUnselected),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.textHeadline,
                      size: 20.r,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Find Nearby Providers',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textHeadline,
                ),
              ),
            ],
          ),

          SizedBox(height: 14.h),

          // Dual-Input Card matching reference design with white background & consistent border
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: AppColors.borderUnselected, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Service Type Row (Pickup style)
                    Row(
                      children: [
                        Transform.rotate(
                          angle: -0.6,
                          child: Icon(
                            Icons.navigation_rounded,
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
                                'SERVICE TYPE',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.5.sp,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textMuted,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(
                                height: 24.h,
                                child: TextField(
                                  controller: _serviceController,
                                  onChanged: (_) => setState(() {}),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textHeadline,
                                  ),
                                  decoration: InputDecoration(
                                    hintText:
                                        'Search service type (e.g. Plumbing, Cleaning)',
                                    hintStyle: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.5.sp,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textMuted.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_serviceController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _serviceController.clear();
                              setState(() {});
                            },
                            child: Icon(
                              Icons.close_rounded,
                              size: 18.r,
                              color: AppColors.textMuted,
                            ),
                          ),
                      ],
                    ),

                    // Divider Line
                    Padding(
                      padding: EdgeInsets.only(
                        left: 32.w,
                        top: 6.h,
                        bottom: 6.h,
                      ),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.borderUnselected,
                      ),
                    ),

                    // Location Row (Drop off style)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          color: Colors.redAccent,
                          size: 20.r,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LOCATION',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.5.sp,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textMuted,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(
                                height: 24.h,
                                child: TextField(
                                  controller: _locationController,
                                  onChanged: (_) => setState(() {}),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textHeadline,
                                  ),
                                  decoration: InputDecoration(
                                    hintText:
                                        'Search location or area (e.g. Downtown)',
                                    hintStyle: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.5.sp,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textMuted.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_locationController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _locationController.clear();
                              setState(() {});
                            },
                            child: Icon(
                              Icons.close_rounded,
                              size: 18.r,
                              color: AppColors.textMuted,
                            ),
                          )
                        else
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _locationController.text = 'Downtown';
                              setState(() {});
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.cardSelectedBg,
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                  color: AppColors.borderUnselected,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.my_location_rounded,
                                    size: 12.r,
                                    color: AppColors.primary,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    'Near me',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                // Dotted connecting line between icons
                Positioned(
                  left: 9.w,
                  top: 22.h,
                  child: Column(
                    children: List.generate(
                      3,
                      (index) => Container(
                        width: 2.w,
                        height: 3.h,
                        margin: EdgeInsets.symmetric(vertical: 1.5.h),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(1.r),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CATEGORY CHIPS BAR WITH BRAND COLOR CONSISTENCY
  // ---------------------------------------------------------------------------
  Widget _buildCategoryChipsBar() {
    return Container(
      height: 48.h,
      color: Colors.white,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        scrollDirection: Axis.horizontal,
        itemCount: _serviceCategories.length,
        separatorBuilder: (_, _) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          final category = _serviceCategories[index];
          final isSelected = _selectedCategory == category;
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _selectedCategory = category;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.cardSelectedBg,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.borderUnselected,
                ),
              ),
              child: Text(
                category,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MAP VIEW WITH FULL CANVAS & INTERACTIVE PINS
  // ---------------------------------------------------------------------------
  Widget _buildMapView(List<ServiceProvider> providers) {
    return Stack(
      children: [
        // 1. Map Canvas Background
        Positioned.fill(
          child: Container(
            color: const Color(0xFFF3F4F1),
            child: CustomPaint(painter: UberStyleMapPainter()),
          ),
        ),

        // 2. Interactive Provider Price Pins & Center Pin Marker
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final center = Offset(
                constraints.maxWidth / 2,
                constraints.maxHeight / 2 - 20.h,
              );

              return Stack(
                children: [
                  // Center Location Marker Pin
                  Positioned(
                    left: center.dx - 12.w,
                    top: center.dy - 12.h,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 24.r,
                          height: 24.r,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 6.r,
                              height: 6.r,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 2.w,
                          height: 10.h,
                          color: AppColors.primaryDark,
                        ),
                      ],
                    ),
                  ),

                  // Provider Price Badges ($45/hr, $60/hr...)
                  ...providers.map((provider) {
                    final pinX =
                        center.dx +
                        (provider.lng * (constraints.maxWidth * 0.42));
                    final pinY =
                        center.dy +
                        (provider.lat * (constraints.maxHeight * 0.38));
                    final isSelected = _selectedProvider?.id == provider.id;

                    return Positioned(
                      left: pinX - 38.w,
                      top: pinY - 18.h,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedProvider = provider;
                          });
                          _showProviderDetails(provider);
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 5.h,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.primaryDark.withValues(
                                          alpha: 0.3,
                                        ),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    provider.icon,
                                    size: 14.r,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.primary,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    provider.price,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5.sp,
                                      fontWeight: FontWeight.w800,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textHeadline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down_rounded,
                              size: 18.r,
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.white,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ),

        // 3. Floating Count Badge: "6 service providers nearby"
        Positioned(
          top: 14.h,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.darkHeaderBg,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Text(
                '${providers.length} service provider${providers.length == 1 ? '' : 's'} nearby',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),

        // 4. Floating GPS Location Re-center Button (Bottom Right)
        Positioned(
          right: 16.w,
          bottom: 24.h,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _locationController.text = 'Current Location';
              setState(() {});
            },
            child: Container(
              width: 46.r,
              height: 46.r,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderUnselected),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.my_location_rounded,
                  color: AppColors.primary,
                  size: 22.r,
                ),
              ),
            ),
          ),
        ),

        // 5. Quick Selected Provider Floating Card at bottom left if a provider is selected
        if (_selectedProvider != null)
          Positioned(
            left: 16.w,
            right: 74.w,
            bottom: 24.h,
            child: GestureDetector(
              onTap: () => _showProviderDetails(_selectedProvider!),
              child: Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42.r,
                      height: 42.r,
                      decoration: BoxDecoration(
                        color: AppColors.cardSelectedBg,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        _selectedProvider!.icon,
                        color: AppColors.primary,
                        size: 22.r,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedProvider!.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textHeadline,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${_selectedProvider!.price} • ${_selectedProvider!.distance}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // PROVIDER DETAILS MODAL BOTTOM SHEET
  // ---------------------------------------------------------------------------
  Widget _buildProviderDetailSheet(ServiceProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 30.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Container(
                width: 56.r,
                height: 56.r,
                decoration: BoxDecoration(
                  color: AppColors.cardSelectedBg,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  provider.icon,
                  color: AppColors.primary,
                  size: 28.r,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textHeadline,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '${provider.serviceType} Specialist • ${provider.distance}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 16.r,
                          color: Colors.amber,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '${provider.rating} (${provider.reviewsCount} reviews)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rate',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.sp,
                      color: AppColors.textMuted,
                    ),
                  ),
                  Text(
                    provider.price,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              SizedBox(width: 20.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Contacting ${provider.name}...'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: Text(
                    'Book Provider',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
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
}

// ---------------------------------------------------------------------------
// MAP PAINTER MATCHING UBER STYLE DESIGN WITH ROADS, DASHED TRACKS & CARS
// ---------------------------------------------------------------------------
class UberStyleMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Background Land
    final landPaint = Paint()..color = const Color(0xFFF2F2EE);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), landPaint);

    // 2. Building footprint blocks
    final buildingPaint = Paint()
      ..color = const Color(0xFFE2E3DF)
      ..style = PaintingStyle.fill;

    final buildingBorderPaint = Paint()
      ..color = const Color(0xFFD4D5D0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final buildings = [
      RRect.fromRectAndRadius(
        Rect.fromLTWH(20.w, 80.h, 120.w, 90.h),
        Radius.circular(12.r),
      ),
      RRect.fromRectAndRadius(
        Rect.fromLTWH(160.w, 40.h, 140.w, 60.h),
        Radius.circular(10.r),
      ),
      RRect.fromRectAndRadius(
        Rect.fromLTWH(220.w, 140.h, 110.w, 120.h),
        Radius.circular(14.r),
      ),
      RRect.fromRectAndRadius(
        Rect.fromLTWH(40.w, 240.h, 100.w, 130.h),
        Radius.circular(12.r),
      ),
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width - 100.w, 20.h, 80.w, 150.h),
        Radius.circular(10.r),
      ),
    ];

    for (final b in buildings) {
      canvas.drawRRect(b, buildingPaint);
      canvas.drawRRect(b, buildingBorderPaint);
    }

    // 3. Roads
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 18.w
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final roadOutlinePaint = Paint()
      ..color = const Color(0xFFDCDEC8)
      ..strokeWidth = 20.w
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Path roadPath = Path();

    // Main Diagonal Avenue
    roadPath.moveTo(-20, size.height * 0.15);
    roadPath.lineTo(size.width + 20, size.height * 0.55);

    // Cross Street 1
    roadPath.moveTo(size.width * 0.2, 0);
    roadPath.lineTo(size.width * 0.85, size.height * 0.7);

    // Horizontal Connectors
    roadPath.moveTo(0, size.height * 0.35);
    roadPath.lineTo(size.width, size.height * 0.35);

    roadPath.moveTo(0, size.height * 0.18);
    roadPath.lineTo(size.width, size.height * 0.18);

    canvas.drawPath(roadPath, roadOutlinePaint);
    canvas.drawPath(roadPath, roadPaint);

    // 4. Dashed Navigation Route Lines
    final dashPaint = Paint()
      ..color = Colors.grey.shade600
      ..strokeWidth = 2.w
      ..style = PaintingStyle.stroke;

    final Path dashPath = Path();
    dashPath.moveTo(size.width * 0.15, size.height * 0.2);
    dashPath.lineTo(size.width * 0.55, size.height * 0.38);

    _drawDashedPath(canvas, dashPath, dashPaint, [6, 4]);

    // 5. Draw Black Cars / Vehicles on Map
    _drawCar(canvas, Offset(size.width * 0.82, size.height * 0.12), -0.4);
    _drawCar(canvas, Offset(size.width * 0.76, size.height * 0.28), -0.4);
    _drawCar(canvas, Offset(size.width * 0.28, size.height * 0.36), 0.5);
  }

  void _drawCar(Canvas canvas, Offset center, double angle) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final carShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(2, 3), width: 18.w, height: 32.h),
        Radius.circular(6.r),
      ),
      carShadow,
    );

    final carBody = Paint()..color = const Color(0xFF1E1E1E);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 18.w, height: 32.h),
        Radius.circular(6.r),
      ),
      carBody,
    );

    final carRoof = Paint()..color = const Color(0xFF383838);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, -1), width: 14.w, height: 18.h),
        Radius.circular(4.r),
      ),
      carRoof,
    );

    final windshield = Paint()..color = const Color(0xFF888888);
    canvas.drawRect(
      Rect.fromCenter(center: const Offset(0, -6), width: 12.w, height: 3.h),
      windshield,
    );

    canvas.restore();
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint,
    List<double> dashArray,
  ) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final double length = draw ? dashArray[0] : dashArray[1];
        if (draw) {
          canvas.drawPath(
            metric.extractPath(distance, distance + length),
            paint,
          );
        }
        distance += length;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
