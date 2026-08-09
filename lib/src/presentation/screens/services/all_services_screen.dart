import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/src/presentation/widgets/dynamic_island_toast.dart';

class AllServicesScreen extends StatefulWidget {
  final String? initialCategory;

  const AllServicesScreen({
    super.key,
    this.initialCategory,
  });

  @override
  State<AllServicesScreen> createState() => _AllServicesScreenState();
}

class _AllServicesScreenState extends State<AllServicesScreen> {
  final TextEditingController _searchController = TextEditingController();
  late String _selectedCategory;

  final List<String> _categories = [
    'All',
    'Cleaning',
    'Plumbing',
    'Electrical',
    'Painting',
    'Gardening',
    'Appliances',
    'HVAC',
    'Security',
  ];

  final List<Map<String, dynamic>> _allServices = [
    {
      'id': 'SRV-01',
      'title': 'Deep Home Sanitization',
      'category': 'Cleaning',
      'price': 'From \$89',
      'rating': '4.9',
      'reviews': '1,240',
      'badge': 'Popular',
      'image': 'assets/images/icon_cleaning.png',
      'icon': Icons.cleaning_services_rounded,
      'description': 'Full house deep cleaning with eco-friendly sanitization solutions.',
    },
    {
      'id': 'SRV-02',
      'title': 'Emergency Pipe Repair',
      'category': 'Plumbing',
      'price': 'From \$75',
      'rating': '4.8',
      'reviews': '850',
      'badge': 'Fast 30m',
      'image': 'assets/images/icon_plumbing.png',
      'icon': Icons.plumbing_rounded,
      'description': 'Leak detection, pipe replacement, and drain unclogging by certified pros.',
    },
    {
      'id': 'SRV-03',
      'title': 'Electrical Inspection',
      'category': 'Electrical',
      'price': 'From \$69',
      'rating': '4.9',
      'reviews': '940',
      'badge': 'Certified',
      'image': 'assets/images/icon_electrical.png',
      'icon': Icons.electrical_services_rounded,
      'description': 'Fuse box check, wiring repairs, and lighting fixture installations.',
    },
    {
      'id': 'SRV-04',
      'title': 'Interior & Wall Painting',
      'category': 'Painting',
      'price': 'From \$199',
      'rating': '4.8',
      'reviews': '430',
      'badge': 'Top Rated',
      'image': 'assets/images/icon_painting.png',
      'icon': Icons.format_paint_rounded,
      'description': 'Premium finish wall coating, drywall patching, and exterior painting.',
    },
    {
      'id': 'SRV-05',
      'title': 'Lawn Care & Landscape',
      'category': 'Gardening',
      'price': 'From \$55',
      'rating': '4.7',
      'reviews': '620',
      'badge': 'Eco Friendly',
      'image': 'assets/images/icon_gardening.png',
      'icon': Icons.yard_rounded,
      'description': 'Grass mowing, hedge trimming, weed removal, and soil health testing.',
    },
    {
      'id': 'SRV-06',
      'title': 'Refrigerator & Appliance Fix',
      'category': 'Appliances',
      'price': 'From \$85',
      'rating': '4.9',
      'reviews': '1,110',
      'badge': 'Warranty',
      'image': 'assets/images/icon_appliances.png',
      'icon': Icons.kitchen_rounded,
      'description': 'Washing machine, fridge, oven, and microwave diagnosis and repair.',
    },
    {
      'id': 'SRV-07',
      'title': 'AC & HVAC Maintenance',
      'category': 'HVAC',
      'price': 'From \$95',
      'rating': '4.9',
      'reviews': '1,050',
      'badge': 'Best Seller',
      'image': 'assets/images/icon_electrical.png',
      'icon': Icons.hvac_rounded,
      'description': 'Air filter replacement, coolant refill, and duct cleaning.',
    },
    {
      'id': 'SRV-08',
      'title': 'Smart Home Security Setup',
      'category': 'Security',
      'price': 'From \$149',
      'rating': '4.9',
      'reviews': '510',
      'badge': '24/7 Shield',
      'image': 'assets/images/icon_electrical.png',
      'icon': Icons.shield_rounded,
      'description': 'CCTV camera installation, smart lock setup, and alarm configuration.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'All';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredServices {
    return _allServices.where((srv) {
      final matchesCategory = _selectedCategory == 'All' || srv['category'] == _selectedCategory;
      final query = _searchController.text.toLowerCase().trim();
      final matchesQuery = query.isEmpty ||
          (srv['title'] as String).toLowerCase().contains(query) ||
          (srv['category'] as String).toLowerCase().contains(query) ||
          (srv['description'] as String).toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final services = _filteredServices;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textHeadline),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'All Registered Services',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.textHeadline,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppColors.primary),
            onPressed: () {
              HapticFeedback.lightImpact();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Bar Container
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
            child: Container(
              height: 48.h,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: AppColors.borderUnselected),
              ),
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search for any home service or repair...',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          color: AppColors.textMuted,
                          fontSize: 13.5.sp,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      child: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                    ),
                ],
              ),
            ),
          ),

          // 2. Category Filter Chips (Horizontal)
          Container(
            height: 48.h,
            color: Colors.white,
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (context, index) => SizedBox(width: 8.w),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _selectedCategory = cat;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.cardSelectedBg,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.borderUnselected,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5.sp,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          SizedBox(height: 12.h),

          // 3. Registered Services Grid Cards
          Expanded(
            child: services.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 54.r, color: AppColors.radioUnselected),
                        SizedBox(height: 12.h),
                        Text(
                          'No services found matching your query',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textMuted,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 30.h),
                    physics: const BouncingScrollPhysics(),
                    itemCount: services.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14.w,
                      mainAxisSpacing: 14.h,
                      childAspectRatio: 0.76,
                    ),
                    itemBuilder: (context, index) {
                      final service = services[index];
                      return _buildRegisteredServiceCard(service);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisteredServiceCard(Map<String, dynamic> srv) {
    final String imagePath = (srv['image'] ?? '').toString();
    final String title = (srv['title'] ?? '').toString();
    final String price = (srv['price'] ?? '').toString();
    final String rating = (srv['rating'] ?? '').toString();
    final String badge = (srv['badge'] ?? '').toString();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.borderUnselected),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(14.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Badge & Favorite Trigger Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Icon(
                Icons.star_rounded,
                color: const Color(0xFFE5A00D),
                size: 16.r,
              ),
            ],
          ),

          SizedBox(height: 10.h),

          // Center Prominent Line Art Clip Art
          Center(
            child: SizedBox(
              width: 60.r,
              height: 60.r,
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    (srv['icon'] as IconData?) ?? Icons.build_rounded,
                    color: AppColors.primary,
                    size: 38.r,
                  );
                },
              ),
            ),
          ),

          const Spacer(),

          // Service Title
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.textHeadline,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          SizedBox(height: 4.h),

          // Rating & Reviews Subtitle
          Row(
            children: [
              Text(
                '$rating ★',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textHeadline,
                ),
              ),
              SizedBox(width: 4.w),
              Text(
                '(${srv['reviews']})',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.sp,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),

          SizedBox(height: 10.h),

          // Bottom Price & Book Now Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                price,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showBookingConfirmationModal(srv);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: AppColors.buttonBackground,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    'Book',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.buttonText,
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

  void _showBookingConfirmationModal(Map<String, dynamic> srv) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
          ),
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 36.h),
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
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
              SizedBox(height: 18.h),
              Text(
                'Book ${srv['title']}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textHeadline,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                srv['description'] as String,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 20.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Service Price',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                  Text(
                    srv['price'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonBackground,
                    foregroundColor: AppColors.buttonText,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    DynamicIslandToast.showSuccess(context, 'Booking request sent for ${srv['title']}!');
                  },
                  child: Text(
                    'Confirm & Schedule Service',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
