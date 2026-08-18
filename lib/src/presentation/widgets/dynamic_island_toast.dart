import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:customer_app/core/constants/app_colors.dart';

class DynamicIslandToast {
  static void showSuccess(BuildContext context, String message) {
    _showToast(context, message, false);
  }

  static void showError(BuildContext context, String message) {
    _showToast(context, message, true);
  }

  static void _showToast(BuildContext context, String message, bool isError) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    HapticFeedback.mediumImpact();

    overlayEntry = OverlayEntry(
      builder: (context) => _DynamicIslandToastWidget(
        message: message,
        isError: isError,
        onDismiss: () {
          overlayEntry.remove();
        },
      ),
    );

    overlay.insert(overlayEntry);
  }
}

class _DynamicIslandToastWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  const _DynamicIslandToastWidget({
    Key? key,
    required this.message,
    this.isError = false,
    required this.onDismiss,
  }) : super(key: key);

  @override
  State<_DynamicIslandToastWidget> createState() =>
      _DynamicIslandToastWidgetState();
}

class _DynamicIslandToastWidgetState extends State<_DynamicIslandToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _widthAnimation;
  late Animation<double> _heightAnimation;
  late Animation<double> _iconScaleAnimation;
  late Animation<double> _tickAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<Offset> _textSlideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // 1. Initial pop scaling of the whole island
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );

    // 2. Width expansion (elastic stretch)
    _widthAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.7, curve: Curves.elasticOut),
      ),
    );

    // 3. Height expansion (pushing down)
    _heightAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.6, curve: Curves.easeOutBack),
      ),
    );

    // 4. Elastic pop for the circle icon background
    _iconScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.7, curve: Curves.elasticOut),
      ),
    );

    // 5. Drawing the tick / cross mark smoothly
    _tickAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 0.9, curve: Curves.easeOutQuart),
      ),
    );

    // 6. Text fading in and sliding slightly from the right
    _textOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
      ),
    );
    _textSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic),
          ),
        );

    _controller.forward();

    // Auto dismiss after 3 seconds
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        _controller.reverse(from: 1.0).then((_) {
          widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 12, // Approximate top padding of iOS dynamic island
      left: 0,
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: Align(
          alignment: Alignment.topCenter,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              // Base dynamic island width is ~120, height ~36
              final width = 120.0 + (230.0 * _widthAnimation.value);
              final height =
                  36.0 + (96.0 * _heightAnimation.value); // ~132px total height

              final Color glowColor = widget.isError
                  ? Colors.redAccent
                  : AppColors.accentLime;

              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: width,
                  height: height,
                  padding: EdgeInsets.only(
                    left: 20.w,
                    right: 20.w,
                    top:
                        32.h *
                        _heightAnimation
                            .value, // Push content down below physical notch
                    bottom: 10.h * _heightAnimation.value,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(
                      18.r + (24.r * _heightAnimation.value),
                    ), // 18r to 42r
                    border: Border.all(
                      color: Colors.white.withValues(
                        alpha: 0.08 * _widthAnimation.value,
                      ),
                      width: 0.5,
                    ),
                    boxShadow: [
                      // Status glow that appears as the island expands
                      BoxShadow(
                        color: glowColor.withValues(
                          alpha: 0.15 * _widthAnimation.value,
                        ),
                        blurRadius: 30,
                        spreadRadius: 4,
                        offset: const Offset(0, 10),
                      ),
                      // Core drop shadow
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Align(
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated Message Text
                        if (_textOpacityAnimation.value > 0)
                          SlideTransition(
                            position: _textSlideAnimation,
                            child: Opacity(
                              opacity: _textOpacityAnimation.value,
                              child: Text(
                                widget.message,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ),

                        if (_textOpacityAnimation.value > 0 &&
                            _iconScaleAnimation.value > 0)
                          SizedBox(height: 10.h),

                        // Animated Icon Circle (Extra Large)
                        if (_iconScaleAnimation.value > 0)
                          Transform.scale(
                            scale: _iconScaleAnimation.value,
                            child: Container(
                              width: 44.r, // Extra large
                              height: 44.r,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: widget.isError
                                      ? [Colors.redAccent, Colors.red.shade800]
                                      : [
                                          AppColors.accentLime,
                                          const Color(0xFF8F994B),
                                        ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: glowColor.withValues(
                                      alpha: 0.4 * _iconScaleAnimation.value,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: CustomPaint(
                                painter: _AnimatedIconPainter(
                                  progress: _tickAnimation.value,
                                  isError: widget.isError,
                                  color: widget.isError
                                      ? Colors.white
                                      : AppColors.primaryDark,
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
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CUSTOM PAINTER FOR ANIMATED TICK / CROSS
// ---------------------------------------------------------------------------
class _AnimatedIconPainter extends CustomPainter {
  final double progress;
  final bool isError;
  final Color color;

  _AnimatedIconPainter({
    required this.progress,
    required this.isError,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Path path = Path();

    if (isError) {
      // Draw X
      // Line 1: top-left to bottom-right
      path.moveTo(size.width * 0.3, size.height * 0.3);
      path.lineTo(size.width * 0.7, size.height * 0.7);
      // Line 2: top-right to bottom-left
      path.moveTo(size.width * 0.7, size.height * 0.3);
      path.lineTo(size.width * 0.3, size.height * 0.7);
    } else {
      // Draw Tick
      path.moveTo(size.width * 0.28, size.height * 0.52);
      path.lineTo(size.width * 0.45, size.height * 0.68);
      path.lineTo(size.width * 0.75, size.height * 0.35);
    }

    // Animate drawing the path strokes based on progress
    ui.PathMetrics pathMetrics = path.computeMetrics();
    for (ui.PathMetric pathMetric in pathMetrics) {
      // Extract segment from 0 to current progress length
      Path extractedPath = pathMetric.extractPath(
        0.0,
        pathMetric.length * progress,
      );
      canvas.drawPath(extractedPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AnimatedIconPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isError != isError;
  }
}
