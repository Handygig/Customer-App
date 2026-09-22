import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:customer_app/core/constants/app_colors.dart';

class AuthAnimatedSheet extends StatefulWidget {
  final double top;
  final Widget child;
  final bool showGrabber;

  const AuthAnimatedSheet({
    super.key,
    required this.top,
    required this.child,
    this.showGrabber = true,
  });

  @override
  State<AuthAnimatedSheet> createState() => _AuthAnimatedSheetState();
}

class _AuthAnimatedSheetState extends State<AuthAnimatedSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _sheetSlide;
  late final Animation<double> _sheetFade;
  late final Animation<Offset> _contentSlide;
  late final Animation<double> _contentFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _sheetSlide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0, 0.85, curve: Curves.easeOutCubic),
          ),
        );

    _sheetFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.60, curve: Curves.easeOut),
      ),
    );

    _contentSlide =
        Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.20, 1, curve: Curves.easeOutCubic),
          ),
        );

    _contentFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.20, 0.85, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.top,
      left: 0,
      right: 0,
      bottom: 0,
      child: SlideTransition(
        position: _sheetSlide,
        child: FadeTransition(
          opacity: _sheetFade,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.sheetBackground,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(36.r),
                topRight: Radius.circular(36.r),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 24,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SlideTransition(
                position: _contentSlide,
                child: FadeTransition(
                  opacity: _contentFade,
                  child: widget.showGrabber
                      ? Column(
                          children: [
                            Center(
                              child: Container(
                                margin: EdgeInsets.only(top: 12.h, bottom: 6.h),
                                width: 38.w,
                                height: 4.h,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE2E4DE),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                              ),
                            ),
                            Expanded(child: widget.child),
                          ],
                        )
                      : widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
