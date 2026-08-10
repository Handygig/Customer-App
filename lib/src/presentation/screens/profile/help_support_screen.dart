import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/src/presentation/widgets/dynamic_island_toast.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final List<Map<String, String>> _faqs = [
    {
      'question': 'How do I book a home maintenance service?',
      'answer': 'Navigate to the Home or Search tab, select your required service (e.g. Plumbing, AC Repair), pick a convenient date & time slot, choose your property, and confirm payment.'
    },
    {
      'question': 'Can I cancel or reschedule my booking?',
      'answer': 'Yes! Go to the Jobs tab, select your upcoming booking, and tap "Reschedule" or "Cancel Booking". Cancellations made 2 hours prior are 100% free of charge.'
    },
    {
      'question': 'What if the technician doesn\'t arrive on time?',
      'answer': 'All service providers are GPS tracked in real-time. If there is a delay over 15 minutes, our 24/7 support team automatically reaches out and provides a \$10 service credit voucher.'
    },
    {
      'question': 'Are service technicians verified and insured?',
      'answer': 'Absolutely. Every professional undergoes background screening, identity verification, and carries comprehensive service liability coverage.'
    },
  ];

  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.darkHeaderBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Help & 24/7 Support',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emergency Repair Banner
            Container(
              padding: EdgeInsets.all(18.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
                gradient: const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: const BoxDecoration(
                      color: AppColors.accentLime,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.headset_mic_rounded,
                        color: AppColors.primaryDark, size: 24.r),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '24/7 Emergency Dispatch',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Water leak or power outage? Call our priority line.',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFFC7CBC0),
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      DynamicIslandToast.showSuccess(context, 'Calling Emergency Dispatch Line: +1 (800) 123-4567');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentLime,
                      foregroundColor: AppColors.primaryDark,
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      'Call Now',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),

            // Live Chat Tile
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(color: AppColors.borderUnselected),
              ),
              child: ListTile(
                onTap: () {
                  HapticFeedback.lightImpact();
                  DynamicIslandToast.showSuccess(context, 'Connecting to live chat agent...');
                },
                leading: Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: AppColors.cardSelectedBg,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(Icons.chat_bubble_outline_rounded,
                      color: AppColors.primary, size: 22.r),
                ),
                title: Text(
                  'Start Live Support Chat',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textHeadline,
                  ),
                ),
                subtitle: Text(
                  'Average response time: 2 mins',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.sp,
                    color: AppColors.textMuted,
                  ),
                ),
                trailing: Icon(Icons.arrow_forward_ios_rounded,
                    size: 14.r, color: AppColors.textMuted),
              ),
            ),
            SizedBox(height: 28.h),

            // FAQ Title
            Text(
              'Frequently Asked Questions',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16.5.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.textHeadline,
              ),
            ),
            SizedBox(height: 14.h),

            // FAQ Accordions
            ...List.generate(_faqs.length, (index) {
              final isExpanded = _expandedIndex == index;
              final item = _faqs[index];

              return Container(
                margin: EdgeInsets.only(bottom: 12.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: isExpanded ? AppColors.primary : AppColors.borderUnselected,
                  ),
                ),
                child: ExpansionTile(
                  key: Key('faq_$index'),
                  tilePadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                  childrenPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                  iconColor: AppColors.primary,
                  collapsedIconColor: AppColors.textMuted,
                  onExpansionChanged: (expanded) {
                    setState(() => _expandedIndex = expanded ? index : null);
                  },
                  title: Text(
                    item['question']!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHeadline,
                    ),
                  ),
                  children: [
                    Text(
                      item['answer']!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.sp,
                        height: 1.45,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
