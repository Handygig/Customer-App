import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/src/presentation/screens/chat/chat_screen.dart';
import 'package:customer_app/src/presentation/widgets/dynamic_island_toast.dart';

class JobDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> job;

  const JobDetailsScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final String jobId = job['id'] as String? ?? 'JOB-0000';
    final String service = job['service'] as String? ?? 'Service Details';
    final String property = job['property'] as String? ?? 'Primary Location';
    final String providerName =
        job['provider'] as String? ?? 'Assigned Professional';
    final String rating = job['rating'] as String? ?? '4.9 ★';
    final String price = job['price'] as String? ?? '\$0.00';
    final String date = job['date'] as String? ?? 'Scheduled Date';
    final String status = job['status'] as String? ?? 'Pending';
    final String type = job['type'] as String? ?? 'ongoing';
    final Color statusColor =
        job['statusColor'] as Color? ?? AppColors.primaryDark;
    final Color statusBg = job['statusBg'] as Color? ?? const Color(0xFFF3F6E6);
    final IconData icon =
        job['icon'] as IconData? ?? Icons.cleaning_services_rounded;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFBFBFB),
        body: Column(
          children: [
            // Top Dark Header Section
            _buildTopHeader(context, jobId, status, statusColor, statusBg),

            // Scrollable Content
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primaryDark,
                backgroundColor: Colors.white,
                strokeWidth: 2.8,
                onRefresh: () async {
                  HapticFeedback.mediumImpact();
                  await Future.delayed(const Duration(milliseconds: 1000));
                  if (context.mounted) {
                    DynamicIslandToast.showSuccess(
                      context,
                      'Refreshed task details',
                    );
                  }
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 20.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Job Overview Card
                      _buildJobOverviewCard(service, property, date, icon),
                      SizedBox(height: 20.h),

                      // Job Progress Timeline
                      _buildProgressTimeline(type),
                      SizedBox(height: 20.h),

                      // Provider Details Section
                      _buildProviderDetailsSection(
                        context,
                        providerName,
                        rating,
                        type,
                        service,
                        jobId,
                      ),
                      SizedBox(height: 20.h),

                      // Price & Payment Details Section
                      _buildPriceBreakdownSection(price, type),
                      SizedBox(height: 20.h),

                      // Location & Property Details
                      _buildLocationCard(property),
                      SizedBox(height: 30.h),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Action Footer
            _buildBottomActionBar(context, type, providerName, service, jobId),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader(
    BuildContext context,
    String jobId,
    String status,
    Color statusColor,
    Color statusBg,
  ) {
    return Container(
      width: double.infinity,
      color: AppColors.primaryDark,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12.h,
        left: 16.w,
        right: 20.w,
        bottom: 24.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                },
                icon: Container(
                  width: 38.r,
                  height: 38.r,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18.r,
                    ),
                  ),
                ),
              ),
              Text(
                'Task Details',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: Colors.white,
                  size: 22.r,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      jobId,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Booking Reference',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5.sp,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 7.h,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    status,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
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

  Widget _buildJobOverviewCard(
    String service,
    String property,
    String date,
    IconData icon,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: const Color(0xFFE8ECD8), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52.r,
                height: 52.r,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F6E6),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Center(
                  child: Icon(icon, color: AppColors.primaryDark, size: 26.r),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.replaceAll('\n', ' '),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      property,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          const Divider(height: 1, color: Color(0xFFEFF2E4)),
          SizedBox(height: 16.h),
          Row(
            children: [
              Icon(
                Icons.event_available_rounded,
                size: 18.r,
                color: AppColors.primary,
              ),
              SizedBox(width: 10.w),
              Text(
                'Schedule: ',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                date,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTimeline(String type) {
    final int currentStep = switch (type) {
      'waiting' => 0,
      'to_approve' => 1,
      'ongoing' => 2,
      'completed' => 3,
      _ => 2,
    };

    final steps = ['Requested', 'Approved', 'In Progress', 'Completed'];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: const Color(0xFFE8ECD8), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Job Progress Status',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15.5.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
          SizedBox(height: 20.h),
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
                          width: 28.r,
                          height: 28.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isPassed
                                ? (isCurrent
                                      ? AppColors.primary
                                      : AppColors.primaryDark)
                                : const Color(0xFFE2E6D5),
                            border: isCurrent
                                ? Border.all(
                                    color: AppColors.accentLime,
                                    width: 3,
                                  )
                                : null,
                          ),
                          child: Center(
                            child: isPassed
                                ? Icon(
                                    Icons.check_rounded,
                                    size: 16.r,
                                    color: Colors.white,
                                  )
                                : Text(
                                    '${index + 1}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          steps[index],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5.sp,
                            fontWeight: isPassed
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isPassed
                                ? AppColors.primaryDark
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    if (index < steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 3.h,
                          margin: EdgeInsets.only(bottom: 22.h),
                          color: index < currentStep
                              ? AppColors.primaryDark
                              : const Color(0xFFE2E6D5),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderDetailsSection(
    BuildContext context,
    String providerName,
    String rating,
    String type,
    String service,
    String jobId,
  ) {
    final bool isAssigned = providerName != 'Awaiting Assignment';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: const Color(0xFFE8ECD8), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Service Provider',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15.5.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
              if (isAssigned)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F6E6),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        size: 13.r,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'Verified Pro',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              CircleAvatar(
                radius: 26.r,
                backgroundColor: isAssigned
                    ? AppColors.primaryDark
                    : const Color(0xFFE2E6D5),
                child: Text(
                  isAssigned
                      ? providerName
                            .split(' ')
                            .map((e) => e[0])
                            .take(2)
                            .join('')
                      : '?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      providerName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 16.r,
                          color: const Color(0xFFF59E0B),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          rating,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          isAssigned ? '(124 Completed Jobs)' : 'Matching Pro',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.sp,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isAssigned) ...[
            SizedBox(height: 18.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.call_rounded, size: 16.r),
                    label: Text(
                      'Call Pro',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            providerName: providerName,
                            serviceTitle: service,
                            jobId: jobId,
                          ),
                        ),
                      );
                    },
                    icon: Icon(Icons.chat_bubble_outline_rounded, size: 16.r),
                    label: Text(
                      'Message',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryDark,
                      side: const BorderSide(
                        color: Color(0xFFC7D0A8),
                        width: 1.2,
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceBreakdownSection(String priceStr, String type) {
    double basePrice = 120.0;
    try {
      final clean = priceStr.replaceAll(RegExp(r'[^0-9.]'), '');
      basePrice = double.tryParse(clean) ?? 120.0;
    } catch (_) {}

    final double tax = basePrice * 0.08;
    final double total = basePrice + tax;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: const Color(0xFFE8ECD8), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment & Billing Details',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15.5.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
          SizedBox(height: 16.h),
          _buildPriceRow(
            'Base Service Rate',
            '\$${basePrice.toStringAsFixed(2)}',
          ),
          SizedBox(height: 10.h),
          _buildPriceRow('Service & Safety Fee', '\$5.00'),
          SizedBox(height: 10.h),
          _buildPriceRow('Estimated Tax (8%)', '\$${tax.toStringAsFixed(2)}'),
          SizedBox(height: 14.h),
          const Divider(height: 1, color: Color(0xFFEFF2E4)),
          SizedBox(height: 14.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
              Text(
                '\$${(total + 5.00).toStringAsFixed(2)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8F0),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: const Color(0xFFE2E6D5)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.credit_card_rounded,
                  size: 20.r,
                  color: AppColors.primary,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    type == 'completed'
                        ? 'Paid with Visa ending in •••• 4242'
                        : 'Payment method authorization active',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
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

  Widget _buildPriceRow(String label, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5.sp,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          amount,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5.sp,
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard(String property) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: const Color(0xFFE8ECD8), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Service Address',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15.5.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Container(
                width: 40.r,
                height: 40.r,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F6E6),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Center(
                  child: Icon(
                    Icons.location_on_rounded,
                    color: AppColors.primaryDark,
                    size: 20.r,
                  ),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Access Code / Gate Note: Ring Doorbell',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.sp,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(
    BuildContext context,
    String type,
    String providerName,
    String service,
    String jobId,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20.w,
        14.h,
        20.w,
        MediaQuery.of(context).padding.bottom + 14.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: switch (type) {
        'to_approve' => Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  side: const BorderSide(color: Color(0xFFDC2626)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: Text(
                  'Decline',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFDC2626),
                  ),
                ),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  DynamicIslandToast.showSuccess(
                    context,
                    'Estimate Approved Successfully!',
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: Text(
                  'Approve',
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
        'completed' => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rate Provider Banner Trigger Card
            GestureDetector(
              onTap: () => _showRateProviderModal(context, job),
              child: Container(
                margin: EdgeInsets.only(bottom: 12.h),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: const Color(0xFFFFE082),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF3C4),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.star_rounded,
                        color: const Color(0xFFD97706),
                        size: 20.r,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'How was ${job['provider'] as String? ?? 'this Pro'}?',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF92400E),
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Tap to rate & review your service',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: const Color(0xFFD97706),
                      size: 14.r,
                    ),
                  ],
                ),
              ),
            ),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showReceiptPreviewModal(context, job),
                    icon: Icon(Icons.receipt_long_rounded, size: 16.r),
                    label: Text(
                      'Receipt',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryDark,
                      side: const BorderSide(
                        color: Color(0xFFC7D0A8),
                        width: 1.2,
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRateProviderModal(context, job),
                    icon: Icon(
                      Icons.star_rounded,
                      size: 16.r,
                      color: const Color(0xFFD97706),
                    ),
                    label: Text(
                      'Rate Pro',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFFBEB),
                      foregroundColor: const Color(0xFF92400E),
                      side: const BorderSide(
                        color: Color(0xFFFFE082),
                        width: 1.2,
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      DynamicIslandToast.showSuccess(
                        context,
                        'Rebooking Service...',
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    child: Text(
                      'Book Again',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5.sp,
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
        _ => Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  DynamicIslandToast.showSuccess(
                    context,
                    'Calling $providerName...',
                  );
                },
                icon: Icon(Icons.call_rounded, size: 18.r),
                label: Text(
                  'Call Provider',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        providerName: providerName,
                        serviceTitle: service,
                        jobId: jobId,
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.chat_bubble_outline_rounded, size: 18.r),
                label: Text(
                  'Message Pro',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryDark,
                  side: const BorderSide(color: Color(0xFFC7D0A8), width: 1.2),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      },
    );
  }

  void _showReceiptPreviewModal(
    BuildContext context,
    Map<String, dynamic> job,
  ) {
    HapticFeedback.mediumImpact();
    final String jobId = job['id'] as String? ?? 'JOB-9788';
    final String service =
        job['service'] as String? ??
        'Electrical Maintenance & Safety Inspection';
    final String provider = job['provider'] as String? ?? 'Apex Electricians';
    final String price = job['price'] as String? ?? '\$242.60';
    final String date = job['date'] as String? ?? 'Today, 2:30 PM';
    final String property =
        job['property'] as String? ?? 'Silicon Valley Office';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FBF6),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
          ),
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 44.w,
                  height: 4.5.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // Title Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: AppColors.cardSelectedBg,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(
                          Icons.receipt_long_rounded,
                          color: AppColors.primary,
                          size: 22.r,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        'Payment Receipt',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textHeadline,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: AppColors.textMuted,
                      size: 22.r,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              SizedBox(height: 14.h),

              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // Paper Card Container
                      Container(
                        padding: EdgeInsets.all(20.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: const Color(0xFFE2E7D3),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Paid Stamp Badge
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 14.w,
                                vertical: 6.h,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: const Color(0xFFA5D6A7),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: const Color(0xFF2E7D32),
                                    size: 16.r,
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    'PAID IN FULL',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5.sp,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF2E7D32),
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 14.h),

                            // Total Amount Big Display
                            Text(
                              price,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 32.sp,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textHeadline,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'Total Amount Paid',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.sp,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 18.h),

                            const Divider(
                              color: Color(0xFFEFF2E4),
                              thickness: 1,
                            ),
                            SizedBox(height: 14.h),

                            // Details Key-Value pairs
                            _buildReceiptRow('Booking Ref', jobId),
                            SizedBox(height: 10.h),
                            _buildReceiptRow('Service Title', service),
                            SizedBox(height: 10.h),
                            _buildReceiptRow('Provider', provider),
                            SizedBox(height: 10.h),
                            _buildReceiptRow('Date & Time', date),
                            SizedBox(height: 10.h),
                            _buildReceiptRow('Address', property),

                            SizedBox(height: 14.h),
                            const Divider(
                              color: Color(0xFFEFF2E4),
                              thickness: 1,
                            ),
                            SizedBox(height: 14.h),

                            // Breakdown
                            _buildReceiptRow('Base Service Rate', '\$220.00'),
                            SizedBox(height: 8.h),
                            _buildReceiptRow('Service & Safety Fee', '\$5.00'),
                            SizedBox(height: 8.h),
                            _buildReceiptRow('Estimated Tax (8%)', '\$17.60'),
                            SizedBox(height: 12.h),

                            Container(
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.credit_card_rounded,
                                    size: 18.r,
                                    color: AppColors.primary,
                                  ),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Text(
                                      'Paid via Visa ending in •••• 4242',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textHeadline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),

              // Download Receipt Button
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    DynamicIslandToast.showSuccess(
                      context,
                      'Receipt PDF downloaded successfully!',
                    );
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.download_rounded, color: Colors.white),
                  label: Text(
                    'Download Receipt (PDF)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26.r),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5.sp,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textHeadline,
            ),
          ),
        ),
      ],
    );
  }

  void _showRateProviderModal(BuildContext context, Map<String, dynamic> job) {
    HapticFeedback.mediumImpact();
    final String provider = job['provider'] as String? ?? 'Apex Electricians';
    final String service =
        job['service'] as String? ?? 'Electrical Maintenance';

    int currentRating = 5;
    final Set<String> selectedTags = {'On-Time ⏰', 'Clean Work 🧹'};
    final TextEditingController commentCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(28.r),
                  ),
                ),
                padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Drag Handle
                      Center(
                        child: Container(
                          width: 44.w,
                          height: 4.5.h,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Rate & Review Pro',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textHeadline,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              color: AppColors.textMuted,
                              size: 22.r,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),

                      // Provider Card Avatar Box
                      Container(
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F9F2),
                          borderRadius: BorderRadius.circular(18.r),
                          border: Border.all(color: const Color(0xFFE5EAD9)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24.r,
                              backgroundColor: AppColors.primaryDark,
                              child: Text(
                                provider
                                    .split(' ')
                                    .map((e) => e.isEmpty ? '' : e[0])
                                    .take(2)
                                    .join(),
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                            SizedBox(width: 14.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    provider,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textHeadline,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    service,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.sp,
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 20.h),

                      Text(
                        'How was your service experience?',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textHeadline,
                        ),
                      ),
                      SizedBox(height: 10.h),

                      // Interactive 5-Star Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final starIndex = index + 1;
                          final isSelected = starIndex <= currentRating;
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setModalState(() {
                                currentRating = starIndex;
                              });
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4.w),
                              child: Icon(
                                isSelected
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 36.r,
                                color: isSelected
                                    ? const Color(0xFFFFB800)
                                    : Colors.grey.shade300,
                              ),
                            ),
                          );
                        }),
                      ),

                      SizedBox(height: 8.h),
                      Text(
                        _getRatingLabel(currentRating),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),

                      SizedBox(height: 20.h),

                      // Quick Compliment Chips
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'What stood out the most?',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textHeadline,
                          ),
                        ),
                      ),
                      SizedBox(height: 10.h),

                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children:
                            [
                              'On-Time ⏰',
                              'Professional 👔',
                              'Clean Work 🧹',
                              'Fast Service ⚡',
                              'Fair Price 🏷️',
                              'Friendly 😊',
                            ].map((tag) {
                              final isSelected = selectedTags.contains(tag);
                              return FilterChip(
                                selected: isSelected,
                                label: Text(tag),
                                labelStyle: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.sp,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.primaryDark
                                      : AppColors.textHeadline,
                                ),
                                selectedColor: AppColors.cardSelectedBg,
                                backgroundColor: Colors.grey.shade100,
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.grey.shade300,
                                ),
                                onSelected: (val) {
                                  HapticFeedback.selectionClick();
                                  setModalState(() {
                                    if (val) {
                                      selectedTags.add(tag);
                                    } else {
                                      selectedTags.remove(tag);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                      ),

                      SizedBox(height: 18.h),

                      // Optional Comment Field
                      TextField(
                        controller: commentCtrl,
                        maxLines: 3,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13.sp),
                        decoration: InputDecoration(
                          hintText: 'Write a public review for $provider...',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            color: AppColors.textMuted,
                            fontSize: 13.sp,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFFBFBFB),
                          contentPadding: EdgeInsets.all(14.w),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E7D3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 24.h),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 52.h,
                        child: ElevatedButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            DynamicIslandToast.showSuccess(
                              context,
                              'Thank you! Review submitted for $provider ⭐',
                            );
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryDark,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26.r),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            'Submit Review',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 5:
        return '⭐⭐⭐⭐⭐ Excellent service!';
      case 4:
        return '⭐⭐⭐⭐ Very Good experience!';
      case 3:
        return '⭐⭐⭐ Average service.';
      case 2:
        return '⭐⭐ Poor service.';
      case 1:
        return '⭐ Terrible experience.';
      default:
        return 'Select a rating';
    }
  }
}
