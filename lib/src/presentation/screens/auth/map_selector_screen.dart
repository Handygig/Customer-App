import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:customer_app/core/constants/app_colors.dart';

class MapSelectorScreen extends StatefulWidget {
  const MapSelectorScreen({super.key});

  @override
  State<MapSelectorScreen> createState() => _MapSelectorScreenState();
}

class _MapSelectorScreenState extends State<MapSelectorScreen> {
  LatLng _selectedLatLng = const LatLng(6.9271, 79.8612);
  String _selectedAddress = 'Colombo, Sri Lanka';
  bool _isLoadingAddress = false;
  bool _myLocationEnabled = false;
  Placemark? _selectedPlacemark;
  GoogleMapController? _mapController;
  final Geocoding _geocoding = Geocoding();

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initLocationPermission();
    _reverseGeocode(_selectedLatLng);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initLocationPermission() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      final allowed =
          permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
      if (!mounted) return;
      setState(() => _myLocationEnabled = allowed);

      if (allowed) {
        final position = await Geolocator.getCurrentPosition();
        if (!mounted) return;
        final target = LatLng(position.latitude, position.longitude);
        _selectedLatLng = target;
        await _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(target, 15),
        );
        await _reverseGeocode(target);
      }
    } catch (_) {
      // Map selection remains fully usable without current-location access.
    }
  }

  Future<void> _reverseGeocode(LatLng position) async {
    if (!mounted) return;
    setState(() => _isLoadingAddress = true);

    try {
      final placemarks = await _geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        _selectedPlacemark = p;
        final parts =
            <String?>[
                  p.street,
                  p.subLocality,
                  p.locality,
                  p.administrativeArea,
                  p.postalCode,
                  p.country,
                ]
                .where((part) => part != null && part.trim().isNotEmpty)
                .map((part) => part!.trim())
                .toSet()
                .toList();

        setState(() {
          _selectedAddress = parts.isEmpty
              ? 'Coordinates: ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}'
              : parts.join(', ');
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _selectedAddress =
              'Coordinates: ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingAddress = false);
    }
  }

  Future<void> _searchLocation(String query) async {
    final text = query.trim();
    if (text.isEmpty) return;

    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();
    setState(() => _isLoadingAddress = true);

    try {
      final locations = await _geocoding.locationFromAddress(text);
      if (locations.isEmpty || !mounted) return;

      final target = LatLng(
        locations.first.latitude,
        locations.first.longitude,
      );
      _selectedLatLng = target;
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(target, 16),
      );
      await _reverseGeocode(target);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location could not be found.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingAddress = false);
    }
  }

  void _handleConfirm() {
    HapticFeedback.mediumImpact();
    final p = _selectedPlacemark;
    Navigator.of(context).pop({
      'address': _selectedAddress,
      'latitude': _selectedLatLng.latitude,
      'longitude': _selectedLatLng.longitude,
      'address_line_1': p?.street ?? _selectedAddress,
      'address_line_2': p?.subLocality ?? '',
      'city': p?.locality ?? p?.subAdministrativeArea ?? '',
      'province': p?.administrativeArea ?? '',
      'postal_code': p?.postalCode ?? '',
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        body: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _selectedLatLng,
                zoom: 15,
              ),
              onMapCreated: (controller) => _mapController = controller,
              onCameraMove: (position) => _selectedLatLng = position.target,
              onCameraIdle: () => _reverseGeocode(_selectedLatLng),
              myLocationEnabled: _myLocationEnabled,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: true,
            ),
            Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 28.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(6.r),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.location_on_rounded,
                        color: Colors.white,
                        size: 32.r,
                      ),
                    ),
                    Container(
                      width: 8.w,
                      height: 8.h,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 10.h,
                  ),
                  child: Row(
                    children: [
                      _buildBackButton(),
                      SizedBox(width: 10.w),
                      Expanded(child: _buildSearchBar()),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomCard()),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Container(
      width: 44.r,
      height: 44.r,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
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
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary,
            size: 20.r,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: _searchLocation,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textHeadline,
              ),
              decoration: InputDecoration(
                hintText: 'Search location...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30.r),
          topRight: Radius.circular(30.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confirm Location',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.textHeadline,
              ),
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: AppColors.primary,
                  size: 20.r,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _isLoadingAddress
                      ? Container(
                          height: 16.h,
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: 14.r,
                            height: 14.r,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                AppColors.primary,
                              ),
                            ),
                          ),
                        )
                      : Text(
                          _selectedAddress,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              'Coordinates: ${_selectedLatLng.latitude.toStringAsFixed(6)}, ${_selectedLatLng.longitude.toStringAsFixed(6)}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton(
                onPressed: _isLoadingAddress ? null : _handleConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonBackground,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26.r),
                  ),
                ),
                child: Text(
                  'Confirm Location',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
