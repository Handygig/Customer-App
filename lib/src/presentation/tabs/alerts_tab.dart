import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/src/domain/entities/notifications/notification_entity.dart';
import 'package:customer_app/src/presentation/cubits/notifications/notification_cubit.dart';
import 'package:customer_app/src/presentation/cubits/notifications/notification_state.dart';
import 'package:customer_app/src/presentation/screens/profile/rewards_referral_screen.dart';
import 'package:customer_app/src/presentation/screens/profile/properties_management_screen.dart';

class AlertsTab extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;

  const AlertsTab({super.key, this.onNavigateTab});

  @override
  State<AlertsTab> createState() => _AlertsTabState();
}

class _AlertsTabState extends State<AlertsTab> {
  final List<Map<String, String>> _filters = const [
    {'key': 'all', 'label': 'All'},
    {'key': 'unread', 'label': 'Unread'},
    {'key': 'job', 'label': 'Jobs'},
    {'key': 'offer', 'label': 'Offers'},
    {'key': 'reward', 'label': 'Rewards'},
    {'key': 'system', 'label': 'Updates'},
  ];

  @override
  void initState() {
    super.initState();
    context.read<NotificationCubit>().loadNotifications(showLoading: false);
  }

  void _handleNotificationTap(NotificationEntity notif) {
    HapticFeedback.lightImpact();

    // Mark as read immediately
    if (!notif.isRead) {
      context.read<NotificationCubit>().markAsRead(notif.id);
    }

    // Contextual routing based on type
    switch (notif.type) {
      case 'offer':
      case 'promo':
        widget.onNavigateTab?.call(0); // Go to Home (offers carousel)
        break;
      case 'job':
      case 'booking':
        widget.onNavigateTab?.call(1); // Go to Jobs tab
        break;
      case 'reward':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RewardsReferralScreen()),
        );
        break;
      case 'account':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PropertiesManagementScreen()),
        );
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor(context),
      body: Column(
        children: [
          // 1. Top Header
          _buildHeader(context, topInset),

          // 2. Filter Chips Row
          _buildFilterChips(context),

          // 3. Notification List
          Expanded(
            child: BlocBuilder<NotificationCubit, NotificationState>(
              builder: (context, state) {
                if (state is NotificationLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (state is NotificationError) {
                  return _buildErrorState(context, state.message);
                }

                if (state is NotificationLoaded) {
                  final notifications = state.notifications;

                  if (notifications.isEmpty) {
                    return _buildEmptyState(context, state.activeFilter);
                  }

                  return RefreshIndicator(
                    color: AppColors.primary,
                    backgroundColor: AppColors.surfaceColor(context),
                    onRefresh: () async {
                      await context
                          .read<NotificationCubit>()
                          .loadNotifications(showLoading: false);
                    },
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 120.h),
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      itemCount: notifications.length,
                      separatorBuilder: (context, index) => SizedBox(height: 10.h),
                      itemBuilder: (context, index) {
                        final notif = notifications[index];
                        return _buildNotificationCard(context, notif);
                      },
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top Header
  // ---------------------------------------------------------------------------
  Widget _buildHeader(BuildContext context, double topInset) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceColor(context),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.r),
          bottomRight: Radius.circular(24.r),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.isDark(context)
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20.w, topInset + 12.h, 20.w, 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4.w,
                    height: 20.h,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'Alerts & Notifications',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.headlineColor(context),
                    ),
                  ),
                ],
              ),
              BlocBuilder<NotificationCubit, NotificationState>(
                builder: (context, state) {
                  final unreadCount = state is NotificationLoaded
                      ? state.unreadCount
                      : 0;

                  if (unreadCount == 0) return const SizedBox.shrink();

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.read<NotificationCubit>().markAllAsRead();
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 5.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.done_all_rounded,
                            size: 14.r,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Mark all read',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Padding(
            padding: EdgeInsets.only(left: 14.w),
            child: Text(
              'Stay updated on your ongoing bookings and offers',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.mutedTextColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Filter Chips Row
  // ---------------------------------------------------------------------------
  Widget _buildFilterChips(BuildContext context) {
    return BlocBuilder<NotificationCubit, NotificationState>(
      builder: (context, state) {
        final activeFilter =
            state is NotificationLoaded ? state.activeFilter : 'all';
        final unreadCount =
            state is NotificationLoaded ? state.unreadCount : 0;

        return Container(
          height: 44.h,
          margin: EdgeInsets.only(top: 10.h, bottom: 4.h),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            physics: const BouncingScrollPhysics(),
            itemCount: _filters.length,
            itemBuilder: (context, index) {
              final filter = _filters[index];
              final isSelected = activeFilter == filter['key'];
              final isUnreadChip = filter['key'] == 'unread';

              return Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.read<NotificationCubit>().setFilter(filter['key']!);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.surfaceColor(context),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.borderColor(context),
                        width: 1.2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          filter['label']!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.sp,
                            fontWeight:
                                isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : AppColors.headlineColor(context),
                          ),
                        ),
                        if (isUnreadChip && unreadCount > 0) ...[
                          SizedBox(width: 6.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 1.h,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.primary,
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Text(
                              '$unreadCount',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Notification Card Item
  // ---------------------------------------------------------------------------
  Widget _buildNotificationCard(BuildContext context, NotificationEntity notif) {
    final bool isUnread = !notif.isRead;
    final isDark = AppColors.isDark(context);

    return Dismissible(
      key: ValueKey(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        decoration: BoxDecoration(
          color: const Color(0xFFD32F2F),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 24.r,
        ),
      ),
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        context.read<NotificationCubit>().deleteNotification(notif.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notification removed'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        );
      },
      child: GestureDetector(
        onTap: () => _handleNotificationTap(notif),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: isUnread
                ? (isDark
                    ? const Color(0xFF262A1F)
                    : const Color(0xFFF9FAF3))
                : AppColors.surfaceColor(context),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isUnread
                  ? AppColors.primary.withValues(alpha: 0.6)
                  : AppColors.borderColor(context),
              width: isUnread ? 1.5 : 1,
            ),
            boxShadow: [
              if (isUnread)
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                )
              else
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          padding: EdgeInsets.all(14.r),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Badge
              Container(
                width: 42.r,
                height: 42.r,
                decoration: BoxDecoration(
                  color: notif.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Center(
                  child: Icon(
                    notif.icon,
                    color: notif.color,
                    size: 20.r,
                  ),
                ),
              ),
              SizedBox(width: 12.w),

              // Notification Title, Body, and Timestamp
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.sp,
                              fontWeight: isUnread
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: AppColors.headlineColor(context),
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          notif.timeAgo,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.sp,
                            fontWeight: isUnread
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isUnread
                                ? AppColors.primary
                                : AppColors.mutedTextColor(context),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      notif.message,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                        color: isUnread
                            ? AppColors.headlineColor(context).withValues(alpha: 0.85)
                            : AppColors.mutedTextColor(context),
                      ),
                    ),
                  ],
                ),
              ),

              // Unread dot indicator
              if (isUnread) ...[
                SizedBox(width: 8.w),
                Container(
                  width: 8.r,
                  height: 8.r,
                  margin: EdgeInsets.only(top: 4.h),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Empty State
  // ---------------------------------------------------------------------------
  Widget _buildEmptyState(BuildContext context, String activeFilter) {
    final String label = activeFilter == 'unread'
        ? 'No unread notifications'
        : 'No notifications found';

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72.r,
              height: 72.r,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 36.r,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.headlineColor(context),
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'You are all caught up! When updates or offers arrive, you will see them here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5.sp,
                color: AppColors.mutedTextColor(context),
                height: 1.4,
              ),
            ),
            SizedBox(height: 20.h),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                context.read<NotificationCubit>().setFilter('all');
                context
                    .read<NotificationCubit>()
                    .loadNotifications(showLoading: true);
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 20.w,
                  vertical: 10.h,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  'Refresh Feed',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Error State
  // ---------------------------------------------------------------------------
  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48.r,
              color: Colors.redAccent,
            ),
            SizedBox(height: 12.h),
            Text(
              'Failed to load notifications',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.headlineColor(context),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.sp,
                color: AppColors.mutedTextColor(context),
              ),
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () {
                context.read<NotificationCubit>().loadNotifications();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              child: const Text('Try Again', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
