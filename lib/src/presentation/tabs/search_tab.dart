import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
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
import 'package:customer_app/core/di/service_locator.dart';
import 'package:customer_app/core/utils/map_marker_helper.dart';
import 'package:customer_app/src/domain/entities/profile/user_profile.dart';
import 'package:customer_app/src/domain/entities/providers/service_provider_entity.dart';
import 'package:customer_app/src/domain/entities/services/service_entity.dart';
import 'package:customer_app/src/domain/repositories/profile/profile_repository.dart';
import 'package:customer_app/src/presentation/cubits/properties/property_cubit.dart';
import 'package:customer_app/src/presentation/cubits/providers/provider_search_cubit.dart';
import 'package:customer_app/src/presentation/cubits/providers/provider_search_state.dart';
import 'package:customer_app/src/presentation/cubits/services/service_category_cubit.dart';
import 'package:customer_app/src/presentation/cubits/services/service_category_state.dart';
import 'package:customer_app/src/presentation/cubits/services/service_cubit.dart';
import 'package:customer_app/src/presentation/cubits/services/service_state.dart';
import 'package:customer_app/src/presentation/screens/auth/map_selector_screen.dart';
import 'package:customer_app/src/presentation/screens/services/widgets/book_service_modal.dart';
import 'package:customer_app/src/presentation/widgets/dynamic_island_toast.dart';

class SearchTab extends StatefulWidget {
  final VoidCallback? onBackTap;
  final String? initialService;
  final String? initialCategory;
  final int? initialCategoryId;

  const SearchTab({
    super.key,
    this.onBackTap,
    this.initialService,
    this.initialCategory,
    this.initialCategoryId,
  });

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final TextEditingController _serviceController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final FocusNode _serviceFocusNode = FocusNode();
  final FocusNode _locationFocusNode = FocusNode();
  final Geocoding _geocoding = Geocoding();

  GoogleMapController? _mapController;
  Timer? _debounceTimer;

  bool _myLocationEnabled = false;
  bool _isLocating = false;
  bool _initialLoadDone = false;
  bool _showServiceSuggestions = false;

  LatLng _centerLocation = ProviderSearchCubit.defaultLocation;
  String _locationName = ProviderSearchCubit.defaultLocationName;

  // Custom Map Markers
  Set<Marker> _mapMarkers = {};
  List<ServiceProviderEntity> _lastProviders = [];
  ServiceProviderEntity? _lastSelectedProvider;
  LatLng? _lastCenterLocation;
  UserProfile? _currentUserProfile;
  StreamSubscription<UserProfile>? _profileSub;
  bool _isBuildingMarkers = false;

  @override
  void initState() {
    super.initState();
    _locationController.text = _locationName;

    if (widget.initialService != null && widget.initialService!.trim().isNotEmpty) {
      _serviceController.text = widget.initialService!.trim();
    }

    _serviceFocusNode.addListener(() {
      if (_serviceFocusNode.hasFocus && mounted) {
        setState(() => _showServiceSuggestions = true);
      }
    });

    if (sl.isRegistered<ProfileRepository>()) {
      _profileSub = sl<ProfileRepository>().watchUserProfile().listen((profile) {
        if (mounted) {
          _currentUserProfile = profile;
          _refreshMarkers();
        }
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServiceCategoryCubit>().loadCategories();
      context.read<ServiceCubit>().loadServices();
      _initUserLocationAndSearch();
    });
  }

  @override
  void didUpdateWidget(SearchTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialService != oldWidget.initialService &&
        widget.initialService != null &&
        widget.initialService!.trim().isNotEmpty) {
      _serviceController.text = widget.initialService!.trim();
      _performSearch();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _profileSub?.cancel();
    _serviceFocusNode.dispose();
    _locationFocusNode.dispose();
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

    final queryService = _serviceController.text.trim();
    final effectiveService = queryService.isNotEmpty ? queryService : null;

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
            service: effectiveService,
            category: widget.initialCategory,
            categoryId: widget.initialCategoryId,
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
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 8),
          ),
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

        final queryService = _serviceController.text.trim();
        final effectiveService = queryService.isNotEmpty ? queryService : null;

        context.read<ProviderSearchCubit>().searchProviders(
              location: target,
              locationName: address,
              service: effectiveService,
              category: widget.initialCategory,
              categoryId: widget.initialCategoryId,
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
      final queryService = _serviceController.text.trim();
      final effectiveService = queryService.isNotEmpty ? queryService : null;
      context.read<ProviderSearchCubit>().searchProviders(
            location: _centerLocation,
            locationName: _locationName,
            service: effectiveService,
            category: widget.initialCategory,
            categoryId: widget.initialCategoryId,
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
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      context.read<ProviderSearchCubit>().updateServiceQuery(query);
    });
  }

  void _onSelectService(String serviceName) {
    HapticFeedback.lightImpact();
    _serviceController.text = serviceName;
    _serviceFocusNode.unfocus();
    setState(() => _showServiceSuggestions = false);
    context.read<ProviderSearchCubit>().updateServiceQuery(serviceName);
    _performSearch();
  }

  Future<void> _openMapSelector() async {
    HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus();
    setState(() => _showServiceSuggestions = false);

    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      CupertinoPageRoute(
        builder: (_) => const MapSelectorScreen(),
      ),
    );

    if (result != null && mounted) {
      final lat = (result['latitude'] as num).toDouble();
      final lng = (result['longitude'] as num).toDouble();
      final address = (result['address'] as String?)?.trim();
      final displayAddress = (address != null && address.isNotEmpty)
          ? address
          : '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';

      final target = LatLng(lat, lng);
      setState(() {
        _centerLocation = target;
        _locationName = displayAddress;
        _locationController.text = displayAddress;
      });

      _animateCameraTo(target);
      context.read<ProviderSearchCubit>().updateLocation(target, displayAddress);
      _performSearch();
    }
  }

  Future<void> _performSearch() async {
    FocusScope.of(context).unfocus();
    setState(() => _showServiceSuggestions = false);
    HapticFeedback.mediumImpact();

    final locationText = _locationController.text.trim();
    final serviceText = _serviceController.text.trim();

    // If manual address typed differs from current location, geocode it
    if (locationText.isNotEmpty &&
        locationText.toLowerCase() != _locationName.toLowerCase()) {
      setState(() => _isLocating = true);
      try {
        final locations = await _geocoding.locationFromAddress(locationText);
        if (locations.isNotEmpty) {
          final loc = locations.first;
          final target = LatLng(loc.latitude, loc.longitude);
          _centerLocation = target;
          _locationName = locationText;
          _animateCameraTo(target);
        }
      } catch (e) {
        debugPrint('⚠️ Geocoding failed on search: $e');
      } finally {
        if (mounted) setState(() => _isLocating = false);
      }
    }

    if (!mounted) return;
    context.read<ProviderSearchCubit>().searchProviders(
          location: _centerLocation,
          locationName: locationText.isNotEmpty ? locationText : _locationName,
          service: serviceText.isNotEmpty ? serviceText : null,
        );
  }

  Future<void> _onLocationSubmitted(String query) async {
    _locationController.text = query.trim();
    await _performSearch();
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

              // 2. Floating Top Elements: Search Header, Category Chips Bar & Count Badge
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTopSearchHeaderBlock(isLoading),
                    _buildCategoryChipsBar(state),
                    SizedBox(height: 6.h),
                    _buildCountBadge(providers.length, isLoading),
                  ],
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
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CUSTOM MAP MARKERS BUILDER (PROVIDER & CUSTOMER PINS)
  // ---------------------------------------------------------------------------
  Future<void> _updateMapMarkers({
    required List<ServiceProviderEntity> providers,
    required ServiceProviderEntity? selectedProvider,
    required LatLng center,
    required String locationName,
  }) async {
    _lastProviders = providers;
    _lastSelectedProvider = selectedProvider;
    _lastCenterLocation = center;

    if (_isBuildingMarkers) return;
    _isBuildingMarkers = true;

    try {
      final newMarkers = <Marker>{};

      // 1. Customer Custom Map Pin (Teardrop + Avatar + Blue dot)
      final customerIcon = await CustomMapMarkerHelper.getCustomerMarker(
        title: 'You',
        name: _currentUserProfile?.fullName.trim().isNotEmpty == true
            ? _currentUserProfile!.fullName
            : 'You',
        profileImageUrl: _currentUserProfile?.profileImageUrl,
        onImageLoaded: () {
          if (mounted) _refreshMarkers();
        },
      );

      newMarkers.add(
        Marker(
          markerId: const MarkerId('center_location_pin'),
          position: center,
          icon: customerIcon,
          anchor: CustomMapMarkerHelper.pinAnchor,
          infoWindow: InfoWindow(
            title: 'Your Location',
            snippet: locationName,
          ),
        ),
      );

      // 2. Provider Custom Map Pins (Teardrop + Photo + Green/Blue dot + Price pill)
      for (final provider in providers) {
        if (provider.latitude == 0.0 && provider.longitude == 0.0) continue;

        final isSelected = selectedProvider?.id == provider.id;
        final providerIcon = await CustomMapMarkerHelper.getProviderMarker(
          id: provider.id,
          name: provider.name,
          price: provider.price,
          hourlyRate: provider.hourlyRate,
          isAvailable: provider.isAvailable,
          isSelected: isSelected,
          profileImageUrl: provider.profileImage,
          onImageLoaded: () {
            if (mounted) _refreshMarkers();
          },
        );

        newMarkers.add(
          Marker(
            markerId: MarkerId('provider_${provider.id}'),
            position: LatLng(provider.latitude, provider.longitude),
            icon: providerIcon,
            anchor: CustomMapMarkerHelper.pinAnchor,
            infoWindow: InfoWindow.noText,
            onTap: () {
              HapticFeedback.selectionClick();
              context.read<ProviderSearchCubit>().selectProvider(provider);
              _animateCameraTo(
                LatLng(provider.latitude, provider.longitude),
                zoom: 15.5,
              );
              _showProviderDrawer(provider);
            },
          ),
        );
      }

      if (mounted) {
        setState(() {
          _mapMarkers = newMarkers;
        });
      }
    } catch (e) {
      debugPrint('⚠️ Error generating custom map markers: $e');
    } finally {
      _isBuildingMarkers = false;
    }
  }

  void _refreshMarkers() {
    if (_lastCenterLocation == null) return;
    _updateMapMarkers(
      providers: _lastProviders,
      selectedProvider: _lastSelectedProvider,
      center: _lastCenterLocation!,
      locationName: _locationName,
    );
  }

  // ---------------------------------------------------------------------------
  // GOOGLE MAP VIEW WITH CUSTOM PINS AND SEARCH AREA CIRCLE
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

    final locationName = (state is ProviderSearchLoaded)
        ? state.locationName
        : _locationName;

    // Trigger custom markers update when data changes
    if (_mapMarkers.isEmpty ||
        _lastProviders != providers ||
        _lastSelectedProvider != selectedProvider ||
        _lastCenterLocation != center) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _updateMapMarkers(
            providers: providers,
            selectedProvider: selectedProvider,
            center: center,
            locationName: locationName,
          );
        }
      });
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
      markers: _mapMarkers,
      circles: circles,
      onMapCreated: (controller) {
        _mapController = controller;
      },
      onTap: (_) {
        FocusScope.of(context).unfocus();
        if (_showServiceSuggestions) {
          setState(() => _showServiceSuggestions = false);
        }
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
        4.h,
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
                    color: Colors.white.withValues(alpha: 0.94),
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

          SizedBox(height: 10.h),

          // Redesigned Glassmorphic Search Card
          ClipRRect(
            borderRadius: BorderRadius.circular(22.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(22.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.95),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDark.withValues(alpha: 0.09),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Row 1: Service Type Input Row with Live Search
                    Row(
                      children: [
                        Container(
                          width: 30.r,
                          height: 30.r,
                          decoration: BoxDecoration(
                            color: AppColors.cardSelectedBg,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.borderUnselected,
                            ),
                          ),
                          child: Center(
                            child: Transform.rotate(
                              angle: -0.6,
                              child: Icon(
                                Icons.navigation_rounded,
                                color: AppColors.primary,
                                size: 16.r,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
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
                                  focusNode: _serviceFocusNode,
                                  textInputAction: TextInputAction.next,
                                  onChanged: (val) {
                                    _onServiceQueryChanged(val);
                                    if (!_showServiceSuggestions) {
                                      setState(() => _showServiceSuggestions = true);
                                    }
                                  },
                                  onTap: () {
                                    if (!_showServiceSuggestions) {
                                      setState(() => _showServiceSuggestions = true);
                                    }
                                  },
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textHeadline,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: context.loc.serviceTypePlaceholder,
                                    hintStyle: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.sp,
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
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4.w),
                              child: Icon(
                                Icons.close_rounded,
                                size: 18.r,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() =>
                                _showServiceSuggestions = !_showServiceSuggestions);
                          },
                          child: Container(
                            padding: EdgeInsets.all(4.r),
                            decoration: BoxDecoration(
                              color: _showServiceSuggestions
                                  ? AppColors.cardSelectedBg
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(
                              _showServiceSuggestions
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 20.r,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Service Live Search Suggestions Dropdown
                    BlocBuilder<ServiceCubit, ServiceState>(
                      builder: (context, sState) {
                        if (!_showServiceSuggestions) return const SizedBox.shrink();
                        final services = (sState is ServiceLoaded)
                            ? sState.services
                            : <ServiceEntity>[];
                        return _buildServiceSuggestions(services);
                      },
                    ),

                    // Divider
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.borderUnselected.withValues(alpha: 0.7),
                      ),
                    ),

                    // Row 2: Location Input Row (Search + Pin + GPS)
                    Row(
                      children: [
                        Container(
                          width: 30.r,
                          height: 30.r,
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.location_on_rounded,
                              color: Colors.redAccent,
                              size: 17.r,
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
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
                                  focusNode: _locationFocusNode,
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
                                      fontSize: 12.sp,
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
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4.w),
                              child: Icon(
                                Icons.close_rounded,
                                size: 18.r,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        SizedBox(width: 4.w),

                        // Pin on Map Button
                        GestureDetector(
                          onTap: _openMapSelector,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 5.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.cardSelectedBg,
                              borderRadius: BorderRadius.circular(9.r),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.pin_drop_rounded,
                                  size: 13.r,
                                  color: AppColors.primary,
                                ),
                                SizedBox(width: 3.w),
                                Text(
                                  'Pin',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 6.w),

                        // GPS Location Button
                        GestureDetector(
                          onTap: () => _detectGpsLocation(),
                          child: Container(
                            padding: EdgeInsets.all(5.5.r),
                            decoration: BoxDecoration(
                              color: AppColors.cardSelectedBg,
                              borderRadius: BorderRadius.circular(9.r),
                              border: Border.all(
                                color: AppColors.borderUnselected,
                              ),
                            ),
                            child: Icon(
                              Icons.my_location_rounded,
                              size: 15.r,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Divider
                    Padding(
                      padding: EdgeInsets.only(top: 8.h, bottom: 10.h),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.borderUnselected.withValues(alpha: 0.7),
                      ),
                    ),

                    // Row 3: Prominent Search Button
                    SizedBox(
                      width: double.infinity,
                      height: 42.h,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.primaryDark,
                              AppColors.primary,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(14.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _performSearch,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: isLoading
                              ? SizedBox(
                                  width: 18.r,
                                  height: 18.r,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    valueColor: AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_rounded,
                                      color: Colors.white,
                                      size: 18.r,
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      'Search Providers',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13.5.sp,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
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
  // SERVICE SUGGESTIONS LIST (LIVE SEARCH)
  // ---------------------------------------------------------------------------
  Widget _buildServiceSuggestions(List<ServiceEntity> services) {
    final query = _serviceController.text.trim().toLowerCase();

    List<({String name, String category})> items = [];
    if (services.isNotEmpty) {
      items = services
          .map((s) => (
                name: s.name.isNotEmpty ? s.name : s.title,
                category: s.category ?? 'Service'
              ))
          .toList();
    } else {
      const defaultServices = [
        (name: 'Plumbing', category: 'Plumbing'),
        (name: 'Drain Cleaning', category: 'Plumbing'),
        (name: 'Pipe Repair', category: 'Plumbing'),
        (name: 'Electrical Repair', category: 'Electrical'),
        (name: 'House Wiring', category: 'Electrical'),
        (name: 'House Cleaning', category: 'Cleaning'),
        (name: 'Deep Cleaning', category: 'Cleaning'),
        (name: 'AC Repair & Service', category: 'HVAC'),
        (name: 'Carpentry & Furniture', category: 'Carpentry'),
        (name: 'Painting & Waterproofing', category: 'Painting'),
        (name: 'Gardening & Lawn', category: 'Gardening'),
        (name: 'Appliance Repair', category: 'Appliances'),
      ];
      items = defaultServices;
    }

    final filtered = items.where((item) {
      if (query.isEmpty) return true;
      return item.name.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);
    }).toList();

    return Container(
      constraints: BoxConstraints(maxHeight: 180.h),
      margin: EdgeInsets.only(top: 8.h),
      decoration: BoxDecoration(
        color: AppColors.cardSelectedBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderUnselected),
      ),
      child: filtered.isEmpty
          ? Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              child: Row(
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 18.r,
                    color: AppColors.textMuted,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'No exact match. Tap Search to look up "$query"',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.symmetric(vertical: 4.h),
              itemCount: filtered.length > 8 ? 8 : filtered.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                thickness: 0.5,
                indent: 44.w,
                endIndent: 12.w,
                color: AppColors.borderUnselected.withValues(alpha: 0.7),
              ),
              itemBuilder: (context, index) {
                final item = filtered[index];
                final isSelected = _serviceController.text.trim().toLowerCase() ==
                    item.name.toLowerCase();

                return InkWell(
                  onTap: () => _onSelectService(item.name),
                  borderRadius: BorderRadius.circular(12.r),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                    child: Row(
                      children: [
                        Container(
                          width: 28.r,
                          height: 28.r,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.borderUnselected,
                            ),
                          ),
                          child: Icon(
                            _getIconForService(item.name),
                            size: 15.r,
                            color: isSelected ? Colors.white : AppColors.primary,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textHeadline,
                                ),
                              ),
                              if (item.category.isNotEmpty)
                                Text(
                                  item.category,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5.sp,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12.r,
                          color: AppColors.textMuted.withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                  ),
                );
              },
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
  // PROVIDER DRAWER (BOTTOM SHEET)
  // ---------------------------------------------------------------------------
  void _showProviderDrawer(ServiceProviderEntity provider) {
    HapticFeedback.mediumImpact();
    context.read<ProviderSearchCubit>().selectProvider(provider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (drawerContext) => _buildProviderDrawer(drawerContext, provider),
    ).then((_) {
      if (mounted) {
        context.read<ProviderSearchCubit>().selectProvider(null);
      }
    });
  }

  String _getReachableTime(ServiceProviderEntity provider) {
    if (provider.distanceKm != null && provider.distanceKm! > 0) {
      final mins = (provider.distanceKm! * 3.5 + 4).round();
      return '$mins mins';
    }
    final match = RegExp(r'([\d\.]+)').firstMatch(provider.distance);
    if (match != null) {
      final km = double.tryParse(match.group(1)!);
      if (km != null && km > 0) {
        final mins = (km * 3.5 + 4).round();
        return '$mins mins';
      }
    }
    return '10-15 mins';
  }

  Widget _buildProviderDrawer(
    BuildContext drawerContext,
    ServiceProviderEntity provider,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 28,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 28.h),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle bar
            Center(
              child: Container(
                width: 44.w,
                height: 4.5.h,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Header: Avatar, Name, Speciality, Status
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildProviderAvatar(provider),
                SizedBox(width: 14.w),
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
                                fontSize: 17.5.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textHeadline,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6.r,
                                  height: 6.r,
                                  decoration: BoxDecoration(
                                    color: provider.isAvailable
                                        ? const Color(0xFF2E7D32)
                                        : const Color(0xFFC62828),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  provider.isAvailable ? 'Available' : 'Busy',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5.sp,
                                    fontWeight: FontWeight.w700,
                                    color: provider.isAvailable
                                        ? const Color(0xFF2E7D32)
                                        : const Color(0xFFC62828),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(
                            _getIconForService(provider.serviceType),
                            size: 14.r,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '${provider.serviceType} Specialist',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 18.h),

            // 3-Column Key Metrics: How Far | Reachable Time | Ratings
            Container(
              padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 10.w),
              decoration: BoxDecoration(
                color: AppColors.cardSelectedBg,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      icon: Icons.near_me_rounded,
                      iconColor: AppColors.primary,
                      label: 'How Far',
                      value: provider.distance,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 38.h,
                    color: AppColors.primary.withValues(alpha: 0.15),
                  ),
                  Expanded(
                    child: _buildMetricTile(
                      icon: Icons.timer_outlined,
                      iconColor: const Color(0xFF0284C7),
                      label: 'Reachable',
                      value: _getReachableTime(provider),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 38.h,
                    color: AppColors.primary.withValues(alpha: 0.15),
                  ),
                  Expanded(
                    child: _buildMetricTile(
                      icon: Icons.star_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      label: 'Ratings',
                      value: '${provider.rating} ★',
                      subtitle: '(${provider.reviewsCount})',
                    ),
                  ),
                ],
              ),
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
                  height: 1.35,
                ),
              ),
            ],

            SizedBox(height: 18.h),

            // "Request Quote" CTA
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(drawerContext);
                  final locAddress = _locationName.trim().isNotEmpty
                      ? _locationName.trim()
                      : (_locationController.text.trim().isNotEmpty
                          ? _locationController.text.trim()
                          : 'Pinned Map Location');

                  BookServiceModal.show(context, {
                    'id': provider.id,
                    'title': '${provider.serviceType} Service',
                    'name': provider.serviceType,
                    'category': provider.serviceType,
                    'provider_id': provider.id,
                    'provider_name': provider.name,
                    'price': provider.price,
                    'location': locAddress,
                    'latitude': _centerLocation.latitude,
                    'longitude': _centerLocation.longitude,
                    'is_from_map': true,
                  });
                },
                icon: Icon(
                  Icons.request_quote_rounded,
                  color: Colors.white,
                  size: 20.r,
                ),
                label: Text(
                  'Request Quote',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(vertical: 15.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  elevation: 2,
                  shadowColor: AppColors.primary.withValues(alpha: 0.35),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    String? subtitle,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14.r, color: iconColor),
            SizedBox(width: 3.w),
            Flexible(
              child: Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textHeadline,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Text(
          subtitle != null ? '$label $subtitle' : label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.5.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildProviderAvatar(ServiceProviderEntity provider) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 52.r,
          height: 52.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.cardSelectedBg,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: ClipOval(
            child: provider.profileImage != null &&
                    provider.profileImage!.isNotEmpty
                ? (provider.profileImage!.startsWith('http')
                    ? Image.network(
                        provider.profileImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildAvatarFallback(provider),
                      )
                    : Image.asset(
                        provider.profileImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildAvatarFallback(provider),
                      ))
                : _buildAvatarFallback(provider),
          ),
        ),
        if (provider.isAvailable)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 14.r,
              height: 14.r,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAvatarFallback(ServiceProviderEntity provider) {
    final initials = provider.name.isNotEmpty
        ? provider.name
            .trim()
            .split(RegExp(r'\s+'))
            .map((s) => s.isNotEmpty ? s[0].toUpperCase() : '')
            .take(2)
            .join()
        : 'P';
    return Container(
      color: AppColors.primary.withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 16.sp,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

