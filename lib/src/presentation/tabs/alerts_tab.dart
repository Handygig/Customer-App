import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer_app/core/constants/app_colors.dart';

class AlertsTab extends StatelessWidget {
  const AlertsTab({super.key});

  final List<Map<String, dynamic>> _notifications = const [
    {
      'title': 'Pro En Route to Your Address',
      'body': 'Marcus Vance is 8 minutes away from Sunset Luxury Villa.',
      'time': '10 mins ago',
      'isUnread': true,
      'icon': Icons.near_me_rounded,
      'color': AppColors.primary,
    },
    {
      'title': 'Job Scheduled Successfully',
      'body': 'Deep Home Sanitization scheduled for Today at 02:00 PM.',
      'time': '2 hours ago',
      'isUnread': true,
      'icon': Icons.event_available_rounded,
      'color': AppColors.primaryLight,
    },
    {
      'title': 'Special 30% Promo Activated',
      'body': 'Use code CLEAN30 for your next deep cleaning booking.',
      'time': '1 day ago',
      'isUnread': false,
      'icon': Icons.local_offer_rounded,
      'color': AppColors.accentOliveLight,
    },
    {
      'title': 'Invoice Paid for Pipe Repair',
      'body': 'Payment of \$145.00 confirmed via Apple Pay.',
      'time': '3 days ago',
      'isUnread': false,
      'icon': Icons.receipt_long_rounded,
      'color': AppColors.primaryDark,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.darkHeaderBg,
        elevation: 0,
        title: Text(
          'Alerts & Notifications',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
      body: ListView.separated(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 110.h),
        itemCount: _notifications.length,
        separatorBuilder: (context, index) => SizedBox(height: 12.h),
        itemBuilder: (context, index) {
          final notif = _notifications[index];
          final bool isUnread = notif['isUnread'] as bool;

          return Container(
            decoration: BoxDecoration(
              color: isUnread ? Colors.white : AppColors.cardSelectedBg,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isUnread
                    ? AppColors.primary
                    : AppColors.borderUnselected,
                width: isUnread ? 1.4 : 1,
              ),
              boxShadow: [
                if (isUnread)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
              ],
            ),
            padding: EdgeInsets.all(16.r),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: (notif['color'] as Color).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    notif['icon'] as IconData,
                    color: notif['color'] as Color,
                    size: 20.r,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notif['title'] as String,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.sp,
                                fontWeight: isUnread
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: AppColors.textHeadline,
                              ),
                            ),
                          ),
                          Text(
                            notif['time'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.sp,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        notif['body'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5.sp,
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
        },
      ),
    );
  }
}
