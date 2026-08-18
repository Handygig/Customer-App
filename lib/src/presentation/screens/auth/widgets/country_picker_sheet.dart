import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/src/data/models/auth/country_code_model.dart';

class CountryPickerSheet extends StatefulWidget {
  final List<CountryCode> countries;
  final CountryCode selectedCountry;
  final bool loading;

  const CountryPickerSheet({
    super.key,
    required this.countries,
    required this.selectedCountry,
    required this.loading,
  });

  static Future<CountryCode?> show({
    required BuildContext context,
    required List<CountryCode> countries,
    required CountryCode selectedCountry,
    required bool loading,
  }) {
    return showModalBottomSheet<CountryCode>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      builder: (_) => CountryPickerSheet(
        countries: countries,
        selectedCountry: selectedCountry,
        loading: loading,
      ),
    );
  }

  @override
  State<CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<CountryPickerSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.toLowerCase().trim();
    final filtered = widget.countries.where((country) {
      return country.name.toLowerCase().contains(query) ||
          country.code.toLowerCase().contains(query);
    }).toList();

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E4DE),
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Select Country / Region',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.textHeadline,
              ),
            ),
            SizedBox(height: 12.h),
            TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search country or dial code...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 14.sp,
                  color: Colors.grey.shade400,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 20.r,
                  color: Colors.grey.shade500,
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 10.h,
                  horizontal: 14.w,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Expanded(
              child: widget.loading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? Center(
                          child: Text(
                            'No country found',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: Colors.grey.shade200,
                          ),
                          itemBuilder: (_, index) {
                            final country = filtered[index];
                            final selected =
                                country.code == widget.selectedCountry.code &&
                                    country.name == widget.selectedCountry.name;

                            return ListTile(
                              onTap: () => Navigator.of(context).pop(country),
                              leading: Text(
                                country.flag,
                                style: TextStyle(fontSize: 24.sp),
                              ),
                              title: Text(
                                country.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15.sp,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    country.code,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  if (selected) ...[
                                    SizedBox(width: 8.w),
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: AppColors.primary,
                                      size: 20.r,
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
