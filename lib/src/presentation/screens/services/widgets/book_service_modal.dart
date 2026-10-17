import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/src/domain/entities/properties/property_entity.dart';
import 'package:customer_app/src/presentation/cubits/job_requests/job_request_cubit.dart';
import 'package:customer_app/src/presentation/cubits/job_requests/job_request_state.dart';
import 'package:customer_app/src/presentation/cubits/properties/property_cubit.dart';
import 'package:customer_app/src/presentation/cubits/properties/property_state.dart';
import 'package:customer_app/src/presentation/cubits/services/service_category_cubit.dart';
import 'package:customer_app/src/presentation/screens/profile/add_new_property_screen.dart';
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
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final srv = widget.service;
    _descriptionController = TextEditingController(
      text: 'Need ${srv['title']} - ${srv['description'] ?? ''}'.trim(),
    );
    // Initial date is tomorrow at 09:00 AM
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day + 1, 9, 0);

    // Initial property selection
    final propCubit = context.read<PropertyCubit>();
    final properties = propCubit.currentProperties;
    if (properties.isNotEmpty) {
      _selectedProperty = properties.firstWhere(
        (p) => p.isDefault,
        orElse: () => properties.first,
      );
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    HapticFeedback.lightImpact();
    final now = DateTime.now();
    final initial = _selectedDate.isBefore(now.add(const Duration(days: 1)))
        ? now.add(const Duration(days: 1))
        : _selectedDate;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryDark,
              onPrimary: Colors.white,
              onSurface: AppColors.textHeadline,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
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

  Future<void> _submitBooking() async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      DynamicIslandToast.showError(context, 'Please enter a service description.');
      return;
    }

    if (_selectedProperty == null) {
      DynamicIslandToast.showError(
          context, 'Please select or add a property for this service.');
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
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result != null) {
      Navigator.pop(context);
      DynamicIslandToast.showSuccess(
        context,
        'Booking request submitted for ${widget.service['title']}!',
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

            // Header Title & Price
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Book ${srv['title']}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textHeadline,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Category: ${srv['category']}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5.sp,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  srv['price'] as String? ?? '',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 18.h),
            const Divider(height: 1, color: Color(0xFFEFF2E4)),
            SizedBox(height: 16.h),

            // 1. Property Selector Section
            Text(
              'Select Property',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textHeadline,
              ),
            ),
            SizedBox(height: 8.h),
            BlocBuilder<PropertyCubit, PropertyState>(
              builder: (context, state) {
                final properties = context.read<PropertyCubit>().currentProperties;

                if (properties.isEmpty) {
                  return Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'No properties found',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5.sp,
                            color: AppColors.textMuted,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddNewPropertyScreen(),
                              ),
                            );
                          },
                          child: Text(
                            '+ Add Property',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (_selectedProperty == null && properties.isNotEmpty) {
                  _selectedProperty = properties.firstWhere(
                    (p) => p.isDefault,
                    orElse: () => properties.first,
                  );
                }

                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: _selectedProperty?.id,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      items: properties.map((prop) {
                        return DropdownMenuItem<int>(
                          value: prop.id,
                          child: Row(
                            children: [
                              Icon(
                                Icons.home_work_outlined,
                                size: 18.r,
                                color: AppColors.primaryDark,
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  '${prop.label} (${prop.fullAddress})',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textHeadline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (propId) {
                        if (propId != null) {
                          setState(() {
                            _selectedProperty = properties.firstWhere(
                              (p) => p.id == propId,
                            );
                          });
                        }
                      },
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 16.h),

            // 2. Preferred Date Picker
            Text(
              'Preferred Date',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textHeadline,
              ),
            ),
            SizedBox(height: 8.h),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 18.r,
                      color: AppColors.primaryDark,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textHeadline,
                        ),
                      ),
                    ),
                    Text(
                      'Change',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // 3. Description Field
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
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: const Color(0xFFE5E7EB)),
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
                    : Text(
                        'Confirm & Send Request',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5.sp,
                          fontWeight: FontWeight.w800,
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
