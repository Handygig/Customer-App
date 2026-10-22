import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/utils/extensions.dart';
import 'package:customer_app/src/presentation/screens/auth/add_properties_screen.dart';
import 'package:customer_app/src/presentation/tabs/home_tab.dart';
import 'package:customer_app/src/presentation/tabs/jobs_tab.dart';
import 'package:customer_app/src/presentation/tabs/search_tab.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:customer_app/src/presentation/cubits/notifications/notification_cubit.dart';
import 'package:customer_app/src/presentation/cubits/notifications/notification_state.dart';
import 'package:customer_app/src/presentation/tabs/alerts_tab.dart';
import 'package:customer_app/src/presentation/tabs/profile_tab.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      HapticFeedback.mediumImpact();
      setState(() {
        _currentIndex = index;
      });
    }
  }

  void _openAddProperties() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddPropertiesScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            // Active Tab View
            IndexedStack(
              index: _currentIndex,
              children: [
                HomeTab(
                  onAddPropertyTap: _openAddProperties,
                  onNavigateTab: _onTabSelected,
                ),
                const JobsTab(),
                SearchTab(onBackTap: () => _onTabSelected(0)),
                AlertsTab(onNavigateTab: _onTabSelected),
                ProfileTab(onAddPropertyTap: _openAddProperties),
              ],
            ),

            // Floating Light Mode Custom Curvature Bottom Navigation Bar (Hidden on Search Tab)
            if (_currentIndex != 2)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildCustomBottomNavigationBar(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomBottomNavigationBar() {
    final double barHeight = 68.h;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        bottom: bottomPadding > 0 ? bottomPadding - 6 : 10.h,
      ),
      child: SizedBox(
        height: barHeight + 32.h,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            // 1. Curved White Background with Smooth Scoop/Dip & Elevation Shadow
            CustomPaint(
              size: Size(double.infinity, barHeight),
              painter: CurvatureNotchedNavBarPainterLight(),
              child: SizedBox(
                height: barHeight,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left Items: Home, Jobs
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildNavItem(
                              index: 0,
                              label: context.loc.tabHome,
                              icon: Icons.home_rounded,
                            ),
                            _buildNavItem(
                              index: 1,
                              label: context.loc.tabJobs,
                              icon: Icons.grid_view_rounded,
                            ),
                          ],
                        ),
                      ),

                      // Gap for Center FAB
                      SizedBox(width: 80.w),

                      // Right Items: Alerts, Profile
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildNavItem(
                              index: 3,
                              label: context.loc.tabAlerts,
                              icon: Icons.notifications_rounded,
                            ),
                            _buildNavItem(
                              index: 4,
                              label: context.loc.tabProfile,
                              icon: Icons.person_rounded,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 2. Central Raised Floating Action Button (Light Mode)
            Positioned(
              top: 0,
              child: GestureDetector(
                onTap: () => _onTabSelected(2),
                child: Container(
                  width: 62.r,
                  height: 62.r,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE8ECE1),
                      width: 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 12,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(6.r),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.search_rounded,
                        color: Colors.white,
                        size: 26.r,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final bool isSelected = _currentIndex == index;
    final Color activeColor = AppColors.primary;
    final Color inactiveColor = const Color(0xFF9CA09A);

    return GestureDetector(
      onTap: () => _onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56.w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: Icon(
                    icon,
                    size: 23.r,
                    color: isSelected ? activeColor : inactiveColor,
                  ),
                ),
                if (index == 3)
                  BlocBuilder<NotificationCubit, NotificationState>(
                    builder: (context, notifState) {
                      final count = notifState is NotificationLoaded
                          ? notifState.unreadCount
                          : 0;
                      if (count == 0) return const SizedBox.shrink();
                      return Positioned(
                        top: -3.h,
                        right: -6.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4.w,
                            vertical: 1.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD32F2F),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: Colors.white,
                              width: 1.5,
                            ),
                          ),
                          constraints: BoxConstraints(
                            minWidth: 16.r,
                            minHeight: 16.r,
                          ),
                          child: Center(
                            child: Text(
                              count > 9 ? '9+' : '$count',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8.5.sp,
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
            SizedBox(height: 3.h),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.sp,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
            // Active indicator dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              margin: EdgeInsets.only(top: 3.h),
              width: isSelected ? 4.r : 0,
              height: isSelected ? 4.r : 0,
              decoration: BoxDecoration(
                color: activeColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// LIGHT MODE CURVED NOTCHED NAVBAR PAINTER
// ---------------------------------------------------------------------------
class CurvatureNotchedNavBarPainterLight extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final Paint borderPaint = Paint()
      ..color = const Color(0xFFE8ECE1).withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.06)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);

    final double w = size.width;
    final double h = size.height;
    final double cornerRadius = 28.r;

    final double centerX = w / 2;
    final double notchWidth = 80.w;
    final double notchDepth = 26.h;

    final Path path = Path();

    // Start at top-left corner after radius
    path.moveTo(cornerRadius, 0);

    // Top horizontal line leading to the left edge of the notch
    path.lineTo(centerX - (notchWidth / 2) - 14.w, 0);

    // Smooth entry curve into the scoop (Notch)
    path.cubicTo(
      centerX - (notchWidth / 2) + 4.w,
      0,
      centerX - (notchWidth / 2) + 8.w,
      notchDepth,
      centerX - (notchWidth / 4),
      notchDepth,
    );

    // Bottom arc of the scoop
    path.cubicTo(
      centerX - 8.w,
      notchDepth + 5.h,
      centerX + 8.w,
      notchDepth + 5.h,
      centerX + (notchWidth / 4),
      notchDepth,
    );

    // Smooth exit curve out of the scoop
    path.cubicTo(
      centerX + (notchWidth / 2) - 8.w,
      notchDepth,
      centerX + (notchWidth / 2) - 4.w,
      0,
      centerX + (notchWidth / 2) + 14.w,
      0,
    );

    // Top horizontal line to top-right corner
    path.lineTo(w - cornerRadius, 0);

    // Top-right rounded corner
    path.quadraticBezierTo(w, 0, w, cornerRadius);

    // Right vertical line down to bottom-right corner
    path.lineTo(w, h - cornerRadius);

    // Bottom-right rounded corner
    path.quadraticBezierTo(w, h, w - cornerRadius, h);

    // Bottom horizontal line to bottom-left corner
    path.lineTo(cornerRadius, h);

    // Bottom-left rounded corner
    path.quadraticBezierTo(0, h, 0, h - cornerRadius);

    // Left vertical line up to top-left corner
    path.lineTo(0, cornerRadius);

    // Top-left rounded corner
    path.quadraticBezierTo(0, 0, cornerRadius, 0);

    path.close();

    // Draw Drop Shadow (softer, more diffuse)
    canvas.drawPath(path.shift(Offset(0, 4.h)), shadowPaint);

    // Draw Main Nav Bar Path
    canvas.drawPath(path, paint);

    // Draw Outline Border
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
