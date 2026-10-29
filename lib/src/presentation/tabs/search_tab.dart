import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/utils/extensions.dart';
import 'package:customer_app/src/domain/entities/properties/property_entity.dart';
import 'package:customer_app/src/domain/entities/providers/service_provider_entity.dart';
import 'package:customer_app/src/presentation/cubits/properties/property_cubit.dart';
import 'package:customer_app/src/presentation/cubits/providers/provider_search_cubit.dart';
import 'package:customer_app/src/presentation/cubits/providers/provider_search_state.dart';
import 'package:customer_app/src/presentation/cubits/services/service_category_cubit.dart';
import 'package:customer_app/src/presentation/cubits/services/service_category_state.dart';
import 'package:customer_app/src/presentation/screens/services/widgets/book_service_modal.dart';
import 'package:customer_app/src/presentation/widgets/dynamic_island_toast.dart';

class SearchTab extends StatefulWidget {
  final VoidCallback? onBackTap;

  const SearchTab({super.key, this.onBackTap});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final TextEditingController _serviceController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final Geocoding _geocoding = Geocoding();

  GoogleMapController? _mapController;
  Timer? _debounceTimer;

  bool _myLocationEnabled = false;
  bool _isLocating = false;
  bool _initialLoadDone = false;

  LatLng _centerLocation = ProviderSearchCubit.defaultLocation;
  String _locationName = ProviderSearchCubit.defaultLocationName;

  @override
  void initState() {
    super.initState();
    _locationController.text = _locationName;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initUserLocationAndSearch();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _serviceController.dispose();
    _locationController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  /// Initial resolution of user location:
  /// 1. Check default customer property from PropertyCubit.
  /// 2. If none, check GPS position via Geolocator.
  /// 3. Fallback to Colombo, Sri Lanka default.
  Future<void> _initUserLocationAndSearch() async {
    if (!mounted || _initialLoadDone) return;
    _initialLoadDone = true;

    final propCubit = context.read<PropertyCubit>();
    final properties = propCubit.currentProperties;
    PropertyEntity? defaultProperty;
    if (properties.isNotEmpty) {
      defaultProperty = properties.where((p) => p.isDefault).firstOrNull ??
          properties.firstOrNull;
    }

    if (defaultProperty != null &&
        defaultProperty.latitude != null &&
        defaultProperty.longitude != null) {
      final target = LatLng(
        defaultProperty.latitude!,
        defaultProperty.longitude!,
      );
      final label = defaultProperty.label.isNotEmpty
          ? '${defaultProperty.label} (${defaultProperty.city})'
          : defaultProperty.city;
      _centerLocation = target;
      _locationName = label;
      _locationController.text = label;
      _animateCameraTo(target);

      context.read<ProviderSearchCubit>().searchProviders(
            location: target,
            locationName: label,
          );
      return;
    }

    // Try GPS
    await _detectGpsLocation(initial: true);
  }

  Future<void> _detectGpsLocation({bool initial = false}) async {
    if (!mounted) return;
    setState(() => _isLocating = true);

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      final allowed = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;

      if (!mounted) return;
      setState(() => _myLocationEnabled = allowed);

      if (allowed) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 8),
        );

        final target = LatLng(position.latitude, position.longitude);
        _centerLocation = target;

        // Reverse geocode to human-readable address
        String address = 'Current Location';
        try {
          final placemarks = await _geocoding.placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );
          if (placemarks.isNotEmpty) {
            final p = placemarks.first;
            final parts = <String?>[
              p.subLocality ?? p.locality,
              p.administrativeArea,
              p.country,
            ].where((e) => e != null && e.trim().isNotEmpty).toList();
            if (parts.isNotEmpty) {
              address = parts.join(', ');
            }
          }
        } catch (_) {}

        if (!mounted) return;
        _locationName = address;
        _locationController.text = address;
        _animateCameraTo(target);

        context.read<ProviderSearchCubit>().searchProviders(
              location: target,
              locationName: address,
              service: _serviceController.text,
            );
        return;
      }
    } catch (e) {
      debugPrint('⚠️ Error retrieving current location: $e');
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }

    // Fallback if initial and GPS not available
    if (initial) {
      context.read<ProviderSearchCubit>().searchProviders(
            location: _centerLocation,
            locationName: _locationName,
          );
    }
  }

  void _animateCameraTo(LatLng target, {double zoom = 14.5}) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: zoom),
      ),
    );
  }

  void _onServiceQueryChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      context.read<ProviderSearchCubit>().updateServiceQuery(query);
    });
  }

  Future<void> _onLocationSubmitted(String query) async {
    final text = query.trim();
    if (text.isEmpty) return;

    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();
    setState(() => _isLocating = true);

    try {
      final locations = await _geocoding.locationFromAddress(text);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        final target = LatLng(loc.latitude, loc.longitude);
        _centerLocation = target;
        _locationName = text;
        _animateCameraTo(target);

        if (!mounted) return;
        context.read<ProviderSearchCubit>().updateLocation(target, text);
        return;
      }
    } catch (e) {
      debugPrint('⚠️ Geocoding failed for "$text": $e');
      if (mounted) {
        DynamicIslandToast.showError(
          context,
          'Could not find "$text". Using previous location.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }

    // Search by text anyway
    if (mounted) {
      context.read<ProviderSearchCubit>().searchProviders(locationName: text);
    }
  }

  void _showSavedPropertiesModal() {
    HapticFeedback.lightImpact();
    final propCubit = context.read<PropertyCubit>();
    final properties = propCubit.currentProperties;

    if (properties.isEmpty) {
      DynamicIslandToast.showWarning(
        context,
        'No saved properties found. Add a property in profile settings.',
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: EdgeInsets.all(16.r),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Saved Property',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textHeadline,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              ...properties.map((prop) {
                return ListTile(
                  contentPadding: EdgeInsets.symmetric(vertical: 4.h),
                  leading: Container(
                    width: 40.r,
                    height: 40.r,
                    decoration: BoxDecoration(
                      color: AppColors.cardSelectedBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.home_work_rounded,
                      color: AppColors.primary,
                      size: 20.r,
                    ),
                  ),
                  title: Text(
                    prop.label.isNotEmpty ? prop.label : prop.city,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHeadline,
                    ),
                  ),
                  subtitle: Text(
                    prop.addressLine.isNotEmpty
                        ? '${prop.addressLine}, ${prop.city}'
                        : prop.city,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.sp,
                      color: AppColors.textMuted,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    if (prop.latitude != null && prop.longitude != null) {
                      final target = LatLng(prop.latitude!, prop.longitude!);
                      final label = prop.label.isNotEmpty
                          ? '${prop.label} (${prop.city})'
                          : prop.city;
                      _centerLocation = target;
                      _locationName = label;
                      _locationController.text = label;
                      _animateCameraTo(target);
                      this.context.read<ProviderSearchCubit>().updateLocation(
                            target,
                            label,
                          );
                    } else {
                      _onLocationSubmitted(prop.city);
                    }
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showProviderDetails(ServiceProviderEntity provider) {
    HapticFeedback.mediumImpact();
    context.read<ProviderSearchCubit>().selectProvider(provider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildProviderDetailSheet(provider),
    );
  }

  IconData _getIconForService(String serviceType) {
    final lower = serviceType.toLowerCase();
    if (lower.contains('plumb')) return Icons.plumbing_rounded;
    if (lower.contains('clean')) return Icons.cleaning_services_rounded;
    if (lower.contains('electr')) return Icons.electrical_services_rounded;
    if (lower.contains('paint')) return Icons.format_paint_rounded;
    if (lower.contains('garden') || lower.contains('land')) {
      return Icons.yard_rounded;
    }
    if (lower.contains('hvac') || lower.contains('ac')) {
      return Icons.hvac_rounded;
    }
    if (lower.contains('appliance')) return Icons.kitchen_rounded;
    return Icons.handyman_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<ProviderSearchCubit, ProviderSearchState>(
        listener: (context, state) {
          if (state is ProviderSearchLoaded) {
            _centerLocation = state.centerLocation;
            if (_locationController.text.isEmpty) {
              _locationController.text = state.locationName;
            }
          }
        },
        builder: (context, state) {
          final providers = (state is ProviderSearchLoaded)
              ? state.providers
              : (state is ProviderSearchLoading
                  ? state.previousProviders
                  : const <ServiceProviderEntity>[]);

          final selectedProvider = (state is ProviderSearchLoaded)
              ? state.selectedProvider
              : null;

          final isLoading = state is ProviderSearchLoading;

          return Stack(
            children: [
              // 1. Live Interactive Google Map with Provider Markers & Search Area Circle
              Positioned.fill(
                child: _buildGoogleMapView(state, providers, selectedProvider),
              ),

              // 2. Floating Top Elements: Search Header & Category Chips Bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTopSearchHeaderBlock(isLoading),
                    _buildCategoryChipsBar(state),
                  ],
                ),
              ),

              // 3. Floating Providers Count Badge
              Positioned(
                top: MediaQuery.of(context).padding.top + 168.h,
                left: 0,
                right: 0,
                child: Center(
                  child: _buildCountBadge(providers.length, isLoading),
                ),
              ),

              // 4. Floating Action Buttons (GPS Re-center & Saved Properties)
              Positioned(
                right: 16.w,
                bottom: 24.h,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFloatingRoundButton(
                      icon: Icons.bookmark_border_rounded,
                      tooltip: 'Saved Properties',
                      onTap: _showSavedPropertiesModal,
                    ),
                    SizedBox(height: 12.h),
                    _buildFloatingRoundButton(
                      icon: Icons.my_location_rounded,
                      tooltip: 'Current Location',
                      isLoading: _isLocating,
                      onTap: () => _detectGpsLocation(),
                    ),
                  ],
                ),
              ),

              // 5. Selected Provider Floating Bottom Card
              if (selectedProvider != null)
                Positioned(
                  left: 16.w,
                  right: 80.w,
                  bottom: 24.h,
                  child: _buildSelectedProviderCard(selectedProvider),
                ),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // GOOGLE MAP VIEW WITH REAL PINS AND SEARCH AREA CIRCLE
  // ---------------------------------------------------------------------------
  Widget _buildGoogleMapView(
    ProviderSearchState state,
    List<ServiceProviderEntity> providers,
    ServiceProviderEntity? selectedProvider,
  ) {
    final center = (state is ProviderSearchLoaded)
        ? state.centerLocation
        : _centerLocation;

    final radius = (state is ProviderSearchLoaded)
        ? state.searchRadius
        : 30.0;

    // Build Markers Set
    final markers = <Marker>{};

    // 1. Center Search Pin Marker
    markers.add(
      Marker(
        markerId: const MarkerId('center_location_pin'),
        position: center,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: 'Search Center',
          snippet: (state is ProviderSearchLoaded)
              ? state.locationName
              : _locationName,
        ),
      ),
    );

    // 2. Provider Markers
    for (final provider in providers) {
      if (provider.latitude == 0.0 && provider.longitude == 0.0) continue;

      final isSelected = selectedProvider?.id == provider.id;
      final markerHue = isSelected
          ? BitmapDescriptor.hueOrange
          : BitmapDescriptor.hueAzure;

      markers.add(
        Marker(
          markerId: MarkerId('provider_${provider.id}'),
          position: LatLng(provider.latitude, provider.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(markerHue),
          infoWindow: InfoWindow(
            title: provider.name,
            snippet: '${provider.serviceType} • ${provider.price}',
            onTap: () => _showProviderDetails(provider),
          ),
          onTap: () {
            HapticFeedback.selectionClick();
            context.read<ProviderSearchCubit>().selectProvider(provider);
            _animateCameraTo(
              LatLng(provider.latitude, provider.longitude),
              zoom: 15.5,
            );
          },
        ),
      );
    }

    // Search Area Circle (Visualized boundary of nearby search radius)
    final circles = <Circle>{
      Circle(
        circleId: const CircleId('search_area_boundary'),
        center: center,
        radius: radius * 1000, // km to meters
        fillColor: AppColors.primary.withValues(alpha: 0.08),
        strokeColor: AppColors.primary.withValues(alpha: 0.4),
        strokeWidth: 2,
      ),
    };

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: center,
        zoom: 13.8,
      ),
      myLocationEnabled: _myLocationEnabled,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
      markers: markers,
      circles: circles,
      onMapCreated: (controller) {
        _mapController = controller;
      },
      onTap: (_) {
        // Tapping map clears selected provider card
        if (selectedProvider != null) {
          context.read<ProviderSearchCubit>().selectProvider(null);
        }
      },
    );
  }

  // ---------------------------------------------------------------------------
  // TOP DUAL-INPUT SEARCH BAR (SERVICE & LOCATION)
  // ---------------------------------------------------------------------------
  Widget _buildTopSearchHeaderBlock(bool isLoading) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16.w,
        MediaQuery.of(context).padding.top + 8.h,
        16.w,
        8.h,
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
                  width: 40.r,
                  height: 40.r,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.textHeadline,
                      size: 22.r,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Text(
                  context.loc.serviceLocator,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textHeadline,
                    shadows: [
                      Shadow(
                        color: Colors.white.withValues(alpha: 0.9),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
              if (isLoading)
                SizedBox(
                  width: 18.r,
                  height: 18.r,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
            ],
          ),

          SizedBox(height: 12.h),

          // Dual-Input Glassmorphic Card (Service + Location)
          ClipRRect(
            borderRadius: BorderRadius.circular(22.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(22.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.9),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Service Type Input Row
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
                                context.loc.serviceType,
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
                                  onChanged: _onServiceQueryChanged,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textHeadline,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: context.loc.serviceTypePlaceholder,
                                    hintStyle: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.5.sp,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textMuted.withValues(alpha: 0.7),
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
                              _onServiceQueryChanged('');
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

                    // Divider
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

                    // Location Input Row
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
                                context.loc.locationLabel,
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
                                  textInputAction: TextInputAction.search,
                                  onSubmitted: _onLocationSubmitted,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textHeadline,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: context.loc.locationPlaceholder,
                                    hintStyle: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.5.sp,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textMuted.withValues(alpha: 0.7),
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
                            onTap: () => _detectGpsLocation(),
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
                                    context.loc.nearMe,
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CATEGORY CHIPS BAR
  // ---------------------------------------------------------------------------
  Widget _buildCategoryChipsBar(ProviderSearchState searchState) {
    final selectedCategory = (searchState is ProviderSearchLoaded)
        ? searchState.selectedCategory
        : 'All';

    return Container(
      height: 48.h,
      color: Colors.transparent,
      child: BlocBuilder<ServiceCategoryCubit, ServiceCategoryState>(
        builder: (context, catState) {
          final categories = (catState is ServiceCategoryLoaded)
              ? ['All', ...catState.categories.where((c) => c.isActive).map((c) => c.name)]
              : const ['All', 'Cleaning', 'Plumbing', 'Electrical', 'Painting', 'Gardening'];

          return ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, _) => SizedBox(width: 8.w),
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = selectedCategory.toLowerCase() == category.toLowerCase();

              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  int? categoryId;
                  if (category != 'All' && catState is ServiceCategoryLoaded) {
                    final matched = catState.categories
                        .where((c) => c.name.toLowerCase() == category.toLowerCase())
                        .firstOrNull;
                    categoryId = matched?.id;
                  }
                  context.read<ProviderSearchCubit>().updateCategory(
                        category,
                        categoryId: categoryId,
                      );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.r),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.white.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.white.withValues(alpha: 0.6),
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 6,
                                ),
                              ],
                      ),
                      child: Row(
                        children: [
                          if (category != 'All') ...[
                            Icon(
                              _getIconForService(category),
                              size: 14.r,
                              color: isSelected ? Colors.white : AppColors.primary,
                            ),
                            SizedBox(width: 6.w),
                          ],
                          Text(
                            category == 'All' ? context.loc.categoryAll : category,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.sp,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                              color: isSelected ? Colors.white : AppColors.textHeadline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FLOATING COUNT BADGE
  // ---------------------------------------------------------------------------
  Widget _buildCountBadge(int count, bool isLoading) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: AppColors.darkHeaderBg.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading) ...[
            SizedBox(
              width: 12.r,
              height: 12.r,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              'Searching providers nearby...',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ] else ...[
            Container(
              width: 8.r,
              height: 8.r,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              '$count service provider${count == 1 ? '' : 's'} nearby',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FLOATING ROUND BUTTONS (GPS & PROPERTIES)
  // ---------------------------------------------------------------------------
  Widget _buildFloatingRoundButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
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
            child: isLoading
                ? SizedBox(
                    width: 18.r,
                    height: 18.r,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  )
                : Icon(
                    icon,
                    color: AppColors.primary,
                    size: 22.r,
                  ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SELECTED PROVIDER FLOATING QUICK CARD
  // ---------------------------------------------------------------------------
  Widget _buildSelectedProviderCard(ServiceProviderEntity provider) {
    return GestureDetector(
      onTap: () => _showProviderDetails(provider),
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
              width: 44.r,
              height: 44.r,
              decoration: BoxDecoration(
                color: AppColors.cardSelectedBg,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                _getIconForService(provider.serviceType),
                color: AppColors.primary,
                size: 24.r,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    provider.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textHeadline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Text(
                        provider.price,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        ' • ${provider.distance}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.primary,
              size: 22.r,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FULL PROVIDER DETAILS MODAL BOTTOM SHEET
  // ---------------------------------------------------------------------------
  Widget _buildProviderDetailSheet(ServiceProviderEntity provider) {
    return Container(
      margin: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 32.h),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(32.r),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.8),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 24.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle Bar
                Center(
                  child: Container(
                    width: 48.w,
                    height: 5.h,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),

                // Profile Section
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 64.r,
                      height: 64.r,
                      decoration: BoxDecoration(
                        color: AppColors.cardSelectedBg,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          _getIconForService(provider.serviceType),
                          color: AppColors.primary,
                          size: 30.r,
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  provider.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textHeadline,
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 3.h,
                                ),
                                decoration: BoxDecoration(
                                  color: provider.isAvailable
                                      ? const Color(0xFFE8F5E9)
                                      : const Color(0xFFFFEBEE),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Text(
                                  provider.isAvailable ? 'Available' : 'Busy',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w800,
                                    color: provider.isAvailable
                                        ? const Color(0xFF2E7D32)
                                        : const Color(0xFFC62828),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '${provider.serviceType} Specialist • ${provider.distance}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Row(
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 18.r,
                                color: Colors.amber,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                '${provider.rating} ',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textHeadline,
                                ),
                              ),
                              Text(
                                '(${context.loc.reviews(provider.reviewsCount)})',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
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

                if (provider.bio != null && provider.bio!.isNotEmpty) ...[
                  SizedBox(height: 14.h),
                  Text(
                    provider.bio!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5.sp,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],

                SizedBox(height: 22.h),

                // Rate and Action Row
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estimated Rate',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                        Text(
                          provider.price,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 24.w),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            // Launch BookServiceModal with provider prefilled
                            BookServiceModal.show(context, {
                              'id': provider.id,
                              'name': provider.serviceType,
                              'provider_id': provider.id,
                              'provider_name': provider.name,
                              'price': provider.price,
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            context.loc.bookProvider,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
