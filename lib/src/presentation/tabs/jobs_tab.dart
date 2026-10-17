import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/src/domain/entities/job_requests/job_request_entity.dart';
import 'package:customer_app/src/presentation/cubits/job_requests/job_request_cubit.dart';
import 'package:customer_app/src/presentation/cubits/job_requests/job_request_state.dart';
import 'package:customer_app/src/presentation/screens/jobs/job_details_screen.dart';
import 'package:customer_app/src/presentation/screens/services/all_services_screen.dart';
import 'package:customer_app/src/presentation/widgets/dynamic_island_toast.dart';

class JobsTab extends StatefulWidget {
  const JobsTab({super.key});

  @override
  State<JobsTab> createState() => _JobsTabState();
}

class _JobsTabState extends State<JobsTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _allJobs = [
    {
      'id': 'JOB-9852',
      'service': 'Plumbing Leak Inspection',
      'property': 'Sunset Luxury Villa, SF',
      'provider': 'Awaiting Assignment',
      'rating': 'New',
      'price': '\$110.00',
      'date': 'Today, Aug 02 • 06:00 PM',
      'status': 'Waiting',
      'type': 'waiting',
      'statusColor': const Color(0xFFD97706),
      'statusBg': const Color(0xFFFEF3C7),
      'icon': Icons.hourglass_top_rounded,
    },
    {
      'id': 'JOB-9850',
      'service': 'Roof Repair & Tiles Service',
      'property': 'Downtown Studio Apt, SF',
      'provider': 'Apex Contractors',
      'rating': '4.9 ★',
      'price': '\$350.00',
      'date': 'Today, Aug 02 • 05:00 PM',
      'status': 'To Approve',
      'type': 'to_approve',
      'statusColor': const Color(0xFF2563EB),
      'statusBg': const Color(0xFFDBEAFE),
      'icon': Icons.assignment_late_rounded,
    },
    {
      'id': 'JOB-9842',
      'service': 'Deep Home Sanitization &\nCleaning',
      'property': 'Sunset Luxury Villa, SF',
      'provider': 'David Miller',
      'rating': '4.9 ★',
      'price': '\$180.00',
      'date': 'Today, Aug 02 • 02:00 PM',
      'status': 'In Progress',
      'type': 'ongoing',
      'statusColor': AppColors.primaryDark,
      'statusBg': const Color(0xFFF3F6E6),
      'icon': Icons.cleaning_services_rounded,
    },
    {
      'id': 'JOB-9845',
      'service': 'HVAC Filter & Air Quality\nService',
      'property': 'Downtown Studio Apt, SF',
      'provider': 'Marcus Vance',
      'rating': '4.8 ★',
      'price': '\$95.00',
      'date': 'Today, Aug 02 • 04:30 PM',
      'status': 'Pro En Route',
      'type': 'ongoing',
      'statusColor': const Color(0xFFD97706),
      'statusBg': const Color(0xFFFEF3C7),
      'icon': Icons.tune_rounded,
    },
    {
      'id': 'JOB-9811',
      'service': 'Kitchen Sink Pipe Replacement',
      'property': 'Sunset Luxury Villa, SF',
      'provider': 'QuickFix Plumbing Ltd',
      'rating': '4.9 ★',
      'price': '\$145.00',
      'date': 'Jul 28, 2026',
      'status': 'Completed',
      'type': 'completed',
      'statusColor': AppColors.primaryDark,
      'statusBg': const Color(0xFFF3F6E6),
      'icon': Icons.plumbing_rounded,
    },
    {
      'id': 'JOB-9788',
      'service': 'Electrical Panel Health Checkup',
      'property': 'Silicon Valley Office',
      'provider': 'Apex Electricians',
      'rating': '4.7 ★',
      'price': '\$220.00',
      'date': 'Jul 15, 2026',
      'status': 'Completed',
      'type': 'completed',
      'statusColor': AppColors.primaryDark,
      'statusBg': const Color(0xFFF3F6E6),
      'icon': Icons.electrical_services_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JobRequestCubit>().loadJobRequests();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _mapJobRequestToCard(JobRequestEntity req) {
    final catName = req.serviceCategory?.name ?? 'General Service';
    final serviceTitle = req.description.isNotEmpty ? req.description : catName;
    final propertyTitle = req.property?.label.isNotEmpty == true
        ? req.property!.label
        : (req.property?.city.isNotEmpty == true
            ? req.property!.city
            : 'Saved Location');

    final String type;
    final String status;
    final Color statusColor;
    final Color statusBg;

    if (req.isCancelled) {
      type = 'completed';
      status = 'Cancelled';
      statusColor = const Color(0xFFDC2626);
      statusBg = const Color(0xFFFEE2E2);
    } else if (req.isCompleted) {
      type = 'completed';
      status = 'Completed';
      statusColor = AppColors.primaryDark;
      statusBg = const Color(0xFFF3F6E6);
    } else if (req.isAssigned) {
      type = 'ongoing';
      status = req.assignment?.status.isNotEmpty == true
          ? req.assignment!.status.toUpperCase()
          : 'In Progress';
      statusColor = AppColors.primaryDark;
      statusBg = const Color(0xFFF3F6E6);
    } else if (req.hasQuotations) {
      type = 'to_approve';
      status = '${req.quotations.length} Quote(s)';
      statusColor = const Color(0xFF2563EB);
      statusBg = const Color(0xFFDBEAFE);
    } else {
      type = 'waiting';
      status = 'Waiting';
      statusColor = const Color(0xFFD97706);
      statusBg = const Color(0xFFFEF3C7);
    }

    final String provider = req.assignment?.providerName ??
        (req.hasQuotations
            ? '${req.quotations.first.provider?.name ?? 'Provider'} + ${req.quotations.length - 1} more'
            : 'Awaiting Quotes');

    final String price;
    if (req.assignment != null && req.quotations.isNotEmpty) {
      final accepted = req.quotations.firstWhere(
        (q) => q.isAccepted,
        orElse: () => req.quotations.first,
      );
      price = '\$${accepted.quotedPrice.toStringAsFixed(2)}';
    } else if (req.quotations.isNotEmpty) {
      final lowest = req.quotations
          .map((q) => q.quotedPrice)
          .reduce((a, b) => a < b ? a : b);
      price = 'From \$${lowest.toStringAsFixed(2)}';
    } else {
      price = 'Pending Quote';
    }

    final String dateStr = req.preferredDate != null
        ? DateFormat('EEE, MMM d • hh:mm a').format(req.preferredDate!)
        : 'Flexible Date';

    IconData icon = Icons.build_rounded;
    final lowerCat = catName.toLowerCase();
    if (lowerCat.contains('plumb')) {
      icon = Icons.plumbing_rounded;
    } else if (lowerCat.contains('elect')) {
      icon = Icons.electrical_services_rounded;
    } else if (lowerCat.contains('clean')) {
      icon = Icons.cleaning_services_rounded;
    } else if (lowerCat.contains('paint')) {
      icon = Icons.format_paint_rounded;
    } else if (lowerCat.contains('garden')) {
      icon = Icons.yard_rounded;
    } else if (lowerCat.contains('appliance') || lowerCat.contains('fridge')) {
      icon = Icons.kitchen_rounded;
    } else if (lowerCat.contains('hvac') || lowerCat.contains('air')) {
      icon = Icons.hvac_rounded;
    } else if (lowerCat.contains('security')) {
      icon = Icons.shield_rounded;
    }

    return {
      'rawId': req.id,
      'id': 'REQ-#${req.id}',
      'service': serviceTitle,
      'property': propertyTitle,
      'provider': provider,
      'rating': req.assignment != null ? '4.9 ★' : 'New',
      'price': price,
      'date': dateStr,
      'status': status,
      'type': type,
      'statusColor': statusColor,
      'statusBg': statusBg,
      'icon': icon,
      'jobRequest': req,
    };
  }

  List<Map<String, dynamic>> _getActiveJobs(List<JobRequestEntity> requests) {
    if (requests.isNotEmpty) {
      return requests.map(_mapJobRequestToCard).toList();
    }
    return _allJobs;
  }

  List<Map<String, dynamic>> _getFilteredJobs(
    List<Map<String, dynamic>> allJobs,
    int tabIndex,
  ) {
    switch (tabIndex) {
      case 0:
        return allJobs.where((j) => j['type'] == 'waiting').toList();
      case 1:
        return allJobs.where((j) => j['type'] == 'to_approve').toList();
      case 2:
        return allJobs.where((j) => j['type'] == 'ongoing').toList();
      case 3:
      default:
        return allJobs.where((j) => j['type'] == 'completed').toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_tabController.length != 4) {
      _tabController.dispose();
      _tabController = TabController(length: 4, vsync: this);
    }

    return BlocBuilder<JobRequestCubit, JobRequestState>(
      builder: (context, state) {
        final requests = context.read<JobRequestCubit>().currentRequests;
        final allJobs = _getActiveJobs(requests);

        final waitingCount = allJobs.where((j) => j['type'] == 'waiting').length;
        final toApproveCount =
            allJobs.where((j) => j['type'] == 'to_approve').length;
        final ongoingCount =
            allJobs.where((j) => j['type'] == 'ongoing').length;
        final completedCount =
            allJobs.where((j) => j['type'] == 'completed').length;

        return Scaffold(
          backgroundColor: const Color(0xFFFBFBFB),
          body: Column(
            children: [
              // Header Section with Dark Olive background
              Container(
                width: double.infinity,
                color: AppColors.primaryDark,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16.h,
                  left: 20.w,
                  right: 20.w,
                  bottom: 20.h,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Bookings & Jobs',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Pill Tab Bar with Liquid Glass Effect
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16.r),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          padding: EdgeInsets.all(4.r),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.25),
                                Colors.white.withValues(alpha: 0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            isScrollable: true,
                            tabAlignment: TabAlignment.start,
                            indicatorSize: TabBarIndicatorSize.tab,
                            labelPadding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 2.h,
                            ),
                            indicator: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.accentLime.withValues(alpha: 0.95),
                                  AppColors.accentLime,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  blurRadius: 1,
                                  offset: const Offset(0, -1),
                                ),
                              ],
                            ),
                            labelColor: AppColors.primaryDark,
                            unselectedLabelColor: Colors.white.withValues(
                              alpha: 0.85,
                            ),
                            labelStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.w700,
                            ),
                            unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.w600,
                            ),
                            dividerColor: Colors.transparent,
                            tabs: [
                              Tab(text: 'Waiting ($waitingCount)'),
                              Tab(text: 'To Approve ($toApproveCount)'),
                              Tab(text: 'Ongoing ($ongoingCount)'),
                              Tab(text: 'Completed ($completedCount)'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content TabBarView
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildJobsList(allJobs, 0),
                    _buildJobsList(allJobs, 1),
                    _buildJobsList(allJobs, 2),
                    _buildJobsList(allJobs, 3),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildJobsList(List<Map<String, dynamic>> allJobs, int tabIndex) {
    final jobs = _getFilteredJobs(allJobs, tabIndex);

    if (jobs.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 64.r,
                color: AppColors.borderUnselected,
              ),
              SizedBox(height: 12.h),
              Text(
                'No jobs in this category',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AllServicesScreen(),
                    ),
                  );
                },
                child: Text(
                  'Explore Services',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryDark,
      backgroundColor: Colors.white,
      strokeWidth: 2.8,
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        await context
            .read<JobRequestCubit>()
            .loadJobRequests(forceRefresh: true);
        if (mounted) {
          DynamicIslandToast.showSuccess(context, 'Bookings updated');
        }
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(18.w, 20.h, 18.w, 120.h),
        itemCount: jobs.length,
        separatorBuilder: (context, index) => SizedBox(height: 16.h),
        itemBuilder: (context, index) {
          final job = jobs[index];
          return _buildJobCard(context, job);
        },
      ),
    );
  }

  Widget _buildJobCard(BuildContext context, Map<String, dynamic> job) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => JobDetailsScreen(
              job: job,
              jobRequest: job['jobRequest'] as JobRequestEntity?,
              jobRequestId: job['rawId'] as int?,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: const Color(0xFFE8ECD8), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(18.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Box
                Container(
                  width: 46.r,
                  height: 46.r,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F6E6),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Center(
                    child: Icon(
                      job['icon'] as IconData,
                      color: AppColors.primaryDark,
                      size: 22.r,
                    ),
                  ),
                ),
                SizedBox(width: 14.w),

                // Title and Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job['service'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15.5.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                          height: 1.25,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        '${job['id']} • ${job['property']}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),

                // Status Tag Badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 5.h,
                  ),
                  decoration: BoxDecoration(
                    color: job['statusBg'] as Color? ?? const Color(0xFFF3F6E6),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    job['status'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: job['statusColor'] as Color,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Divider(height: 1, thickness: 1, color: const Color(0xFFEFF2E4)),
            SizedBox(height: 14.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 15.r,
                      color: AppColors.primaryDark.withValues(alpha: 0.8),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      job['date'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
                Text(
                  job['price'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
