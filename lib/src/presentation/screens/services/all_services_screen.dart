import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/src/domain/entities/services/service_entity.dart';
import 'package:customer_app/src/presentation/cubits/services/service_category_cubit.dart';
import 'package:customer_app/src/presentation/cubits/services/service_category_state.dart';
import 'package:customer_app/src/presentation/cubits/services/service_cubit.dart';
import 'package:customer_app/src/presentation/cubits/services/service_state.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_app/config/router/app_routes.dart';

class AllServicesScreen extends StatefulWidget {
  final String? initialCategory;

  const AllServicesScreen({super.key, this.initialCategory});

  @override
  State<AllServicesScreen> createState() => _AllServicesScreenState();
}

class _AllServicesScreenState extends State<AllServicesScreen> {
  final TextEditingController _searchController = TextEditingController();
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'All';

    // Ensure services and categories are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServiceCategoryCubit>().loadCategories();
      context.read<ServiceCubit>().loadServices();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      context.read<ServiceCategoryCubit>().loadCategories(forceRefresh: true),
      context.read<ServiceCubit>().loadServices(forceRefresh: true),
    ]);
  }

  List<ServiceEntity> _filterServices(List<ServiceEntity> allServices) {
    return allServices.where((srv) {
      final matchesCategory = _selectedCategory == 'All' ||
          (srv.category ?? '').toLowerCase().trim() ==
              _selectedCategory.toLowerCase().trim();

      final query = _searchController.text.toLowerCase().trim();
      final matchesQuery = query.isEmpty ||
          srv.title.toLowerCase().contains(query) ||
          srv.name.toLowerCase().contains(query) ||
          (srv.category ?? '').toLowerCase().contains(query) ||
          (srv.description ?? '').toLowerCase().contains(query);

      return matchesCategory && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primaryDark,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'All Services',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryDark,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.tune_rounded,
              color: AppColors.primary,
              size: 22,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.primary,
        child: Column(
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
                    const Icon(
                      Icons.search_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
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
                        child: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // 2. Category Filter Chips (Horizontal)
            Container(
              height: 48.h,
              color: Colors.white,
              child: BlocBuilder<ServiceCategoryCubit, ServiceCategoryState>(
                builder: (context, state) {
                  final List<String> categories = ['All'];
                  if (state is ServiceCategoryLoaded) {
                    final names = state.categories
                        .where((c) => c.isActive)
                        .map((c) => c.name)
                        .toList();
                    categories.addAll(names);
                  }

                  return ListView.separated(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: categories.length,
                    separatorBuilder: (context, index) => SizedBox(width: 8.w),
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final isSelected = _selectedCategory == cat;

                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _selectedCategory = cat;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 6.h,
                          ),
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
                            cat,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5.sp,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            SizedBox(height: 12.h),

            // 3. Registered Services Grid Cards
            Expanded(
              child: BlocBuilder<ServiceCubit, ServiceState>(
                builder: (context, state) {
                  if (state is ServiceLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }

                  if (state is ServiceError) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 48.r,
                              color: Colors.redAccent,
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              state.message,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.textSecondary,
                                fontSize: 13.5.sp,
                              ),
                            ),
                            SizedBox(height: 16.h),
                            ElevatedButton(
                              onPressed: () => context
                                  .read<ServiceCubit>()
                                  .loadServices(forceRefresh: true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final allServices = (state is ServiceLoaded)
                      ? state.services.where((s) => s.isActive).toList()
                      : <ServiceEntity>[];

                  final services = _filterServices(allServices);

                  if (services.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 54.r,
                            color: AppColors.radioUnselected,
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            allServices.isEmpty
                                ? 'No services available yet'
                                : 'No services found matching your query',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.textMuted,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 30.h),
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisteredServiceCard(ServiceEntity srv) {
    final String title = srv.title.isNotEmpty ? srv.title : srv.name;
    final String? networkImage = srv.imageUrl;
    final String categoryName = srv.category ?? '';
    final visuals = _resolveVisuals(title, categoryName);
    final String localAsset = visuals['image'] ?? '';
    final IconData fallbackIcon = visuals['icon'] ?? Icons.build_rounded;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _navigateToMapSearch(srv);
      },
      child: Container(
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
            // Top Category Badge Row
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    categoryName.isNotEmpty ? categoryName : 'Service',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 10.h),

            // Center Service Image / Visual
            Center(
              child: SizedBox(
                width: 60.r,
                height: 60.r,
                child: networkImage != null && networkImage.isNotEmpty
                    ? Image.network(
                        networkImage,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          if (localAsset.isNotEmpty) {
                            return Image.asset(
                              localAsset,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => Icon(
                                fallbackIcon,
                                color: AppColors.primary,
                                size: 38.r,
                              ),
                            );
                          }
                          return Icon(
                            fallbackIcon,
                            color: AppColors.primary,
                            size: 38.r,
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
                                size: 38.r,
                              );
                            },
                          )
                        : Icon(
                            fallbackIcon,
                            color: AppColors.primary,
                            size: 38.r,
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

            // Description or Category Subtitle
            Text(
              srv.description?.isNotEmpty == true
                  ? srv.description!
                  : categoryName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.sp,
                color: AppColors.textMuted,
              ),
            ),

            SizedBox(height: 12.h),

            // Bottom Search Button
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _navigateToMapSearch(srv);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.buttonBackground,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_rounded,
                          size: 15.r,
                          color: AppColors.buttonText,
                        ),
                        SizedBox(width: 6.w),
                        Flexible(
                          child: Text(
                            'Search',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.buttonText,
                            ),
                          ),
                        ),
                      ],
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

  void _navigateToMapSearch(ServiceEntity srv) {
    final String serviceName = srv.title.isNotEmpty ? srv.title : srv.name;
    context.push(
      AppRoutes.providerSearch,
      extra: {
        'service': serviceName,
        'category': srv.category,
        'categoryId': srv.categoryId,
      },
    );
  }

  Map<String, dynamic> _resolveVisuals(String title, String category) {
    final key = '$title $category'.toLowerCase();
    if (key.contains('clean')) {
      return {
        'image': 'assets/images/icon_cleaning.png',
        'icon': Icons.cleaning_services_rounded,
      };
    } else if (key.contains('plumb') || key.contains('pipe') || key.contains('leak')) {
      return {
        'image': 'assets/images/icon_plumbing.png',
        'icon': Icons.plumbing_rounded,
      };
    } else if (key.contains('paint')) {
      return {
        'image': 'assets/images/icon_painting.png',
        'icon': Icons.format_paint_rounded,
      };
    } else if (key.contains('garden') || key.contains('lawn')) {
      return {
        'image': 'assets/images/icon_gardening.png',
        'icon': Icons.yard_rounded,
      };
    } else if (key.contains('appliance') || key.contains('fridge') || key.contains('oven')) {
      return {
        'image': 'assets/images/icon_appliances.png',
        'icon': Icons.kitchen_rounded,
      };
    } else if (key.contains('electr') || key.contains('wire') || key.contains('power')) {
      return {
        'image': 'assets/images/icon_electrical.png',
        'icon': Icons.electrical_services_rounded,
      };
    }

    return {
      'image': '',
      'icon': Icons.build_rounded,
    };
  }
}
