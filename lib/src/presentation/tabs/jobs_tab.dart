import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/src/domain/entities/job_requests/job_request_entity.dart';
import 'package:customer_app/src/domain/entities/job_requests/job_assignment_entity.dart';
import 'package:customer_app/src/presentation/cubits/job_requests/job_request_cubit.dart';
import 'package:customer_app/src/presentation/cubits/job_requests/job_request_state.dart';
import 'package:customer_app/src/presentation/cubits/job_assignments/job_assignment_cubit.dart';
import 'package:customer_app/src/presentation/cubits/job_assignments/job_assignment_state.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_app/config/router/app_routes.dart';
import 'package:customer_app/src/presentation/screens/jobs/job_details_screen.dart';
import 'package:customer_app/src/presentation/screens/services/all_services_screen.dart';
import 'package:customer_app/src/presentation/widgets/dynamic_island_toast.dart';
import 'package:customer_app/core/utils/extensions.dart';

class JobsTab extends StatefulWidget {
  const JobsTab({super.key});

  @override
  State<JobsTab> createState() => _JobsTabState();
}

class _JobsTabState extends State<JobsTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JobRequestCubit>().loadJobRequests();
      context.read<JobAssignmentCubit>().loadAssignments();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(String catName) {
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
    return icon;
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

    final String provider = req.hasQuotations
        ? '${req.quotations.first.provider?.name ?? 'Provider'}${req.quotations.length > 1 ? ' + ${req.quotations.length - 1} more' : ''}'
        : 'Awaiting Quotes';

    final String price;
    if (req.quotations.isNotEmpty) {
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

    return {
      'rawId': req.id,
      'id': 'REQ-#${req.id}',
      'service': serviceTitle,
      'property': propertyTitle,
      'provider': provider,
      'rating': req.hasQuotations ? 'Quotes Available' : 'New',
      'price': price,
      'date': dateStr,
      'status': status,
      'type': type,
      'statusColor': statusColor,
      'statusBg': statusBg,
      'icon': _getCategoryIcon(catName),
      'jobRequest': req,
      'isAssignment': false,
    };
  }

  Map<String, dynamic> _mapAssignmentToCard(JobAssignmentEntity assignment) {
    final catName =
        assignment.jobRequest?.serviceCategory?.name ?? 'Assigned Service';
    final serviceTitle = assignment.jobRequest?.description.isNotEmpty == true
        ? assignment.jobRequest!.description
        : catName;
    final propertyTitle = assignment.jobRequest?.property?.label.isNotEmpty == true
        ? assignment.jobRequest!.property!.label
        : (assignment.jobRequest?.property?.city.isNotEmpty == true
            ? assignment.jobRequest!.property!.city
            : 'Service Location');

    final String type;
    final String statusText;
    final Color statusColor;
    final Color statusBg;

    if (assignment.isCancelled) {
      type = 'completed';
      statusText = 'Cancelled';
      statusColor = const Color(0xFFDC2626);
      statusBg = const Color(0xFFFEE2E2);
    } else if (assignment.isCompleted) {
      type = 'completed';
      statusText = 'Completed';
      statusColor = AppColors.primaryDark;
      statusBg = const Color(0xFFF3F6E6);
    } else {
      type = 'ongoing';
      statusText = assignment.status.isNotEmpty
          ? assignment.status.replaceAll('_', ' ').toUpperCase()
          : 'SCHEDULED';
      statusColor = AppColors.primaryDark;
      statusBg = const Color(0xFFF3F6E6);
    }

    final String provider = assignment.providerName ??
        (assignment.companyName ?? 'Assigned Professional');

    final String price;
    if (assignment.payment != null) {
      price = '\$${assignment.payment!.amount.toStringAsFixed(2)}';
    } else if (assignment.quotation != null) {
      price = '\$${assignment.quotation!.quotedPrice.toStringAsFixed(2)}';
    } else {
      price = 'Fixed Rate';
    }

    final dateVal = assignment.startDate ??
        assignment.assignedAt ??
        assignment.jobRequest?.preferredDate;
    final String dateStr = dateVal != null
        ? DateFormat('EEE, MMM d • hh:mm a').format(dateVal)
        : 'Scheduled';

    return {
      'rawId': assignment.id,
      'id': 'JOB-#${assignment.id}',
      'service': serviceTitle,
      'property': propertyTitle,
      'provider': provider,
      'rating': '4.9 ★',
      'price': price,
      'date': dateStr,
      'status': statusText,
      'type': type,
      'statusColor': statusColor,
      'statusBg': statusBg,
      'icon': _getCategoryIcon(catName),
      'assignment': assignment,
      'isAssignment': true,
    };
  }

  List<Map<String, dynamic>> _getActiveJobs(
    List<JobRequestEntity> requests,
    List<JobAssignmentEntity> assignments,
  ) {
    final List<Map<String, dynamic>> list = [];

    // Pending / Unassigned job requests populate Waiting and To Approve tabs
    for (final req in requests) {
      if (!req.isAssigned) {
        list.add(_mapJobRequestToCard(req));
      } else if (req.isCancelled) {
        list.add(_mapJobRequestToCard(req));
      }
    }

    // Assignments populate Ongoing and Completed tabs
    for (final assignment in assignments) {
      list.add(_mapAssignmentToCard(assignment));
    }

    return list;
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
      builder: (context, requestState) {
        return BlocBuilder<JobAssignmentCubit, JobAssignmentState>(
          builder: (context, assignmentState) {
            final requests = context.read<JobRequestCubit>().currentRequests;
            final assignments =
                context.read<JobAssignmentCubit>().currentAssignments;
            final allJobs = _getActiveJobs(requests, assignments);

            final waitingCount =
                allJobs.where((j) => j['type'] == 'waiting').length;
            final toApproveCount =
                allJobs.where((j) => j['type'] == 'to_approve').length;
            final ongoingCount =
                allJobs.where((j) => j['type'] == 'ongoing').length;
            final completedCount =
                allJobs.where((j) => j['type'] == 'completed').length;

            final isLoading = (requestState is JobRequestLoading &&
                    requests.isEmpty) ||
                (assignmentState is JobAssignmentLoading && assignments.isEmpty);

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
                          context.loc.myBookingsAndJobs,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          context.loc.myBookingsSubtitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.sp,
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 18.h),

                        // Enhanced Modern Segmented Tab Bar
                        Container(
                          height: 48.h,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                          padding: EdgeInsets.all(4.r),
                          child: TabBar(
                            controller: _tabController,
                            indicator: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            labelColor: AppColors.primaryDark,
                            unselectedLabelColor:
                                Colors.white.withValues(alpha: 0.85),
                            labelStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w800,
                            ),
                            unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w600,
                            ),
                            dividerColor: Colors.transparent,
                            tabs: [
                              Tab(text: '${context.loc.tabWaiting} ($waitingCount)'),
                              Tab(text: '${context.loc.tabToApprove} ($toApproveCount)'),
                              Tab(text: '${context.loc.tabOngoing} ($ongoingCount)'),
                              Tab(text: '${context.loc.tabCompleted} ($completedCount)'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content TabBarView
                  Expanded(
                    child: isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primaryDark,
                            ),
                          )
                        : TabBarView(
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
      },
    );
  }

  Widget _buildJobsList(List<Map<String, dynamic>> allJobs, int tabIndex) {
    final jobs = _getFilteredJobs(allJobs, tabIndex);

    if (jobs.isEmpty) {
      final tabLabels = [
        context.loc.waitingRequests,
        context.loc.quotesToApprove,
        context.loc.ongoingJobs.toLowerCase(),
        context.loc.completedJobs,
      ];
      final currentCategory = tabLabels[tabIndex];

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
                context.loc.noJobsInCategory(currentCategory),
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
                onPressed: () => context.push(AppRoutes.allServices),
                child: Text(
                  context.loc.exploreServices,
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
        await Future.wait([
          context.read<JobRequestCubit>().loadJobRequests(forceRefresh: true),
          context.read<JobAssignmentCubit>().loadAssignments(forceRefresh: true),
        ]);
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
        context.push(
          AppRoutes.jobDetails,
          extra: {
            'job': job,
            'jobRequest': job['jobRequest'] as JobRequestEntity?,
            'jobRequestId': job['isAssignment'] != true
                ? (job['rawId'] as int?)
                : null,
            'jobAssignment': job['assignment'] as JobAssignmentEntity?,
            'assignmentId': job['isAssignment'] == true
                ? (job['rawId'] as int?)
                : null,
          },
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
            const Divider(height: 1, thickness: 1, color: Color(0xFFEFF2E4)),
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
