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
import 'package:customer_app/src/domain/entities/job_requests/job_assignment_entity.dart';
import 'package:customer_app/src/presentation/cubits/job_assignments/job_assignment_cubit.dart';
import 'package:customer_app/src/presentation/cubits/job_assignments/job_assignment_state.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_app/config/router/app_routes.dart';
import 'package:customer_app/src/domain/entities/properties/property_entity.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:customer_app/src/presentation/widgets/dynamic_island_toast.dart';

class JobDetailsScreen extends StatefulWidget {
  final Map<String, dynamic>? job;
  final JobRequestEntity? jobRequest;
  final int? jobRequestId;
  final JobAssignmentEntity? jobAssignment;
  final int? assignmentId;

  const JobDetailsScreen({
    super.key,
    this.job,
    this.jobRequest,
    this.jobRequestId,
    this.jobAssignment,
    this.assignmentId,
  });

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  int? _resolvedJobId;
  int? _resolvedAssignmentId;

  @override
  void initState() {
    super.initState();
    _resolvedAssignmentId = widget.assignmentId ?? widget.jobAssignment?.id;
    if (_resolvedAssignmentId == null &&
        widget.job != null &&
        widget.job!['isAssignment'] == true &&
        widget.job!['rawId'] is int) {
      _resolvedAssignmentId = widget.job!['rawId'] as int;
    }

    _resolvedJobId = widget.jobRequestId ?? widget.jobRequest?.id;
    if (_resolvedJobId == null &&
        widget.job != null &&
        widget.job!['isAssignment'] != true &&
        widget.job!['rawId'] is int) {
      _resolvedJobId = widget.job!['rawId'] as int;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_resolvedAssignmentId != null) {
        context
            .read<JobAssignmentCubit>()
            .loadAssignmentDetails(_resolvedAssignmentId!);
      }
      if (_resolvedJobId != null) {
        context.read<JobRequestCubit>().loadJobRequestDetails(_resolvedJobId!);
        context
            .read<JobRequestCubit>()
            .loadJobRequestQuotations(_resolvedJobId!);
      }
    });
  }

  bool _isSimulatingQuote = false;

  Future<void> _simulateQuote() async {
    if (_resolvedJobId == null) {
      DynamicIslandToast.showError(
        context,
        'Job ID not available for simulation.',
      );
      return;
    }

    setState(() {
      _isSimulatingQuote = true;
    });
    HapticFeedback.mediumImpact();

    try {
      final quotation = await context
          .read<JobRequestCubit>()
          .simulateQuotation(_resolvedJobId!);

      if (!mounted) return;

      if (quotation != null) {
        DynamicIslandToast.showSuccess(
          context,
          'Quotation received from ${quotation.provider?.name ?? 'Provider'} for LKR ${quotation.quotedPrice.toStringAsFixed(2)}!',
        );
      } else {
        final state = context.read<JobRequestCubit>().state;
        final error = state is JobRequestError
            ? state.message
            : 'Failed to simulate quotation';
        DynamicIslandToast.showError(context, error);
      }
    } catch (e) {
      if (mounted) {
        DynamicIslandToast.showError(context, 'Simulation error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSimulatingQuote = false;
        });
      }
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
          'Accept quote from ${quote.provider?.name ?? 'Provider'} for LKR ${quote.quotedPrice.toStringAsFixed(2)}? This will assign the job to this provider.',
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
          context.read<JobRequestCubit>().loadJobRequests(forceRefresh: true);
          context.read<JobAssignmentCubit>().loadAssignments(forceRefresh: true);
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

  bool _isProcessingExtraQuote = false;

  Future<void> _confirmApproveExtraQuote(
    BuildContext context,
    JobAssignmentEntity assignment,
  ) async {
    final extraAmount = assignment.extraAmount ?? 0.0;
    final originalPrice = assignment.quotation?.quotedPrice ?? 0.0;
    final totalEffective = assignment.totalEffectivePrice > 0
        ? assignment.totalEffectivePrice
        : (originalPrice + extraAmount);

    HapticFeedback.mediumImpact();
    final shouldApprove = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: const Color(0xFF16A34A),
                size: 20.r,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                'Approve Updated Quote?',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 17.sp,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The service provider has submitted an updated quotation with additional scope/materials:',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.sp,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 12.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (assignment.extraReason != null &&
                      assignment.extraReason!.trim().isNotEmpty) ...[
                    Text(
                      'Reason for update:',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      '"${assignment.extraReason!}"',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.sp,
                        fontStyle: FontStyle.italic,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    SizedBox(height: 10.h),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Additional Charge:',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '+ LKR ${extraAmount.toStringAsFixed(2)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'New Total Amount:',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      Text(
                        'LKR ${totalEffective.toStringAsFixed(2)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text(
              'Approve Update',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldApprove == true && context.mounted) {
      setState(() {
        _isProcessingExtraQuote = true;
      });
      HapticFeedback.mediumImpact();
      final cubit = context.read<JobAssignmentCubit>();
      try {
        final success = await cubit.approveExtraCharge(assignment.id);

        if (context.mounted) {
          if (success) {
            DynamicIslandToast.showSuccess(
              context,
              'Updated quotation of +LKR ${extraAmount.toStringAsFixed(2)} approved!',
            );
            await cubit.loadAssignments(forceRefresh: true);
            await cubit.loadAssignmentDetails(assignment.id);
          } else {
            final state = cubit.state;
            final error = state is JobAssignmentError
                ? state.message
                : 'Failed to approve updated quotation';
            DynamicIslandToast.showError(context, error);
          }
        }
      } catch (e) {
        if (context.mounted) {
          DynamicIslandToast.showError(context, 'Approval failed: $e');
        }
      } finally {
        if (mounted) {
          setState(() {
            _isProcessingExtraQuote = false;
          });
        }
      }
    }
  }

  Future<void> _confirmRejectExtraQuote(
    BuildContext context,
    JobAssignmentEntity assignment,
  ) async {
    final extraAmount = assignment.extraAmount ?? 0.0;
    HapticFeedback.mediumImpact();
    final shouldReject = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                color: const Color(0xFFDC2626),
                size: 20.r,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                'Decline Updated Quote?',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 17.sp,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to decline this updated quotation request (+LKR ${extraAmount.toStringAsFixed(2)})?\n\nThe provider will be notified to proceed strictly with the original agreed work scope.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5.sp,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(
              'Back',
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
              'Yes, Decline',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldReject == true && context.mounted) {
      setState(() {
        _isProcessingExtraQuote = true;
      });
      HapticFeedback.mediumImpact();
      final cubit = context.read<JobAssignmentCubit>();
      try {
        final success = await cubit.rejectExtraCharge(assignment.id);

        if (context.mounted) {
          if (success) {
            DynamicIslandToast.showInfo(
              context,
              'Updated quotation request declined.',
            );
            await cubit.loadAssignments(forceRefresh: true);
            await cubit.loadAssignmentDetails(assignment.id);
          } else {
            final state = cubit.state;
            final error = state is JobAssignmentError
                ? state.message
                : 'Failed to decline updated quotation';
            DynamicIslandToast.showError(context, error);
          }
        }
      } catch (e) {
        if (context.mounted) {
          DynamicIslandToast.showError(context, 'Decline failed: $e');
        }
      } finally {
        if (mounted) {
          setState(() {
            _isProcessingExtraQuote = false;
          });
        }
      }
    }
  }

  Future<void> _simulateExtraQuote(
    BuildContext context,
    int assignmentId, {
    double? extraAmount,
    String? extraReason,
  }) async {
    setState(() {
      _isProcessingExtraQuote = true;
    });
    HapticFeedback.mediumImpact();
    final cubit = context.read<JobAssignmentCubit>();
    final double amount = extraAmount ?? 2500.0;
    try {
      final updatedAssignment = await cubit.simulateExtraQuote(
        assignmentId,
        extraAmount: amount,
        extraReason: extraReason ?? 'Additional materials and extra pipe fittings required',
      );

      if (context.mounted) {
        if (updatedAssignment != null) {
          DynamicIslandToast.showSuccess(
            context,
            'Provider sent updated quotation of +LKR ${amount.toStringAsFixed(2)}!',
          );
          await cubit.loadAssignments(forceRefresh: true);
          await cubit.loadAssignmentDetails(assignmentId);
        } else {
          final state = cubit.state;
          final error = state is JobAssignmentError
              ? state.message
              : 'Failed to simulate updated quote';
          DynamicIslandToast.showError(context, error);
        }
      }
    } catch (e) {
      if (context.mounted) {
        DynamicIslandToast.showError(context, 'Simulation error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingExtraQuote = false;
        });
      }
    }
  }

  bool _isSimulatingCompleteJob = false;

  Future<void> _simulateCompleteJob(
    BuildContext context,
    int assignmentId,
  ) async {
    setState(() {
      _isSimulatingCompleteJob = true;
    });
    HapticFeedback.mediumImpact();
    final cubit = context.read<JobAssignmentCubit>();
    try {
      final updatedAssignment = await cubit.simulateCompleteJob(assignmentId);

      if (context.mounted) {
        if (updatedAssignment != null) {
          DynamicIslandToast.showSuccess(
            context,
            'Job successfully simulated as completed!',
          );
          await cubit.loadAssignments(forceRefresh: true);
          await cubit.loadAssignmentDetails(assignmentId);
          if (context.mounted) {
            context.read<JobRequestCubit>().loadJobRequests(forceRefresh: true);
          }
        } else {
          final state = cubit.state;
          final error = state is JobAssignmentError
              ? state.message
              : 'Failed to simulate job completion';
          DynamicIslandToast.showError(context, error);
        }
      }
    } catch (e) {
      if (context.mounted) {
        DynamicIslandToast.showError(context, 'Simulation error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSimulatingCompleteJob = false;
        });
      }
    }
  }

  Future<void> _showChangeQuotationDialog(
    BuildContext context,
    int assignmentId,
  ) async {
    final amountController = TextEditingController(text: '2500');
    final reasonController = TextEditingController(
      text: 'Additional materials and extra pipe fittings required',
    );
    double selectedAmount = 2500;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (dialogCtx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20.w,
                right: 20.w,
                top: 20.h,
                bottom: MediaQuery.of(dialogCtx).viewInsets.bottom + 24.h,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(
                          Icons.price_change_rounded,
                          color: const Color(0xFFD97706),
                          size: 20.r,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Simulate Quotation Change',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            Text(
                              'Provider sends updated quotation to customer',
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
                  SizedBox(height: 16.h),
                  Text(
                    'Quick Presets (Extra Amount):',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [1500.0, 2500.0, 5000.0].map((amt) {
                      final isSelected = selectedAmount == amt;
                      return Padding(
                        padding: EdgeInsets.only(right: 8.w),
                        child: ChoiceChip(
                          label: Text('+ LKR ${amt.toInt()}'),
                          selected: isSelected,
                          selectedColor: const Color(0xFFFDE68A),
                          backgroundColor: const Color(0xFFF1F5F9),
                          labelStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 12.sp,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected ? const Color(0xFF78350F) : AppColors.textSecondary,
                          ),
                          onSelected: (val) {
                            if (val) {
                              setModalState(() {
                                selectedAmount = amt;
                                amountController.text = amt.toInt().toString();
                              });
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Additional Amount (LKR):',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      prefixText: 'LKR ',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Reason for update:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  TextField(
                    controller: reasonController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'e.g. Additional materials required',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                        final amt = double.tryParse(amountController.text.trim()) ?? 2500.0;
                        final reason = reasonController.text.trim();
                        _simulateExtraQuote(context, assignmentId, extraAmount: amt, extraReason: reason);
                      },
                      icon: const Icon(Icons.bolt_rounded, color: Colors.white),
                      label: Text(
                        'Send Updated Quotation',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.sp,
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
  }

  @override
  Widget build(BuildContext context) {
    final jobCubit = context.watch<JobRequestCubit>();
    final assignmentCubit = context.watch<JobAssignmentCubit>();

    final activeAssignment = (_resolvedAssignmentId != null &&
            assignmentCubit.selectedAssignment?.id == _resolvedAssignmentId)
        ? assignmentCubit.selectedAssignment
        : (assignmentCubit.currentAssignments
                .any((a) => a.id == _resolvedAssignmentId)
            ? assignmentCubit.currentAssignments
                .firstWhere((a) => a.id == _resolvedAssignmentId)
            : widget.jobAssignment);

    final activeRequest = (_resolvedJobId != null &&
            jobCubit.selectedJobRequest?.id == _resolvedJobId)
        ? jobCubit.selectedJobRequest
        : (widget.jobRequest ??
            (widget.job?['jobRequest'] as JobRequestEntity?));

    final quotations = (_resolvedJobId != null)
        ? jobCubit.quotationsFor(_resolvedJobId!)
        : (activeRequest?.quotations ?? const <QuotationEntity>[]);

    final String jobId;
    final String service;
    final String descriptionText;
    final String property;
    final String providerName;
    final String rating;
    final String price;
    final String date;
    final String status;
    final String type;
    final Color statusColor;
    final Color statusBg;

    if (activeAssignment != null) {
      jobId = 'JOB-#${activeAssignment.id}';
      service = activeAssignment.jobRequest?.serviceCategory?.name ??
          (activeAssignment.jobRequest?.description.isNotEmpty == true
              ? activeAssignment.jobRequest!.description
              : (widget.job?['service'] as String? ?? 'Service Assignment'));
      descriptionText = activeAssignment.jobRequest?.description ?? '';
      final assignLocMatch =
          RegExp(r'\(Location:\s*([^)]+)\)', caseSensitive: false)
              .firstMatch(descriptionText);
      final String? assignExtractedLoc = assignLocMatch?.group(1)?.trim();
      final assignProp = activeAssignment.jobRequest?.property;
      if (assignProp != null && assignProp.fullAddress.isNotEmpty) {
        property = assignProp.label.isNotEmpty
            ? '${assignProp.label} • ${assignProp.fullAddress}'
            : assignProp.fullAddress;
      } else if (assignExtractedLoc != null && assignExtractedLoc.isNotEmpty) {
        property = assignExtractedLoc;
      } else if (assignProp?.label.isNotEmpty == true) {
        property = assignProp!.label;
      } else {
        property = widget.job?['property'] as String? ?? 'Service Location';
      }
      providerName = activeAssignment.providerName ??
          (activeAssignment.companyName ??
              (widget.job?['provider'] as String? ?? 'Assigned Professional'));
      rating = '4.9 ★';

      if (activeAssignment.payment != null) {
        price = 'LKR ${activeAssignment.payment!.amount.toStringAsFixed(2)}';
      } else if (activeAssignment.quotation != null) {
        price =
            'LKR ${activeAssignment.quotation!.quotedPrice.toStringAsFixed(2)}';
      } else {
        price = widget.job?['price'] as String? ?? 'LKR 0.00';
      }

      final dateVal = activeAssignment.startDate ??
          activeAssignment.assignedAt ??
          activeAssignment.jobRequest?.preferredDate;
      date = dateVal != null
          ? DateFormat('EEE, MMM d • hh:mm a').format(dateVal)
          : (widget.job?['date'] as String? ?? 'Scheduled Date');

      if (activeAssignment.isCancelled) {
        status = 'Cancelled';
        type = 'cancelled';
        statusColor = const Color(0xFFDC2626);
        statusBg = const Color(0xFFFEE2E2);
      } else if (activeAssignment.isCompleted) {
        status = 'Completed';
        type = 'completed';
        statusColor = AppColors.primaryDark;
        statusBg = const Color(0xFFF3F6E6);
      } else {
        status = activeAssignment.status.isNotEmpty
            ? activeAssignment.status.replaceAll('_', ' ').toUpperCase()
            : 'SCHEDULED';
        type = 'ongoing';
        statusColor = AppColors.primaryDark;
        statusBg = const Color(0xFFF3F6E6);
      }
    } else if (activeRequest != null) {
      jobId = 'REQ-#${activeRequest.id}';
      service = activeRequest.serviceCategory?.name ??
          (activeRequest.description.isNotEmpty
              ? activeRequest.description
              : 'Service Details');
      descriptionText = activeRequest.description;
      final reqLocMatch =
          RegExp(r'\(Location:\s*([^)]+)\)', caseSensitive: false)
              .firstMatch(descriptionText);
      final String? reqExtractedLoc = reqLocMatch?.group(1)?.trim();
      final reqProp = activeRequest.property;
      if (reqProp != null && reqProp.fullAddress.isNotEmpty) {
        property = reqProp.label.isNotEmpty
            ? '${reqProp.label} • ${reqProp.fullAddress}'
            : reqProp.fullAddress;
      } else if (reqExtractedLoc != null && reqExtractedLoc.isNotEmpty) {
        property = reqExtractedLoc;
      } else if (reqProp?.label.isNotEmpty == true) {
        property = reqProp!.label;
      } else {
        property = widget.job?['property'] as String? ?? 'Primary Location';
      }
      providerName = activeRequest.assignment?.providerName ??
          (quotations.isNotEmpty
              ? (quotations.first.provider?.name ?? 'Assigned Professional')
              : 'Awaiting Assignment');
      rating = activeRequest.assignment != null ? '4.9 ★' : 'New';

      if (activeRequest.assignment != null && quotations.isNotEmpty) {
        final accepted = quotations.firstWhere(
          (q) => q.isAccepted,
          orElse: () => quotations.first,
        );
        price = 'LKR ${accepted.quotedPrice.toStringAsFixed(2)}';
      } else if (quotations.isNotEmpty) {
        final lowest = quotations
            .map((q) => q.quotedPrice)
            .reduce((a, b) => a < b ? a : b);
        price = 'LKR ${lowest.toStringAsFixed(2)}';
      } else {
        price = widget.job?['price'] as String? ?? 'LKR 0.00';
      }

      date = activeRequest.preferredDate != null
          ? DateFormat('EEE, MMM d • hh:mm a')
              .format(activeRequest.preferredDate!)
          : (widget.job?['date'] as String? ?? 'Scheduled Date');

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
      jobId = widget.job?['id'] as String? ?? 'JOB-0000';
      service = widget.job?['service'] as String? ?? 'Service Details';
      descriptionText = '';
      property = widget.job?['property'] as String? ?? 'Primary Location';
      providerName = widget.job?['provider'] as String? ?? 'Awaiting Assignment';
      rating = widget.job?['rating'] as String? ?? 'New';
      price = widget.job?['price'] as String? ?? 'LKR 0.00';
      date = widget.job?['date'] as String? ?? 'Scheduled Date';
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

    final PropertyEntity? resolvedProperty =
        activeAssignment?.jobRequest?.property ?? activeRequest?.property;
    final locMatch = RegExp(r'\(Location:\s*([^)]+)\)', caseSensitive: false)
        .firstMatch(descriptionText);
    final String? resolvedCustomAddress = locMatch?.group(1)?.trim();

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
              onSimulateQuote: _resolvedJobId != null ? _simulateQuote : null,
              onSimulateExtraQuote: activeAssignment != null
                  ? () => _showChangeQuotationDialog(context, activeAssignment.id)
                  : null,
              onSimulateCompleteJob: (activeAssignment != null &&
                      activeAssignment.status != 'completed')
                  ? () => _simulateCompleteJob(context, activeAssignment.id)
                  : null,
              onDispute: (activeAssignment != null &&
                      activeAssignment.hasDispute != true)
                  ? () => _showDisputeModal(
                        context,
                        assignmentId: activeAssignment.id,
                        providerName: providerName,
                      )
                  : null,
            ),

            // Scrollable Content
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primaryDark,
                backgroundColor: Colors.white,
                strokeWidth: 2.8,
                onRefresh: () async {
                  HapticFeedback.mediumImpact();
                  final List<Future<dynamic>> futures = [];
                  if (_resolvedJobId != null) {
                    futures.add(context
                        .read<JobRequestCubit>()
                        .loadJobRequestDetails(_resolvedJobId!));
                    futures.add(context
                        .read<JobRequestCubit>()
                        .loadJobRequestQuotations(_resolvedJobId!));
                  }
                  if (_resolvedAssignmentId != null) {
                    futures.add(context
                        .read<JobAssignmentCubit>()
                        .loadAssignmentDetails(_resolvedAssignmentId!));
                  }
                  if (futures.isNotEmpty) {
                    await Future.wait(futures);
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

                      // Dispute Banner (if active dispute exists)
                      if (activeAssignment?.hasDispute == true) ...[
                        _buildDisputeBanner(),
                        SizedBox(height: 20.h),
                      ],

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

                      // Updated Quotation Decision / Status Card
                      if (activeAssignment != null &&
                          (activeAssignment.hasPendingExtraQuote ||
                              activeAssignment.hasApprovedExtraQuote ||
                              activeAssignment.hasRejectedExtraQuote)) ...[
                        _buildUpdatedQuotationSection(
                          context,
                          activeAssignment,
                          originalPrice: activeAssignment.quotation?.quotedPrice ??
                              (double.tryParse(price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0),
                        ),
                        SizedBox(height: 20.h),
                      ],

                      // Dev Simulation Controls (Change Quotation & Complete Job)
                      if (activeAssignment != null) ...[
                        _buildDevSimulationCard(context, activeAssignment),
                        SizedBox(height: 20.h),
                      ],

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
                      _buildPriceBreakdownSection(
                        price,
                        type,
                        assignment: activeAssignment,
                        job: widget.job ??
                            {
                              'id': jobId,
                              'service': service,
                              'property': property,
                              'provider': providerName,
                              'price': price,
                              'date': date,
                              'status': status,
                              'type': type,
                              'rawId': _resolvedJobId ?? _resolvedAssignmentId,
                            },
                      ),
                      SizedBox(height: 20.h),

                      // Location & Property Details
                      _buildLocationCard(
                        context,
                        property: property,
                        propertyEntity: resolvedProperty,
                        customAddress: resolvedCustomAddress,
                        job: widget.job,
                      ),
                      SizedBox(height: 20.h),

                      // Dispute Section (for assignments when no active dispute yet)
                      if (activeAssignment != null &&
                          activeAssignment.hasDispute != true) ...[
                        _buildDisputeTriggerCard(
                          context,
                          activeAssignment,
                          providerName,
                        ),
                        SizedBox(height: 30.h),
                      ] else ...[
                        SizedBox(height: 10.h),
                      ],
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
                    'rawId': _resolvedJobId ?? _resolvedAssignmentId,
                  },
              canCancel: canCancel,
              onCancel: () => _confirmCancelRequest(context, _resolvedJobId),
              quotations: quotations,
              assignment: activeAssignment,
              resolvedJobId: _resolvedJobId,
              resolvedAssignmentId: _resolvedAssignmentId,
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
    VoidCallback? onDispute,
    VoidCallback? onSimulateQuote,
    VoidCallback? onSimulateExtraQuote,
    VoidCallback? onSimulateCompleteJob,
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
              if ((canCancel && onCancel != null) ||
                  onDispute != null ||
                  onSimulateQuote != null ||
                  onSimulateExtraQuote != null ||
                  onSimulateCompleteJob != null)
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: Colors.white,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  onSelected: (value) {
                    if (value == 'cancel' && onCancel != null) {
                      onCancel();
                    } else if (value == 'dispute' && onDispute != null) {
                      onDispute();
                    } else if (value == 'simulate' && onSimulateQuote != null) {
                      onSimulateQuote();
                    } else if (value == 'simulate_extra' &&
                        onSimulateExtraQuote != null) {
                      onSimulateExtraQuote();
                    } else if (value == 'simulate_complete' &&
                        onSimulateCompleteJob != null) {
                      onSimulateCompleteJob();
                    }
                  },
                  itemBuilder: (context) => [
                    if (onSimulateQuote != null)
                      PopupMenuItem(
                        value: 'simulate',
                        child: Row(
                          children: [
                            Icon(
                              Icons.bolt_rounded,
                              color: const Color(0xFFD97706),
                              size: 18.r,
                            ),
                            SizedBox(width: 10.w),
                            Text(
                              'Simulate Quote (Dev)',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFD97706),
                                fontSize: 13.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (onSimulateExtraQuote != null)
                      PopupMenuItem(
                        value: 'simulate_extra',
                        child: Row(
                          children: [
                            Icon(
                              Icons.auto_fix_high_rounded,
                              color: const Color(0xFFD97706),
                              size: 18.r,
                            ),
                            SizedBox(width: 10.w),
                            Text(
                              'Simulate Change Quote (Dev)',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFD97706),
                                fontSize: 13.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (onSimulateCompleteJob != null)
                      PopupMenuItem(
                        value: 'simulate_complete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.task_alt_rounded,
                              color: const Color(0xFF16A34A),
                              size: 18.r,
                            ),
                            SizedBox(width: 10.w),
                            Text(
                              'Simulate Complete Job (Dev)',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF16A34A),
                                fontSize: 13.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (canCancel && onCancel != null)
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
                    if (onDispute != null)
                      PopupMenuItem(
                        value: 'dispute',
                        child: Row(
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              color: const Color(0xFFDC2626),
                              size: 18.r,
                            ),
                            SizedBox(width: 10.w),
                            Text(
                              'Report Dispute',
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
              Row(
                children: [
                  if (_resolvedJobId != null) ...[
                    InkWell(
                      onTap: _isSimulatingQuote ? null : _simulateQuote,
                      borderRadius: BorderRadius.circular(20.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: const Color(0xFFFCD34D),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bolt_rounded,
                              size: 13.r,
                              color: const Color(0xFFD97706),
                            ),
                            SizedBox(width: 3.w),
                            Text(
                              '+ Simulate',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                  ],
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
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
            ],
          ),
          SizedBox(height: 14.h),
          if (quotations.isEmpty) ...[
            Container(
              padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: const Color(0xFFF0F1EA)),
              ),
              child: Column(
                children: [
                  Row(
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
                  SizedBox(height: 14.h),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isSimulatingQuote ? null : _simulateQuote,
                      icon: _isSimulatingQuote
                          ? SizedBox(
                              width: 14.r,
                              height: 14.r,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFFD97706),
                                ),
                              ),
                            )
                          : Icon(
                              Icons.bolt_rounded,
                              size: 16.r,
                              color: const Color(0xFFD97706),
                            ),
                      label: Text(
                        _isSimulatingQuote
                            ? 'Simulating Quote...'
                            : '⚡ Simulate Quotation (Dev)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFD97706),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFFBEB),
                        side: const BorderSide(
                          color: Color(0xFFFCD34D),
                          width: 1.2,
                        ),
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
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
                    'LKR ${quote.quotedPrice.toStringAsFixed(2)}',
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
                      context.push(
                        AppRoutes.chat,
                        extra: {
                          'providerName': providerName,
                          'serviceTitle': service,
                          'jobId': jobId,
                        },
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

  Widget _buildUpdatedQuotationSection(
    BuildContext context,
    JobAssignmentEntity assignment, {
    required double originalPrice,
  }) {
    if (assignment.hasApprovedExtraQuote) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: const Color(0xFF86EFAC), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF16A34A).withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: const Color(0xFF16A34A),
                size: 20.r,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Updated Quotation Approved',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF15803D),
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          '+ LKR ${(assignment.extraAmount ?? 0.0).toStringAsFixed(2)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF15803D),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    assignment.extraReason?.isNotEmpty == true
                        ? '"${assignment.extraReason!}"'
                        : 'Additional scope accepted and reflected in final billing.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5.sp,
                      color: const Color(0xFF166534),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (assignment.hasRejectedExtraQuote) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: const Color(0xFF64748B),
              size: 20.r,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                'Updated quotation request declined. Provider was instructed to proceed with original scope.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5.sp,
                  color: const Color(0xFF475569),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (!assignment.hasPendingExtraQuote) {
      return const SizedBox.shrink();
    }

    final double extra = assignment.extraAmount ?? 0.0;
    final double safeOriginal =
        originalPrice > 0 ? originalPrice : (assignment.totalEffectivePrice - extra);
    final double newTotal = safeOriginal + extra;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF5),
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: const Color(0xFFF59E0B), width: 1.6),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD97706).withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36.r,
                height: 36.r,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Center(
                  child: Icon(
                    Icons.request_quote_rounded,
                    color: const Color(0xFFB45309),
                    size: 20.r,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Updated Quotation Received',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15.5.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF78350F),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Provider updated quote during the job',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE68A),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: const Color(0xFFF59E0B), width: 0.8),
                ),
                child: Text(
                  'APPROVAL NEEDED',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF78350F),
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),

          // Provider Reason Box
          if (assignment.extraReason?.isNotEmpty == true) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.format_quote_rounded,
                    color: const Color(0xFFD97706),
                    size: 18.r,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      assignment.extraReason!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.sp,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF451A03),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),
          ],

          // Cost Breakdown Card
          Container(
            padding: EdgeInsets.all(14.r),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: const Color(0xFFFCD34D)),
            ),
            child: Column(
              children: [
                if (safeOriginal > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Original Quote',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.sp,
                          color: const Color(0xFF78350F),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'LKR ${safeOriginal.toStringAsFixed(2)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.sp,
                          color: const Color(0xFF78350F),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Additional Scope / Parts',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.sp,
                        color: const Color(0xFFB45309),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '+ LKR ${extra.toStringAsFixed(2)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.sp,
                        color: const Color(0xFFB45309),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                const Divider(height: 1, color: Color(0xFFF59E0B)),
                SizedBox(height: 8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Revised Total',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF451A03),
                      ),
                    ),
                    Text(
                      'LKR ${newTotal.toStringAsFixed(2)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF451A03),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // Action Buttons: Decline & Approve
          Row(
            children: [
              Expanded(
                flex: 4,
                child: SizedBox(
                  height: 44.h,
                  child: OutlinedButton.icon(
                    onPressed: _isProcessingExtraQuote
                        ? null
                        : () => _confirmRejectExtraQuote(context, assignment),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.2),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    icon: Icon(
                      Icons.close_rounded,
                      size: 16.r,
                      color: const Color(0xFFDC2626),
                    ),
                    label: Text(
                      'Decline',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                flex: 6,
                child: SizedBox(
                  height: 44.h,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessingExtraQuote
                        ? null
                        : () => _confirmApproveExtraQuote(context, assignment),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    icon: _isProcessingExtraQuote
                        ? SizedBox(
                            width: 16.r,
                            height: 16.r,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                    label: Text(
                      _isProcessingExtraQuote ? 'Processing...' : 'Approve Quote',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDevSimulationCard(
    BuildContext context,
    JobAssignmentEntity assignment,
  ) {
    final bool isCompleted = assignment.status == 'completed';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFF59E0B), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD97706).withValues(alpha: 0.08),
            blurRadius: 14,
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
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.developer_mode_rounded,
                  size: 16.r,
                  color: const Color(0xFFB45309),
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                'DEV SIMULATION TOOLS',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: const Color(0xFFB45309),
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE68A),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  'DEBUG',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF78350F),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'Simulate provider actions to test real-time customer state changes:',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5.sp,
              color: const Color(0xFF78350F),
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42.h,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessingExtraQuote
                        ? null
                        : () => _showChangeQuotationDialog(context, assignment.id),
                    icon: _isProcessingExtraQuote
                        ? SizedBox(
                            width: 14.r,
                            height: 14.r,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            Icons.price_change_rounded,
                            size: 16.r,
                            color: Colors.white,
                          ),
                    label: Text(
                      'Change Quote',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 10.w),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: SizedBox(
                  height: 42.h,
                  child: ElevatedButton.icon(
                    onPressed: (_isSimulatingCompleteJob || isCompleted)
                        ? null
                        : () => _simulateCompleteJob(context, assignment.id),
                    icon: _isSimulatingCompleteJob
                        ? SizedBox(
                            width: 14.r,
                            height: 14.r,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            isCompleted ? Icons.check_circle_rounded : Icons.task_alt_rounded,
                            size: 16.r,
                            color: Colors.white,
                          ),
                    label: Text(
                      isCompleted ? 'Completed' : 'Complete Job',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCompleted
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 10.w),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBreakdownSection(
    String priceStr,
    String type, {
    JobAssignmentEntity? assignment,
    Map<String, dynamic>? job,
  }) {
    double basePrice = 120.0;
    try {
      final clean = priceStr.replaceAll(RegExp(r'[^0-9.]'), '');
      basePrice = double.tryParse(clean) ?? 120.0;
    } catch (_) {}

    final double extraCharge = (assignment?.hasApprovedExtraQuote == true)
        ? (assignment?.extraAmount ?? 0.0)
        : 0.0;
    final double subtotal = basePrice + extraCharge;
    final double tax = subtotal * 0.08;
    final double total = subtotal + tax;

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
            'LKR ${basePrice.toStringAsFixed(2)}',
          ),
          if (assignment?.hasApprovedExtraQuote == true && extraCharge > 0) ...[
            SizedBox(height: 10.h),
            _buildPriceRow(
              'Approved Extra Quotation',
              '+ LKR ${extraCharge.toStringAsFixed(2)}',
              valueColor: const Color(0xFF16A34A),
            ),
          ],
          SizedBox(height: 10.h),
          _buildPriceRow('Service & Safety Fee', 'LKR 5.00'),
          SizedBox(height: 10.h),
          _buildPriceRow('Estimated Tax (8%)', 'LKR ${tax.toStringAsFixed(2)}'),
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
                'LKR ${(total + 5.00).toStringAsFixed(2)}',
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
                    (type == 'completed' ||
                            assignment?.payment?.isPaid == true)
                        ? 'Paid in full via Card'
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
          if (assignment != null &&
              (assignment.payment == null ||
                  assignment.payment?.isPaid != true)) ...[
            SizedBox(height: 14.h),
            SizedBox(
              width: double.infinity,
              height: 46.h,
              child: ElevatedButton.icon(
                onPressed: () => _showPayJobAssignmentModal(
                  context,
                  job ??
                      {
                        'id': assignment.id,
                        'service': assignment
                                .jobRequest?.serviceCategory?.name ??
                            'Service Assignment',
                        'provider': assignment.providerName ?? 'Provider',
                        'price': priceStr,
                      },
                ),
                icon: Icon(
                  Icons.payment_rounded,
                  size: 16.r,
                  color: Colors.white,
                ),
                label: Text(
                  'Pay for Service Now',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5.sp,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String amount, {Color? valueColor}) {
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
            color: valueColor ?? AppColors.primaryDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard(
    BuildContext context, {
    required String property,
    PropertyEntity? propertyEntity,
    String? customAddress,
    Map<String, dynamic>? job,
  }) {
    final isCustomLocation = (propertyEntity == null &&
            customAddress != null &&
            customAddress.isNotEmpty) ||
        (propertyEntity == null &&
            property.isNotEmpty &&
            property != 'Primary Location' &&
            property != 'Service Location');

    final locationTitle = propertyEntity?.label.trim().isNotEmpty == true
        ? propertyEntity!.label.trim()
        : (isCustomLocation ? 'Current / Pinned Location' : 'Primary Location');

    final fullAddress = propertyEntity?.fullAddress.trim().isNotEmpty == true
        ? propertyEntity!.fullAddress.trim()
        : (customAddress != null && customAddress.isNotEmpty
            ? customAddress
            : (property.isNotEmpty &&
                    property != 'Primary Location' &&
                    property != 'Service Location'
                ? property
                : 'Service location confirmed via GPS pin'));

    final cityText = propertyEntity?.city.isNotEmpty == true
        ? propertyEntity!.city
        : (customAddress != null && customAddress.contains(',')
            ? customAddress.split(',').first.trim()
            : (fullAddress.contains(',')
                ? fullAddress.split(',').first.trim()
                : 'Colombo, Western Province'));

    final streetText = propertyEntity?.addressLine.isNotEmpty == true
        ? propertyEntity!.addressLine
        : (isCustomLocation ? 'GPS Pinned / Real-Time Location' : null);

    final double? latitude = propertyEntity?.latitude;
    final double? longitude = propertyEntity?.longitude;
    final hasCoords = latitude != null && longitude != null;

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
                'Service Address',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15.5.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isCustomLocation
                      ? const Color(0xFFEFF6FF)
                      : const Color(0xFFF3F6E6),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: isCustomLocation
                        ? const Color(0xFFBFDBFE)
                        : const Color(0xFFD6E3B5),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCustomLocation
                          ? Icons.my_location_rounded
                          : Icons.home_work_rounded,
                      size: 12.r,
                      color: isCustomLocation
                          ? const Color(0xFF2563EB)
                          : AppColors.primaryDark,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      isCustomLocation ? 'GPS Location' : 'Saved Property',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: isCustomLocation
                            ? const Color(0xFF2563EB)
                            : AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42.r,
                height: 42.r,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F6E6),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Center(
                  child: Icon(
                    isCustomLocation
                        ? Icons.location_on_rounded
                        : Icons.location_city_rounded,
                    color: AppColors.primaryDark,
                    size: 22.r,
                  ),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locationTitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      fullAddress,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF374151),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: const Color(0xFFF0F1EA)),
            ),
            child: Column(
              children: [
                _buildAddressDetailRow(
                  icon: Icons.map_outlined,
                  label: 'Area / City',
                  value: cityText,
                ),
                if (streetText != null) ...[
                  SizedBox(height: 8.h),
                  _buildAddressDetailRow(
                    icon: Icons.signpost_outlined,
                    label: 'Street / Note',
                    value: streetText,
                  ),
                ],
                if (hasCoords) ...[
                  SizedBox(height: 8.h),
                  _buildAddressDetailRow(
                    icon: Icons.explore_outlined,
                    label: 'Coordinates',
                    value:
                        '${latitude.toStringAsFixed(4)}° N, ${longitude.toStringAsFixed(4)}° E',
                  ),
                ],
                SizedBox(height: 8.h),
                _buildAddressDetailRow(
                  icon: Icons.doorbell_outlined,
                  label: 'Access Note',
                  value: 'Ring Doorbell / Call upon arrival',
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Clipboard.setData(ClipboardData(text: fullAddress));
                    DynamicIslandToast.showSuccess(
                      context,
                      'Address copied to clipboard',
                    );
                  },
                  icon: Icon(Icons.copy_rounded, size: 14.r),
                  label: Text(
                    'Copy Address',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryDark,
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    padding: EdgeInsets.symmetric(vertical: 9.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showLocationMapModal(
                      context,
                      title: locationTitle,
                      address: fullAddress,
                      latitude: latitude,
                      longitude: longitude,
                    );
                  },
                  icon: Icon(Icons.map_rounded, size: 14.r),
                  label: Text(
                    'View on Map',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    padding: EdgeInsets.symmetric(vertical: 9.h),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddressDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14.r, color: AppColors.textMuted),
        SizedBox(width: 8.w),
        Text(
          '$label: ',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showLocationMapModal(
    BuildContext context, {
    required String title,
    required String address,
    double? latitude,
    double? longitude,
  }) async {
    HapticFeedback.lightImpact();
    double targetLat = latitude ?? 6.9271;
    double targetLng = longitude ?? 79.8612;

    if (latitude == null && address.isNotEmpty) {
      try {
        final locs = await Geocoding().locationFromAddress(address);
        if (locs.isNotEmpty) {
          targetLat = locs.first.latitude;
          targetLng = locs.first.longitude;
        }
      } catch (_) {}
    }

    if (!context.mounted) return;

    final targetPos = LatLng(targetLat, targetLng);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: 480.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          children: [
            SizedBox(height: 12.h),
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.sp,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: targetPos,
                      zoom: 15.0,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('service_location'),
                        position: targetPos,
                        infoWindow: InfoWindow(
                          title: title,
                          snippet: address,
                        ),
                      ),
                    },
                    zoomControlsEnabled: true,
                    myLocationButtonEnabled: false,
                  ),
                ),
              ),
            ),
          ],
        ),
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
    List<QuotationEntity> quotations = const [],
    JobAssignmentEntity? assignment,
    int? resolvedJobId,
    int? resolvedAssignmentId,
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
                      _resolvedJobId != null ? 'Cancel' : 'Cancel Request',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                SizedBox(width: 10.w),
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
                    _resolvedJobId != null ? 'Refresh' : 'Refresh Quotes',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
              if (_resolvedJobId != null) ...[
                SizedBox(width: 10.w),
                ElevatedButton(
                  onPressed: _isSimulatingQuote ? null : _simulateQuote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 14.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isSimulatingQuote)
                        SizedBox(
                          width: 14.r,
                          height: 14.r,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      else
                        Icon(
                          Icons.bolt_rounded,
                          size: 16.r,
                          color: Colors.white,
                        ),
                      SizedBox(width: 4.w),
                      Text(
                        'Simulate',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    if (quotations.isEmpty) {
                      DynamicIslandToast.showInfo(
                        context,
                        'Waiting for provider quotations...',
                      );
                      return;
                    }
                    final jobId = resolvedJobId;
                    if (jobId == null) {
                      DynamicIslandToast.showError(
                        context,
                        'Job request ID not found',
                      );
                      return;
                    }
                    if (quotations.length == 1) {
                      _confirmAcceptQuotation(
                        context,
                        quotations.first,
                        jobId,
                      );
                    } else {
                      _showSelectQuotationModal(
                        context,
                        quotations,
                        jobId,
                      );
                    }
                  },
                  icon: Icon(Icons.check_circle_outline_rounded, size: 18.r),
                  label: Text(
                    quotations.length > 1
                        ? 'Approve Quote (${quotations.length})'
                        : 'Approve Quotation',
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
            // Rate Provider Banner Trigger Card (only if not yet reviewed)
            if (assignment?.hasReviewed != true)
              GestureDetector(
                onTap: () => _showRateProviderModal(
                  context,
                  assignmentId:
                      assignment?.id ?? resolvedAssignmentId ?? 0,
                  providerName: providerName,
                  serviceTitle: service,
                ),
                child: Container(
                  margin: EdgeInsets.only(bottom: 12.h),
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 12.h,
                  ),
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
                              'How was $providerName?',
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
                    onPressed: assignment?.hasReviewed == true
                        ? null
                        : () => _showRateProviderModal(
                              context,
                              assignmentId: assignment?.id ??
                                  resolvedAssignmentId ??
                                  0,
                              providerName: providerName,
                              serviceTitle: service,
                            ),
                    icon: Icon(
                      assignment?.hasReviewed == true
                          ? Icons.check_circle_rounded
                          : Icons.star_rounded,
                      size: 16.r,
                      color: assignment?.hasReviewed == true
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFD97706),
                    ),
                    label: Text(
                      assignment?.hasReviewed == true
                          ? 'Reviewed'
                          : 'Rate Pro',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w700,
                        color: assignment?.hasReviewed == true
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF92400E),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: assignment?.hasReviewed == true
                          ? const Color(0xFFF0FDF4)
                          : const Color(0xFFFFFBEB),
                      foregroundColor: assignment?.hasReviewed == true
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF92400E),
                      side: BorderSide(
                        color: assignment?.hasReviewed == true
                            ? const Color(0xFF86EFAC)
                            : const Color(0xFFFFE082),
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
                  context.push(
                    AppRoutes.chat,
                    extra: {
                      'providerName': providerName,
                      'serviceTitle': service,
                      'jobId': jobId,
                    },
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
    final String price = job['price'] as String? ?? 'LKR 242.60';
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
                            _buildReceiptRow('Base Service Rate', 'LKR 220.00'),
                            SizedBox(height: 8.h),
                            _buildReceiptRow('Service & Safety Fee', 'LKR 5.00'),
                            SizedBox(height: 8.h),
                            _buildReceiptRow('Estimated Tax (8%)', 'LKR 17.60'),
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

  void _showRateProviderModal(
    BuildContext context, {
    required int assignmentId,
    required String providerName,
    required String serviceTitle,
  }) {
    HapticFeedback.mediumImpact();
    int currentRating = 5;
    final Set<String> selectedTags = {'On-Time ⏰', 'Clean Work 🧹'};
    final TextEditingController commentCtrl = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetCtx) {
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
                                providerName
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
                                    providerName,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textHeadline,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    serviceTitle,
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
                            onTap: isSubmitting
                                ? null
                                : () {
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
                        children: [
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
                            onSelected: isSubmitting
                                ? null
                                : (val) {
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
                        enabled: !isSubmitting,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13.sp),
                        decoration: InputDecoration(
                          hintText:
                              'Write a public review for $providerName...',
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
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  if (assignmentId <= 0) {
                                    DynamicIslandToast.showError(
                                      context,
                                      'Assignment ID not found for review',
                                    );
                                    return;
                                  }

                                  HapticFeedback.mediumImpact();
                                  setModalState(() {
                                    isSubmitting = true;
                                  });

                                  final comment = commentCtrl.text.trim();
                                  final success = await context
                                      .read<JobAssignmentCubit>()
                                      .submitReview(
                                        assignmentId,
                                        rating: currentRating,
                                        comment: comment.isNotEmpty
                                            ? comment
                                            : null,
                                      );

                                  if (context.mounted &&
                                      bottomSheetCtx.mounted) {
                                    setModalState(() {
                                      isSubmitting = false;
                                    });
                                    if (success) {
                                      Navigator.of(bottomSheetCtx).pop();
                                      DynamicIslandToast.showSuccess(
                                        context,
                                        'Thank you! Review submitted for $providerName ⭐',
                                      );
                                    } else {
                                      final cubitState = context
                                          .read<JobAssignmentCubit>()
                                          .state;
                                      final msg =
                                          cubitState is JobAssignmentError
                                              ? cubitState.message
                                              : 'Failed to submit review';
                                      DynamicIslandToast.showError(
                                        context,
                                        msg,
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryDark,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26.r),
                            ),
                            elevation: 2,
                          ),
                          child: isSubmitting
                              ? SizedBox(
                                  width: 22.r,
                                  height: 22.r,
                                  child: const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.2,
                                  ),
                                )
                              : Text(
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

  void _showDisputeModal(
    BuildContext context, {
    required int assignmentId,
    required String providerName,
  }) {
    HapticFeedback.mediumImpact();
    final TextEditingController reasonCtrl = TextEditingController();
    String? selectedCategory;
    bool isSubmitting = false;

    final categories = [
      'Work Incomplete',
      'Poor Workmanship',
      'Provider No-Show',
      'Overcharged',
      'Unprofessional Conduct',
      'Property Damage',
      'Other',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetCtx) {
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
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8.r),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFEE2E2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.shield_outlined,
                                  color: const Color(0xFFDC2626),
                                  size: 20.r,
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Text(
                                'Report Dispute',
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
                      SizedBox(height: 6.h),
                      Text(
                        'Raise an issue regarding $providerName for investigation and mediation by the HandyGig support team.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5.sp,
                          color: AppColors.textMuted,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // Category chips
                      Text(
                        'Select Issue Category',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textHeadline,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: categories.map((cat) {
                          final isSelected = selectedCategory == cat;
                          return ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            selectedColor: const Color(0xFFFEE2E2),
                            backgroundColor: const Color(0xFFF9FAFB),
                            labelStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 12.sp,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? const Color(0xFFDC2626)
                                  : AppColors.textHeadline,
                            ),
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFFFCA5A5)
                                  : const Color(0xFFE5E7EB),
                            ),
                            onSelected: isSubmitting
                                ? null
                                : (selected) {
                                    HapticFeedback.selectionClick();
                                    setModalState(() {
                                      selectedCategory = selected ? cat : null;
                                      if (selected && reasonCtrl.text.isEmpty) {
                                        reasonCtrl.text = '[$cat]: ';
                                        reasonCtrl.selection =
                                            TextSelection.fromPosition(
                                          TextPosition(
                                            offset: reasonCtrl.text.length,
                                          ),
                                        );
                                      }
                                    });
                                  },
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 18.h),

                      // Detailed Reason
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Reason / Description *',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textHeadline,
                            ),
                          ),
                          Text(
                            '${reasonCtrl.text.length}/2000',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5.sp,
                              color: reasonCtrl.text.length > 2000
                                  ? Colors.red
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      TextField(
                        controller: reasonCtrl,
                        maxLines: 4,
                        maxLength: 2000,
                        enabled: !isSubmitting,
                        buildCounter: (context,
                                {required currentLength,
                                required isFocused,
                                maxLength}) =>
                            null,
                        onChanged: (_) => setModalState(() {}),
                        style: GoogleFonts.plusJakartaSans(fontSize: 13.sp),
                        decoration: InputDecoration(
                          hintText:
                              'Describe in detail what occurred, including dates, missed promises, or damages...',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            color: AppColors.textMuted,
                            fontSize: 13.sp,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFFBFBFB),
                          contentPadding: EdgeInsets.all(14.w),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide:
                                const BorderSide(color: Color(0xFFE2E7D3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: const BorderSide(
                              color: Color(0xFFDC2626),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // Submit Dispute Button
                      SizedBox(
                        width: double.infinity,
                        height: 52.h,
                        child: ElevatedButton.icon(
                          onPressed: (isSubmitting ||
                                  reasonCtrl.text.trim().isEmpty)
                              ? null
                              : () async {
                                  if (assignmentId <= 0) {
                                    DynamicIslandToast.showError(
                                      context,
                                      'Assignment ID not found for dispute',
                                    );
                                    return;
                                  }

                                  final reason = reasonCtrl.text.trim();
                                  if (reason.length < 5) {
                                    DynamicIslandToast.showError(
                                      context,
                                      'Please provide a meaningful reason (at least 5 characters)',
                                    );
                                    return;
                                  }

                                  HapticFeedback.mediumImpact();
                                  setModalState(() {
                                    isSubmitting = true;
                                  });

                                  final success = await context
                                      .read<JobAssignmentCubit>()
                                      .submitDispute(
                                        assignmentId,
                                        reason: reason,
                                      );

                                  if (context.mounted &&
                                      bottomSheetCtx.mounted) {
                                    setModalState(() {
                                      isSubmitting = false;
                                    });
                                    if (success) {
                                      Navigator.of(bottomSheetCtx).pop();
                                      DynamicIslandToast.showSuccess(
                                        context,
                                        'Dispute submitted. HandyGig support has been notified.',
                                      );
                                    } else {
                                      final cubitState = context
                                          .read<JobAssignmentCubit>()
                                          .state;
                                      final msg =
                                          cubitState is JobAssignmentError
                                              ? cubitState.message
                                              : 'Failed to submit dispute';
                                      DynamicIslandToast.showError(
                                        context,
                                        msg,
                                      );
                                    }
                                  }
                                },
                          icon: isSubmitting
                              ? const SizedBox.shrink()
                              : Icon(
                                  Icons.gavel_rounded,
                                  size: 18.r,
                                  color: Colors.white,
                                ),
                          label: isSubmitting
                              ? SizedBox(
                                  width: 22.r,
                                  height: 22.r,
                                  child: const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.2,
                                  ),
                                )
                              : Text(
                                  'Submit Dispute to Support',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26.r),
                            ),
                            elevation: 2,
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

  void _showSelectQuotationModal(
    BuildContext context,
    List<QuotationEntity> quotations,
    int jobId,
  ) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetCtx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
          ),
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Text(
                'Select Quotation to Approve',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textHeadline,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Choose a quotation from providers who applied for this task.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5.sp,
                  color: AppColors.textMuted,
                ),
              ),
              SizedBox(height: 16.h),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: quotations.length,
                  separatorBuilder: (_, _) => SizedBox(height: 12.h),
                  itemBuilder: (context, index) {
                    final quote = quotations[index];
                    return Container(
                      padding: EdgeInsets.all(14.r),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FBF6),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: const Color(0xFFE2E7D3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                quote.provider?.name ??
                                    (quote.provider?.id != null
                                        ? 'Provider #${quote.provider!.id}'
                                        : 'Provider'),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14.5.sp,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              Text(
                                'LKR ${quote.quotedPrice.toStringAsFixed(2)}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF16A34A),
                                ),
                              ),
                            ],
                          ),
                          if (quote.message != null &&
                              quote.message!.isNotEmpty) ...[
                            SizedBox(height: 6.h),
                            Text(
                              quote.message!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.sp,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          SizedBox(height: 10.h),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(bottomSheetCtx).pop();
                                _confirmAcceptQuotation(
                                  context,
                                  quote,
                                  jobId,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryDark,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                              child: Text(
                                'Accept & Assign',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDisputeBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFFCA5A5), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: const BoxDecoration(
              color: Color(0xFFFEE2E2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shield_outlined,
              color: const Color(0xFFDC2626),
              size: 20.r,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dispute Active (Under Investigation)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF991B1B),
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  'A dispute has been submitted for this assignment. HandyGig support is reviewing the issue and mediating with the provider.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFB91C1C),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisputeTriggerCard(
    BuildContext context,
    JobAssignmentEntity assignment,
    String providerName,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFE8ECD8), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.gavel_rounded,
              color: const Color(0xFFDC2626),
              size: 20.r,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need Help with this Task?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textHeadline,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Encountered an issue with quality, payment or conduct?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5.sp,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          TextButton(
            onPressed: () => _showDisputeModal(
              context,
              assignmentId: assignment.id,
              providerName: providerName,
            ),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
              padding: EdgeInsets.symmetric(
                horizontal: 10.w,
                vertical: 6.h,
              ),
            ),
            child: Text(
              'Dispute',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 12.5.sp,
              ),
            ),
          ),
        ],
      ),
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
    final String price = job['price'] as String? ?? 'LKR 0.00';

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
                                  context.push(AppRoutes.paymentMethods);
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
