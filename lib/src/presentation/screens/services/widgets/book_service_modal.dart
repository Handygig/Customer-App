import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/src/domain/entities/payments/card_entity.dart';
import 'package:customer_app/src/domain/entities/properties/property_entity.dart';
import 'package:customer_app/src/presentation/cubits/job_requests/job_request_cubit.dart';
import 'package:customer_app/src/presentation/cubits/job_requests/job_request_state.dart';
import 'package:customer_app/src/presentation/cubits/payments/card_cubit.dart';
import 'package:customer_app/src/presentation/cubits/payments/card_state.dart';
import 'package:customer_app/src/presentation/cubits/properties/property_cubit.dart';
import 'package:customer_app/src/presentation/cubits/properties/property_state.dart';
import 'package:customer_app/src/presentation/cubits/services/service_category_cubit.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_app/config/router/app_routes.dart';
import 'package:customer_app/src/presentation/widgets/dynamic_island_toast.dart';

class BookServiceModal extends StatefulWidget {
  final Map<String, dynamic> service;

  const BookServiceModal({super.key, required this.service});

  static Future<void> show(BuildContext context, Map<String, dynamic> service) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookServiceModal(service: service),
    );
  }

  @override
  State<BookServiceModal> createState() => _BookServiceModalState();
}

class _BookServiceModalState extends State<BookServiceModal> {
  late final TextEditingController _descriptionController;
  late DateTime _selectedDate;
  PropertyEntity? _selectedProperty;
  CardEntity? _selectedCard;
  String _selectedPaymentMethod = 'card'; // 'card' or 'cash'
  bool _isSubmitting = false;
  bool _isLocatingCurrentPosition = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    // Initial date is tomorrow at 09:00 AM
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day + 1, 9, 0);

    // Initial property selection
    final propCubit = context.read<PropertyCubit>();
    final properties = propCubit.currentProperties;
    if (properties.isNotEmpty) {
      _selectedProperty = properties.where((p) => p.isDefault).firstOrNull ?? properties.first;
    }

    // Initial card selection
    final cardCubit = context.read<CardCubit>();
    final cards = cardCubit.cards;
    if (cards.isNotEmpty) {
      _selectedCard = cards.where((c) => c.isDefault && !c.isFrozen).firstOrNull ??
          cards.where((c) => !c.isFrozen).firstOrNull ??
          cards.first;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    HapticFeedback.lightImpact();
    DateTime tempDate = _selectedDate;
    int pickerKeyVersion = 0;

    final now = DateTime.now();
    // Next 12 months for quick month selection
    final monthsList = List.generate(12, (index) {
      return DateTime(now.year, now.month + index, 1);
    });

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void jumpToMonth(DateTime m) {
              HapticFeedback.lightImpact();
              final daysInMonth = DateTime(m.year, m.month + 1, 0).day;
              final clampedDay = tempDate.day.clamp(1, daysInMonth);
              var newDate = DateTime(
                m.year,
                m.month,
                clampedDay,
                tempDate.hour,
                tempDate.minute,
              );
              if (newDate.isBefore(now.add(const Duration(minutes: 30)))) {
                newDate = now.add(const Duration(hours: 1));
              }
              setSheetState(() {
                tempDate = newDate;
                pickerKeyVersion++;
              });
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Title & Close
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Date & Time',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 17.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textHeadline,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'Choose your preferred service schedule',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5.sp,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(sheetContext),
                          child: Container(
                            padding: EdgeInsets.all(6.r),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF3F4F6),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 18.r,
                              color: AppColors.textHeadline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 14.h),

                    // Active preview chip banner
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.event_available_rounded,
                            size: 18.r,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              DateFormat('EEEE, MMM d, yyyy • hh:mm a').format(tempDate),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Month Selector Header & Quick Month Navigation
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Month',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textHeadline,
                          ),
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                final prevMonth = DateTime(tempDate.year, tempDate.month - 1, 1);
                                if (!prevMonth.isBefore(DateTime(now.year, now.month, 1))) {
                                  jumpToMonth(prevMonth);
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.all(5.r),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Icon(
                                  Icons.chevron_left_rounded,
                                  size: 18.r,
                                  color: (tempDate.year == now.year && tempDate.month == now.month)
                                      ? AppColors.textMuted.withValues(alpha: 0.35)
                                      : AppColors.textHeadline,
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            GestureDetector(
                              onTap: () {
                                final nextMonth = DateTime(tempDate.year, tempDate.month + 1, 1);
                                if (nextMonth.isBefore(DateTime(now.year, now.month + 12, 1))) {
                                  jumpToMonth(nextMonth);
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.all(5.r),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18.r,
                                  color: AppColors.textHeadline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),

                    // Horizontal Month Selector Pills
                    SizedBox(
                      height: 36.h,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: monthsList.length,
                        separatorBuilder: (context, index) => SizedBox(width: 8.w),
                        itemBuilder: (context, index) {
                          final m = monthsList[index];
                          final isSelected = m.year == tempDate.year && m.month == tempDate.month;

                          return GestureDetector(
                            onTap: () => jumpToMonth(m),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: EdgeInsets.symmetric(horizontal: 14.w),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.buttonBackground
                                    : const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(10.r),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.buttonBackground
                                      : const Color(0xFFE5E7EB),
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  DateFormat('MMM yyyy').format(m),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.sp,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    color: isSelected
                                        ? AppColors.buttonText
                                        : AppColors.textHeadline,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 14.h),

                    // Cupertino Wheel Picker for Day & Time
                    Text(
                      'Scroll to Pick Day & Time',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textHeadline,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    SizedBox(
                      height: 185.h,
                      child: CupertinoDatePicker(
                        key: ValueKey(pickerKeyVersion),
                        mode: CupertinoDatePickerMode.dateAndTime,
                        initialDateTime: tempDate.isBefore(now.add(const Duration(minutes: 30)))
                            ? now.add(const Duration(hours: 1))
                            : tempDate,
                        minimumDate: now.add(const Duration(minutes: 15)),
                        maximumDate: now.add(const Duration(days: 365)),
                        use24hFormat: false,
                        onDateTimeChanged: (val) {
                          setSheetState(() => tempDate = val);
                        },
                      ),
                    ),

                    SizedBox(height: 18.h),

                    // Confirm Action Button
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
                          HapticFeedback.mediumImpact();
                          setState(() => _selectedDate = tempDate);
                          Navigator.pop(sheetContext);
                        },
                        child: Text(
                          'Confirm Schedule',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  int _resolveServiceCategoryId() {
    final catCubit = context.read<ServiceCategoryCubit>();
    final categories = catCubit.categories;
    final catName = widget.service['category']?.toString().toLowerCase().trim() ?? '';

    final matched = categories.where(
      (c) => c.name.toLowerCase().trim() == catName,
    );
    if (matched.isNotEmpty) {
      return matched.first.id;
    }
    if (categories.isNotEmpty) {
      return categories.first.id;
    }
    return 1;
  }

  Future<void> _navigateToAddCard() async {
    HapticFeedback.lightImpact();
    await context.push(AppRoutes.addCard);
    if (!mounted) return;
    final cardCubit = context.read<CardCubit>();
    await cardCubit.loadCards(silent: true);
    if (!mounted) return;
    final cards = cardCubit.cards;
    if (cards.isNotEmpty) {
      setState(() {
        _selectedCard = cards.where((c) => c.isDefault && !c.isFrozen).firstOrNull ??
            cards.where((c) => !c.isFrozen).firstOrNull ??
            cards.last;
      });
    }
  }

  Future<void> _navigateToAddProperty() async {
    HapticFeedback.lightImpact();
    await context.push(AppRoutes.addNewProperty);
    if (!mounted) return;
    final propCubit = context.read<PropertyCubit>();
    await propCubit.loadProperties(forceRefresh: true);
    if (!mounted) return;
    final props = propCubit.currentProperties;
    if (props.isNotEmpty) {
      setState(() {
        _selectedProperty = props.where((p) => p.isDefault).firstOrNull ?? props.last;
      });
    }
  }

  Future<void> _useCurrentLocationAsProperty() async {
    if (_isLocatingCurrentPosition) return;
    HapticFeedback.lightImpact();
    setState(() => _isLocatingCurrentPosition = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        DynamicIslandToast.showError(
          context,
          'Please enable Location Services on your device.',
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        DynamicIslandToast.showError(
          context,
          'Location permission is permanently denied. Please enable in Settings.',
        );
        return;
      }

      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        DynamicIslandToast.showError(context, 'Location permission denied.');
        return;
      }

      // 1. Try to get cached / last known position first (instant on devices and simulators)
      Position? position;
      try {
        position = await Geolocator.getLastKnownPosition();
      } catch (_) {}

      // 2. If no cached position, fetch with medium accuracy and short timeout
      if (position == null) {
        try {
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 5),
            ),
          );
        } catch (_) {
          // If timed out, try lowest accuracy as quick fallback
          try {
            position = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.lowest,
                timeLimit: Duration(seconds: 4),
              ),
            );
          } catch (_) {
            // Re-check last known position
            try {
              position = await Geolocator.getLastKnownPosition();
            } catch (_) {}
          }
        }
      }

      // 3. Fallback coordinates (Colombo central) if device/simulator has no GPS fix yet
      final double lat = position?.latitude ?? 6.9044;
      final double lng = position?.longitude ?? 79.8543;

      String city = 'Colombo';
      String fullAddress = 'Current Location';

      try {
        final placemarks = await Geocoding()
            .placemarkFromCoordinates(lat, lng)
            .timeout(const Duration(seconds: 5));

        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final locality = p.locality ?? p.subAdministrativeArea ?? p.administrativeArea;
          if (locality != null && locality.trim().isNotEmpty) {
            city = locality.trim();
          }

          final addressParts = <String?>[
            p.street,
            p.subLocality,
            p.locality,
            p.postalCode,
          ]
              .where((part) => part != null && part.trim().isNotEmpty)
              .map((part) => part!.trim())
              .toSet()
              .toList();

          if (addressParts.isNotEmpty) {
            fullAddress = addressParts.join(', ');
          }
        }
      } catch (e) {
        debugPrint('Reverse geocode error or timeout: $e');
        if (position == null) {
          fullAddress = 'Colombo, Western Province';
        }
      }

      if (!mounted) return;

      final propCubit = context.read<PropertyCubit>();
      final existingLocationProp = propCubit.currentProperties.where(
        (p) =>
            p.label == 'Current Location' ||
            (p.latitude != null &&
                (p.latitude! - lat).abs() < 0.0005 &&
                (p.longitude! - lng).abs() < 0.0005),
      ).firstOrNull;

      if (existingLocationProp != null) {
        setState(() {
          _selectedProperty = existingLocationProp;
        });
        DynamicIslandToast.showSuccess(
          context,
          'Selected: ${existingLocationProp.fullAddress}',
        );
      } else {
        final success = await propCubit.addProperty(
          label: 'Current Location',
          addressLine: fullAddress,
          city: city,
          latitude: lat,
          longitude: lng,
          isDefault: true,
        );

        if (!mounted) return;

        if (success) {
          final updated = propCubit.currentProperties;
          setState(() {
            _selectedProperty = updated.where((p) => p.label == 'Current Location').firstOrNull ??
                updated.lastOrNull;
          });
          DynamicIslandToast.showSuccess(
            context,
            'Current location added and selected!',
          );
        } else {
          DynamicIslandToast.showError(
            context,
            'Failed to save current location as property.',
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      DynamicIslandToast.showError(context, 'Could not get current location: $e');
    } finally {
      if (mounted) {
        setState(() => _isLocatingCurrentPosition = false);
      }
    }
  }

  Future<void> _submitBooking() async {
    // 1. Validate Description
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      DynamicIslandToast.showError(context, 'Please enter a service description.');
      return;
    }

    // 2. Validate Payment Method & Cards
    if (_selectedPaymentMethod == 'card') {
      final cards = context.read<CardCubit>().cards;
      if (cards.isEmpty) {
        DynamicIslandToast.showError(
          context,
          'No payment cards found. Please add a card or select Cash payment.',
        );
        return;
      }
      if (_selectedCard == null) {
        DynamicIslandToast.showError(
          context,
          'Please select a payment card to proceed.',
        );
        return;
      }
      if (_selectedCard!.isFrozen) {
        DynamicIslandToast.showError(
          context,
          'The selected card is frozen. Please choose another card or Cash.',
        );
        return;
      }
    }

    // 3. Validate Properties
    final properties = context.read<PropertyCubit>().currentProperties;
    if (properties.isEmpty) {
      DynamicIslandToast.showError(
        context,
        'No property found. Please add a property before placing your booking.',
      );
      return;
    }

    if (_selectedProperty == null) {
      DynamicIslandToast.showError(
        context,
        'Please select a property for this service.',
      );
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    final catId = _resolveServiceCategoryId();
    final jobCubit = context.read<JobRequestCubit>();

    final result = await jobCubit.createJobRequest(
      propertyId: _selectedProperty!.id,
      serviceCategoryId: catId,
      description: description,
      preferredDate: _selectedDate,
      paymentMethod: _selectedPaymentMethod,
      cardId: _selectedPaymentMethod == 'card' ? _selectedCard?.id : null,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result != null) {
      Navigator.pop(context);
      DynamicIslandToast.showSuccess(
        context,
        'Booking request placed for ${widget.service['title']}! Providers will send quotations shortly.',
      );
    } else {
      final state = jobCubit.state;
      final errorMsg = state is JobRequestError
          ? state.message
          : 'Could not create booking request. Please try again.';
      DynamicIslandToast.showError(context, errorMsg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final srv = widget.service;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      padding: EdgeInsets.fromLTRB(
        20.w,
        12.h,
        20.w,
        bottomInset > 0 ? bottomInset + 16.h : 36.h,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 44.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.borderUnselected,
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
            SizedBox(height: 18.h),

            // Header Title (Without Pricing)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Book ${srv['title'] ?? srv['name'] ?? srv['provider_name'] ?? 'Service'}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textHeadline,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Category: ${srv['category'] ?? srv['serviceType'] ?? 'General'}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5.sp,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            const Divider(height: 1, color: Color(0xFFEFF2E4)),
            SizedBox(height: 16.h),

            // 1. Payment Method Selection (Card or Cash)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payment Method',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textHeadline,
                  ),
                ),
                if (_selectedPaymentMethod == 'card')
                  GestureDetector(
                    onTap: _navigateToAddCard,
                    child: Text(
                      '+ Add Card',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                else
                  Text(
                    'Select preference',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5.sp,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 10.h),

            // Payment Method Selector Chips / Cards
            Row(
              children: [
                // Card Option
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _selectedPaymentMethod = 'card';
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
                      decoration: BoxDecoration(
                        color: _selectedPaymentMethod == 'card'
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: _selectedPaymentMethod == 'card'
                              ? AppColors.primary
                              : const Color(0xFFE5E7EB),
                          width: _selectedPaymentMethod == 'card' ? 1.8 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.credit_card_rounded,
                            size: 20.r,
                            color: _selectedPaymentMethod == 'card'
                                ? AppColors.primary
                                : AppColors.textMuted,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              'Card Payment',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5.sp,
                                fontWeight: _selectedPaymentMethod == 'card'
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: _selectedPaymentMethod == 'card'
                                    ? AppColors.primary
                                    : AppColors.textHeadline,
                              ),
                            ),
                          ),
                          if (_selectedPaymentMethod == 'card')
                            Icon(
                              Icons.check_circle_rounded,
                              size: 16.r,
                              color: AppColors.primary,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),

                // Cash Option
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _selectedPaymentMethod = 'cash';
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
                      decoration: BoxDecoration(
                        color: _selectedPaymentMethod == 'cash'
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: _selectedPaymentMethod == 'cash'
                              ? AppColors.primary
                              : const Color(0xFFE5E7EB),
                          width: _selectedPaymentMethod == 'cash' ? 1.8 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.payments_rounded,
                            size: 20.r,
                            color: _selectedPaymentMethod == 'cash'
                                ? AppColors.primary
                                : AppColors.textMuted,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              'Cash on Hand',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5.sp,
                                fontWeight: _selectedPaymentMethod == 'cash'
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: _selectedPaymentMethod == 'cash'
                                    ? AppColors.primary
                                    : AppColors.textHeadline,
                              ),
                            ),
                          ),
                          if (_selectedPaymentMethod == 'cash')
                            Icon(
                              Icons.check_circle_rounded,
                              size: 16.r,
                              color: AppColors.primary,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Card Selector when card method is chosen
            if (_selectedPaymentMethod == 'card') ...[
              SizedBox(height: 12.h),
              BlocBuilder<CardCubit, CardState>(
                builder: (context, state) {
                  final cards = context.read<CardCubit>().cards;

                  // Validation: Handle No Cards Added
                  if (cards.isEmpty) {
                    return Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(color: const Color(0xFFFED7AA)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEDD5),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Icon(
                              Icons.credit_card_off_rounded,
                              color: const Color(0xFFC2410C),
                              size: 20.r,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'No cards added yet',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5.sp,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF9A3412),
                                  ),
                                ),
                                Text(
                                  'Add a card or switch to Cash above',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.sp,
                                    color: const Color(0xFFC2410C),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: _navigateToAddCard,
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 6.h,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                                side: const BorderSide(color: Color(0xFFFDBA74)),
                              ),
                            ),
                            child: Text(
                              '+ Add Card',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFC2410C),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (_selectedCard == null || !cards.any((c) => c.id == _selectedCard!.id)) {
                    _selectedCard = cards.where((c) => c.isDefault && !c.isFrozen).firstOrNull ??
                        cards.where((c) => !c.isFrozen).firstOrNull ??
                        (cards.isNotEmpty ? cards.first : null);
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        isExpanded: true,
                        value: _selectedCard?.id,
                        borderRadius: BorderRadius.circular(16.r),
                        dropdownColor: Colors.white,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textHeadline,
                        ),
                        selectedItemBuilder: (context) {
                          return cards.map((card) {
                            final isFrozen = card.isFrozen;
                            return Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(7.r),
                                  decoration: BoxDecoration(
                                    color: (isFrozen ? Colors.redAccent : AppColors.primary).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Icon(
                                    Icons.credit_card_rounded,
                                    size: 18.r,
                                    color: isFrozen ? Colors.redAccent : AppColors.primary,
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: Text(
                                    '${card.cardType.toUpperCase()} •••• ${card.lastFourDigits}${card.isDefault ? " (Primary)" : ""}${isFrozen ? " [FROZEN]" : ""}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.5.sp,
                                      fontWeight: FontWeight.w600,
                                      color: isFrozen ? Colors.redAccent : AppColors.textHeadline,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList();
                        },
                        items: cards.map((card) {
                          final isFrozen = card.isFrozen;
                          return DropdownMenuItem<int>(
                            value: card.id,
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(7.r),
                                  decoration: BoxDecoration(
                                    color: (isFrozen ? Colors.redAccent : AppColors.primary).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Icon(
                                    Icons.credit_card_rounded,
                                    size: 18.r,
                                    color: isFrozen ? Colors.redAccent : AppColors.primary,
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: Text(
                                    '${card.cardType.toUpperCase()} •••• ${card.lastFourDigits}${card.isDefault ? " (Primary)" : ""}${isFrozen ? " [FROZEN]" : ""}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.5.sp,
                                      fontWeight: FontWeight.w600,
                                      color: isFrozen ? Colors.redAccent : AppColors.textHeadline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (cardId) {
                          if (cardId != null) {
                            setState(() {
                              _selectedCard = cards.where((c) => c.id == cardId).firstOrNull;
                            });
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ],

            SizedBox(height: 18.h),

            // 2. Property Selector Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Property',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textHeadline,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: _isLocatingCurrentPosition
                          ? null
                          : _useCurrentLocationAsProperty,
                      borderRadius: BorderRadius.circular(8.r),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 3.h,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isLocatingCurrentPosition)
                              SizedBox(
                                width: 12.r,
                                height: 12.r,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 1.8,
                                  color: AppColors.primary,
                                ),
                              )
                            else
                              Icon(
                                Icons.my_location_rounded,
                                size: 14.r,
                                color: AppColors.primary,
                              ),
                            SizedBox(width: 4.w),
                            Text(
                              'Current Location',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Text(
                      ' • ',
                      style: TextStyle(
                        color: AppColors.textMuted.withValues(alpha: 0.5),
                        fontSize: 11.sp,
                      ),
                    ),
                    GestureDetector(
                      onTap: _navigateToAddProperty,
                      child: Text(
                        '+ Add Property',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8.h),
            BlocBuilder<PropertyCubit, PropertyState>(
              builder: (context, state) {
                final properties = context.read<PropertyCubit>().currentProperties;

                // Validation: Handle No Properties Added
                if (properties.isEmpty) {
                  return Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: const Color(0xFFFED7AA)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8.r),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEDD5),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Icon(
                                Icons.home_work_outlined,
                                color: const Color(0xFFC2410C),
                                size: 20.r,
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'No properties added yet',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.5.sp,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF9A3412),
                                    ),
                                  ),
                                  Text(
                                    'Add a property or use your current location',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.sp,
                                      color: const Color(0xFFC2410C),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: _navigateToAddProperty,
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w,
                                  vertical: 6.h,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                  side: const BorderSide(color: Color(0xFFFDBA74)),
                                ),
                              ),
                              child: Text(
                                '+ Add',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5.sp,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFC2410C),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLocatingCurrentPosition
                                ? null
                                : _useCurrentLocationAsProperty,
                            icon: _isLocatingCurrentPosition
                                ? SizedBox(
                                    width: 14.r,
                                    height: 14.r,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    Icons.my_location_rounded,
                                    size: 16.r,
                                    color: Colors.white,
                                  ),
                            label: Text(
                              _isLocatingCurrentPosition
                                  ? 'Getting Current Location...'
                                  : 'Use Current Location',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              disabledBackgroundColor:
                                  AppColors.primary.withValues(alpha: 0.6),
                              padding: EdgeInsets.symmetric(vertical: 10.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (_selectedProperty == null || !properties.any((p) => p.id == _selectedProperty!.id)) {
                  _selectedProperty = properties.where((p) => p.isDefault).firstOrNull ??
                      (properties.isNotEmpty ? properties.first : null);
                }

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: _selectedProperty?.id,
                      borderRadius: BorderRadius.circular(16.r),
                      dropdownColor: Colors.white,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textHeadline,
                      ),
                      selectedItemBuilder: (context) {
                        return properties.map((prop) {
                          return Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(7.r),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Icon(
                                  Icons.location_on_outlined,
                                  size: 18.r,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      prop.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textHeadline,
                                      ),
                                    ),
                                    Text(
                                      prop.fullAddress,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.sp,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList();
                      },
                      items: properties.map((prop) {
                        return DropdownMenuItem<int>(
                          value: prop.id,
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8.r),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Icon(
                                  Icons.location_on_outlined,
                                  size: 18.r,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            prop.label,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13.sp,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textHeadline,
                                            ),
                                          ),
                                        ),
                                        if (prop.isDefault) ...[
                                          SizedBox(width: 6.w),
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(6.r),
                                            ),
                                            child: Text(
                                              'Default',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 10.sp,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      prop.fullAddress,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5.sp,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (propId) {
                        if (propId != null) {
                          setState(() {
                            _selectedProperty = properties.where((p) => p.id == propId).firstOrNull;
                          });
                        }
                      },
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 18.h),

            // 3. Preferred Date & Time Picker
            Text(
              'Preferred Schedule',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textHeadline,
              ),
            ),
            SizedBox(height: 8.h),
            GestureDetector(
              onTap: _pickDateTime,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44.w,
                      height: 44.h,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('MMM').format(_selectedDate).toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            DateFormat('dd').format(_selectedDate),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDark,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textHeadline,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 13.r,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                'Time: ${DateFormat('hh:mm a').format(_selectedDate)}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5.sp,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 13.r,
                            color: AppColors.textHeadline,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Change',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textHeadline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 18.h),

            // 4. Description Field
            Text(
              'Service Description & Notes',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textHeadline,
              ),
            ),
            SizedBox(height: 8.h),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
              ),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              child: TextField(
                controller: _descriptionController,
                maxLines: 3,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.sp,
                  color: AppColors.textHeadline,
                ),
                decoration: InputDecoration(
                  hintText: 'Describe details, preferred timing, or special notes...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5.sp,
                    color: AppColors.textMuted,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            SizedBox(height: 24.h),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonBackground,
                  foregroundColor: AppColors.buttonText,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  elevation: 0,
                ),
                onPressed: _isSubmitting ? null : _submitBooking,
                child: _isSubmitting
                    ? SizedBox(
                        width: 20.r,
                        height: 20.r,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryDark,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.send_rounded,
                            size: 16.r,
                            color: AppColors.buttonText,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Place Booking & Request Quotes',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
