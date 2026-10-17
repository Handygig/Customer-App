import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/src/domain/entities/job_requests/job_request_entity.dart';
import 'package:customer_app/src/domain/entities/job_requests/quotation_entity.dart';
import 'package:customer_app/src/presentation/cubits/job_requests/job_request_cubit.dart';
import 'package:customer_app/src/presentation/cubits/job_requests/job_request_state.dart';
import 'package:customer_app/src/presentation/cubits/payments/card_cubit.dart';
import 'package:customer_app/src/presentation/cubits/payments/card_state.dart';
import 'package:customer_app/src/presentation/screens/chat/chat_screen.dart';
import 'package:customer_app/src/presentation/screens/profile/payment_methods_screen.dart';
import 'package:customer_app/src/presentation/widgets/dynamic_island_toast.dart';

class JobDetailsScreen extends StatefulWidget {
  final Map<String, dynamic>? job;
  final JobRequestEntity? jobRequest;
  final int? jobRequestId;

  const JobDetailsScreen({
    super.key,
    this.job,
    this.jobRequest,
    this.jobRequestId,
  });

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  int? _resolvedJobId;

  @override
  void initState() {
    super.initState();
    _resolvedJobId = widget.jobRequestId ?? widget.jobRequest?.id;
    if (_resolvedJobId == null &&
        widget.job != null &&
        widget.job!['rawId'] is int) {
      _resolvedJobId = widget.job!['rawId'] as int;
    }

    if (_resolvedJobId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<JobRequestCubit>().loadJobRequestDetails(_resolvedJobId!);
        context
            .read<JobRequestCubit>()
            .loadJobRequestQuotations(_resolvedJobId!);
      });
    }
  }

  Future<void> _confirmCancelRequest(BuildContext context, int? jobId) async {
    if (jobId == null) {
      DynamicIslandToast.showError(context, 'Cannot cancel: Job ID not found.');
      return;
    }

    HapticFeedback.mediumImpact();
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          'Cancel Job Request?',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18.sp,
          ),
        ),
        content: Text(
          'Are you sure you want to cancel this job request? Providers will no longer be able to submit quotes for this job.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5.sp,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(
              'Keep Request',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text(
              'Yes, Cancel',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldCancel == true && context.mounted) {
      final success =
          await context.read<JobRequestCubit>().cancelJobRequest(jobId);
      if (context.mounted) {
        if (success) {
          DynamicIslandToast.showSuccess(
              context, 'Job request cancelled successfully');
          Navigator.pop(context);
        } else {
          final state = context.read<JobRequestCubit>().state;
          final error = state is JobRequestError
              ? state.message
              : 'Failed to cancel job request';
          DynamicIslandToast.showError(context, error);
        }
      }
    }
  }

  Future<void> _confirmAcceptQuotation(
    BuildContext context,
    QuotationEntity quote,
    int jobId,
  ) async {
    HapticFeedback.mediumImpact();
    final shouldAccept = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          'Accept Quotation?',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18.sp,
          ),
        ),
        content: Text(
          'Accept quote from ${quote.provider?.name ?? 'Provider'} for \$${quote.quotedPrice.toStringAsFixed(2)}? This will assign the job to this provider.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5.sp,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(
              'Review Later',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text(
              'Accept & Assign',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldAccept == true && context.mounted) {
      final success = await context
          .read<JobRequestCubit>()
          .acceptQuotation(quote.id, jobId);
      if (context.mounted) {
        if (success) {
          DynamicIslandToast.showSuccess(
            context,
            'Quotation accepted! Job assigned to ${quote.provider?.name ?? 'Provider'}.',
          );
        } else {
          final state = context.read<JobRequestCubit>().state;
          final error = state is JobRequestError
              ? state.message
              : 'Failed to accept quotation';
          DynamicIslandToast.showError(context, error);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobCubit = context.watch<JobRequestCubit>();
    final activeRequest = (_resolvedJobId != null &&
            jobCubit.selectedJobRequest?.id == _resolvedJobId)
        ? jobCubit.selectedJobRequest
        : (widget.jobRequest ??
            (widget.job?['jobRequest'] as JobRequestEntity?));

    final quotations = (_resolvedJobId != null)
        ? jobCubit.quotationsFor(_resolvedJobId!)
        : (activeRequest?.quotations ?? const <QuotationEntity>[]);

    final String jobId = activeRequest != null
        ? 'REQ-#${activeRequest.id}'
        : (widget.job?['id'] as String? ?? 'JOB-0000');
    final String service = activeRequest != null
        ? (activeRequest.serviceCategory?.name ?? activeRequest.description)
        : (widget.job?['service'] as String? ?? 'Service Details');
    final String descriptionText = activeRequest?.description ?? '';
    final String property = activeRequest != null
        ? (activeRequest.property?.label.isNotEmpty == true
            ? '${activeRequest.property!.label} • ${activeRequest.property!.fullAddress}'
            : (activeRequest.property?.fullAddress ?? 'Primary Location'))
        : (widget.job?['property'] as String? ?? 'Primary Location');
    final String providerName = activeRequest?.assignment?.providerName ??
        (quotations.isNotEmpty
            ? (quotations.first.provider?.name ?? 'Assigned Professional')
            : (widget.job?['provider'] as String? ?? 'Awaiting Assignment'));
    final String rating = activeRequest?.assignment != null
        ? '4.9 ★'
        : (widget.job?['rating'] as String? ?? 'New');

    final String price;
    if (activeRequest != null &&
        activeRequest.assignment != null &&
        quotations.isNotEmpty) {
      final accepted = quotations.firstWhere(
        (q) => q.isAccepted,
        orElse: () => quotations.first,
      );
      price = '\$${accepted.quotedPrice.toStringAsFixed(2)}';
    } else if (quotations.isNotEmpty) {
      final lowest =
          quotations.map((q) => q.quotedPrice).reduce((a, b) => a < b ? a : b);
      price = '\$${lowest.toStringAsFixed(2)}';
    } else {
      price = widget.job?['price'] as String? ?? '\$0.00';
    }

    final String date = activeRequest?.preferredDate != null
        ? DateFormat('EEE, MMM d • hh:mm a')
            .format(activeRequest!.preferredDate!)
        : (widget.job?['date'] as String? ?? 'Scheduled Date');

    final String status;
    final String type;
    final Color statusColor;
    final Color statusBg;
    if (activeRequest != null) {
      if (activeRequest.isCancelled) {
        status = 'Cancelled';
        type = 'cancelled';
        statusColor = const Color(0xFFDC2626);
        statusBg = const Color(0xFFFEE2E2);
      } else if (activeRequest.isCompleted) {
        status = 'Completed';
        type = 'completed';
        statusColor = AppColors.primaryDark;
        statusBg = const Color(0xFFF3F6E6);
      } else if (activeRequest.isAssigned) {
        status = activeRequest.assignment?.status.isNotEmpty == true
            ? activeRequest.assignment!.status.toUpperCase()
            : 'In Progress';
        type = 'ongoing';
        statusColor = AppColors.primaryDark;
        statusBg = const Color(0xFFF3F6E6);
      } else if (quotations.isNotEmpty) {
        status = '${quotations.length} Quote(s)';
        type = 'to_approve';
        statusColor = const Color(0xFF2563EB);
        statusBg = const Color(0xFFDBEAFE);
      } else {
        status = 'Waiting';
        type = 'waiting';
        statusColor = const Color(0xFFD97706);
        statusBg = const Color(0xFFFEF3C7);
      }
    } else {
      status = widget.job?['status'] as String? ?? 'Pending';
      type = widget.job?['type'] as String? ?? 'ongoing';
      statusColor =
          widget.job?['statusColor'] as Color? ?? AppColors.primaryDark;
      statusBg = widget.job?['statusBg'] as Color? ?? const Color(0xFFF3F6E6);
    }

    final IconData icon =
        widget.job?['icon'] as IconData? ?? Icons.cleaning_services_rounded;
    final bool canCancel = activeRequest?.canCancel ??
        (type == 'waiting' || status == 'Pending' || status == 'Waiting');

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFBFBFB),
        body: Column(
          children: [
            // Top Dark Header Section
            _buildTopHeader(
              context,
              jobId,
              status,
              statusColor,
              statusBg,
              canCancel: canCancel,
              onCancel: () => _confirmCancelRequest(context, _resolvedJobId),
            ),

            // Scrollable Content
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primaryDark,
                backgroundColor: Colors.white,
                strokeWidth: 2.8,
                onRefresh: () async {
                  HapticFeedback.mediumImpact();
                  if (_resolvedJobId != null) {
                    await Future.wait([
                      context
                          .read<JobRequestCubit>()
                          .loadJobRequestDetails(_resolvedJobId!),
                      context
                          .read<JobRequestCubit>()
                          .loadJobRequestQuotations(_resolvedJobId!),
                    ]);
                  } else {
                    await Future.delayed(const Duration(milliseconds: 500));
                  }
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
                      _buildJobOverviewCard(
                        service,
                        property,
                        date,
                        icon,
                        description: descriptionText.isNotEmpty &&
                                descriptionText != service
                            ? descriptionText
                            : null,
                      ),
                      SizedBox(height: 20.h),

                      // Received Provider Quotations Section
                      if (_resolvedJobId != null || quotations.isNotEmpty) ...[
                        _buildQuotationsSection(
                          context,
                          quotations,
                          _resolvedJobId,
                          activeRequest?.isPending ??
                              (status == 'Waiting' || status == 'Pending'),
                        ),
                        SizedBox(height: 20.h),
                      ],

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
            _buildBottomActionBar(
              context,
              type,
              providerName,
              service,
              jobId,
              widget.job ??
                  {
                    'id': jobId,
                    'service': service,
                    'property': property,
                    'provider': providerName,
                    'price': price,
                    'date': date,
                    'status': status,
                    'type': type,
                    'rawId': _resolvedJobId,
                  },
              canCancel: canCancel,
              onCancel: () => _confirmCancelRequest(context, _resolvedJobId),
            ),
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
    Color statusBg, {
    bool canCancel = false,
    VoidCallback? onCancel,
  }) {
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
              if (canCancel && onCancel != null)
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: Colors.white,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  onSelected: (value) {
                    if (value == 'cancel') {
                      onCancel();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'cancel',
                      child: Row(
                        children: [
                          Icon(
                            Icons.cancel_outlined,
                            color: const Color(0xFFDC2626),
                            size: 18.r,
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            'Cancel Request',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFDC2626),
                              fontSize: 13.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              else
                IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: Colors.white.withValues(alpha: 0.5),
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
    IconData icon, {
    String? description,
  }) {
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
          if (description != null && description.isNotEmpty) ...[
            SizedBox(height: 14.h),
            const Divider(height: 1, color: Color(0xFFEFF2E4)),
            SizedBox(height: 14.h),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Job Details & Notes',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5.sp,
                    color: AppColors.primaryDark,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuotationsSection(
    BuildContext context,
    List<QuotationEntity> quotations,
    int? jobId,
    bool canAccept,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Provider Quotations',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15.5.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: quotations.isEmpty
                      ? const Color(0xFFFEF3C7)
                      : const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  quotations.isEmpty
                      ? 'Waiting for Quotes'
                      : '${quotations.length} Received',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w700,
                    color: quotations.isEmpty
                        ? const Color(0xFFD97706)
                        : const Color(0xFF1D4ED8),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          if (quotations.isEmpty) ...[
            Container(
              padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: const Color(0xFFF0F1EA)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36.r,
                    height: 36.r,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEF3C7),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.hourglass_top_rounded,
                        color: const Color(0xFFD97706),
                        size: 18.r,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No quotes submitted yet',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Service providers in your area will review your request shortly.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5.sp,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: quotations.length,
              separatorBuilder: (_, _) => SizedBox(height: 12.h),
              itemBuilder: (context, index) {
                final quote = quotations[index];
                return _buildQuotationCard(
                  context,
                  quote,
                  jobId,
                  canAccept: canAccept && quote.isPending,
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuotationCard(
    BuildContext context,
    QuotationEntity quote,
    int? jobId, {
    required bool canAccept,
  }) {
    final providerName = quote.provider?.name ?? 'Service Professional';
    final rating = quote.provider?.rating != null
        ? '${quote.provider!.rating!.toStringAsFixed(1)} ★'
        : 'Top Rated';

    final Color badgeBg;
    final Color badgeColor;
    final String badgeText;

    if (quote.isAccepted) {
      badgeBg = const Color(0xFFDCFCE7);
      badgeColor = const Color(0xFF16A34A);
      badgeText = 'Accepted';
    } else if (quote.isRejected) {
      badgeBg = const Color(0xFFFEE2E2);
      badgeColor = const Color(0xFFDC2626);
      badgeText = 'Declined';
    } else {
      badgeBg = const Color(0xFFEFF6FF);
      badgeColor = const Color(0xFF2563EB);
      badgeText = 'Pending';
    }

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBF7),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: quote.isAccepted
              ? const Color(0xFF86EFAC)
              : const Color(0xFFE2E6D5),
          width: quote.isAccepted ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundColor: AppColors.primaryDark,
                child: Text(
                  providerName.isNotEmpty ? providerName[0].toUpperCase() : 'P',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
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
                            providerName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDark,
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
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            badgeText,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 14.r,
                          color: const Color(0xFFD97706),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          rating,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        if (quote.estimatedDuration != null &&
                            quote.estimatedDuration!.isNotEmpty) ...[
                          Text(
                            ' • ',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5.sp,
                              color: AppColors.textMuted,
                            ),
                          ),
                          Icon(
                            Icons.schedule_rounded,
                            size: 13.r,
                            color: AppColors.textMuted,
                          ),
                          SizedBox(width: 3.w),
                          Text(
                            quote.estimatedDuration!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5.sp,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (quote.message != null && quote.message!.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: const Color(0xFFECEFE4)),
              ),
              child: Text(
                quote.message!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ),
          ],
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quote Price',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.sp,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '\$${quote.quotedPrice.toStringAsFixed(2)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
              if (canAccept && jobId != null)
                ElevatedButton.icon(
                  onPressed: () => _confirmAcceptQuotation(context, quote, jobId),
                  icon: Icon(Icons.check_circle_outline_rounded, size: 16.r),
                  label: Text(
                    'Accept Quote',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 10.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTimeline(String type) {
    if (type == 'cancelled') {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(18.r),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(color: const Color(0xFFFECACA), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 36.r,
              height: 36.r,
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.cancel_rounded,
                  color: const Color(0xFFDC2626),
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
                    'Request Cancelled',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF991B1B),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'This job request was cancelled. No further quotes can be submitted.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.sp,
                      color: const Color(0xFFB91C1C),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

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
    Map<String, dynamic> job, {
    bool canCancel = false,
    VoidCallback? onCancel,
  }) {
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
        'cancelled' => Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 14.h),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Center(
              child: Text(
                'Job Request Cancelled',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFDC2626),
                ),
              ),
            ),
          ),
        'waiting' => Row(
            children: [
              if (canCancel && onCancel != null) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCancel,
                    icon: Icon(
                      Icons.cancel_outlined,
                      size: 16.r,
                      color: const Color(0xFFDC2626),
                    ),
                    label: Text(
                      'Cancel Request',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      side: const BorderSide(
                        color: Color(0xFFFCA5A5),
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
              ],
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    if (_resolvedJobId != null) {
                      context
                          .read<JobRequestCubit>()
                          .loadJobRequestDetails(_resolvedJobId!);
                      context
                          .read<JobRequestCubit>()
                          .loadJobRequestQuotations(_resolvedJobId!);
                      DynamicIslandToast.showSuccess(
                        context,
                        'Checking for quotes...',
                      );
                    }
                  },
                  icon: Icon(Icons.refresh_rounded, size: 16.r),
                  label: Text(
                    'Refresh Quotes',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        'to_approve' => Row(
            children: [
              if (canCancel && onCancel != null) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      side: const BorderSide(color: Color(0xFFDC2626)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    child: Text(
                      'Cancel Request',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 14.w),
              ],
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showPayJobAssignmentModal(context, job),
                  icon: Icon(Icons.payment_rounded, size: 18.r),
                  label: Text(
                    'Pay & Approve',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
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

  void _showPayJobAssignmentModal(
    BuildContext context,
    Map<String, dynamic> job,
  ) {
    HapticFeedback.mediumImpact();
    final String service = job['service'] as String? ?? 'Service Assignment';
    final String provider = job['provider'] as String? ?? 'Assigned Pro';
    final String price = job['price'] as String? ?? '\$0.00';

    int assignmentId = 1;
    if (job['assignment_id'] is int) {
      assignmentId = job['assignment_id'] as int;
    } else if (job['assignment_id'] is String) {
      assignmentId = int.tryParse(job['assignment_id'] as String) ?? 1;
    } else if (job['id'] is int) {
      assignmentId = job['id'] as int;
    } else if (job['id'] is String) {
      final digits = (job['id'] as String).replaceAll(RegExp(r'\D'), '');
      assignmentId = int.tryParse(digits) ?? 1;
    }

    final cardCubit = context.read<CardCubit>();
    cardCubit.loadCards(silent: true);

    int? selectedId = cardCubit.selectedCard?.id ??
        (cardCubit.cards.isNotEmpty ? cardCubit.cards.first.id : null);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return BlocBuilder<CardCubit, CardState>(
              bloc: cardCubit,
              builder: (context, cardState) {
                final cards = cardCubit.cards;
                final isLoading = cardState is CardLoading;

                if (selectedId == null && cards.isNotEmpty) {
                  final active = cards.firstWhere(
                    (c) => c.isDefault && !c.isFrozen,
                    orElse: () => cards.firstWhere(
                      (c) => !c.isFrozen,
                      orElse: () => cards.first,
                    ),
                  );
                  selectedId = active.id;
                }

                return Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.85,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28.r),
                    ),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    20.w,
                    16.h,
                    20.w,
                    MediaQuery.of(context).padding.bottom + 20.h,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 44.w,
                          height: 4.h,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD6DBBA),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                      ),
                      SizedBox(height: 18.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Pay & Complete Job',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F6E6),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Text(
                              price,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        '$service • $provider',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5.sp,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 18.h),
                      Text(
                        'Select Payment Card',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      if (cards.isEmpty)
                        Container(
                          padding: EdgeInsets.all(16.r),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBFBFB),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(color: const Color(0xFFE8ECD8)),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'No payment cards available.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.sp,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              SizedBox(height: 10.h),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(bottomSheetContext);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const PaymentMethodsScreen(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryDark,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                ),
                                child: const Text(
                                  'Add Card in Settings',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Flexible(
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: cards.length,
                            separatorBuilder: (_, _) => SizedBox(height: 10.h),
                            itemBuilder: (context, index) {
                              final card = cards[index];
                              final isSelected = selectedId == card.id;
                              final isFrozen = card.isFrozen;

                              return InkWell(
                                onTap: isFrozen
                                    ? null
                                    : () {
                                        setModalState(() {
                                          selectedId = card.id;
                                        });
                                      },
                                borderRadius: BorderRadius.circular(14.r),
                                child: Container(
                                  padding: EdgeInsets.all(12.r),
                                  decoration: BoxDecoration(
                                    color: isFrozen
                                        ? const Color(0xFFF3F4F6)
                                        : (isSelected
                                            ? const Color(0xFFF3F6E6)
                                            : Colors.white),
                                    borderRadius: BorderRadius.circular(14.r),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primaryDark
                                          : const Color(0xFFE8ECD8),
                                      width: isSelected ? 1.8 : 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.credit_card_rounded,
                                        color: isFrozen
                                            ? Colors.grey
                                            : AppColors.primaryDark,
                                        size: 24.r,
                                      ),
                                      SizedBox(width: 12.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  '${card.cardType.toUpperCase()} •••• ${card.lastFourDigits}',
                                                  style: GoogleFonts
                                                      .plusJakartaSans(
                                                    fontSize: 13.5.sp,
                                                    fontWeight: FontWeight.w700,
                                                    color: isFrozen
                                                        ? Colors.grey
                                                        : AppColors.primaryDark,
                                                  ),
                                                ),
                                                if (card.isDefault) ...[
                                                  SizedBox(width: 6.w),
                                                  Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                      horizontal: 6.w,
                                                      vertical: 2.h,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          AppColors.primaryDark,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        6.r,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      'DEFAULT',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 9.sp,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            SizedBox(height: 2.h),
                                            Text(
                                              isFrozen
                                                  ? 'Card is Frozen - Unfreeze to use'
                                                  : 'Expires ${card.expiryDate}',
                                              style: GoogleFonts
                                                  .plusJakartaSans(
                                                fontSize: 11.5.sp,
                                                color: isFrozen
                                                    ? Colors.red
                                                    : AppColors.textMuted,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected && !isFrozen)
                                        Icon(
                                          Icons.check_circle_rounded,
                                          color: AppColors.primaryDark,
                                          size: 20.r,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      SizedBox(height: 20.h),
                      SizedBox(
                        width: double.infinity,
                        height: 50.h,
                        child: ElevatedButton(
                          onPressed:
                              (isLoading || selectedId == null || cards.isEmpty)
                                  ? null
                                  : () async {
                                      HapticFeedback.mediumImpact();
                                      final success = await cardCubit
                                          .payJobAssignment(
                                        jobAssignmentId: assignmentId,
                                        cardId: selectedId!,
                                      );
                                      if (context.mounted &&
                                          bottomSheetContext.mounted) {
                                        if (success) {
                                          Navigator.pop(bottomSheetContext);
                                          DynamicIslandToast.showSuccess(
                                            context,
                                            'Payment successful! Assignment completed.',
                                          );
                                          Navigator.pop(context);
                                        } else {
                                          final err =
                                              cardCubit.state is CardError
                                                  ? (cardCubit.state
                                                          as CardError)
                                                      .message
                                                  : 'Payment failed';
                                          DynamicIslandToast.showError(
                                            context,
                                            err,
                                          );
                                        }
                                      }
                                    },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryDark,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                          ),
                          child: isLoading
                              ? SizedBox(
                                  height: 20.r,
                                  width: 20.r,
                                  child: const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Confirm & Pay $price',
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
                );
              },
            );
          },
        );
      },
    );
  }
}
