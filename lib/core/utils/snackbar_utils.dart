import 'package:customer_app/config/router/app_router.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class SnackBarUtils {
  static void showSuccess(BuildContext? context, String message) {
    _show(
      context,
      message,
      AppColors.successColor,
      Icons.check_circle_outline,
      false,
    );
  }

  static void showError(BuildContext? context, String message) {
    _show(context, message, AppColors.errorColor, Icons.error_outline, true);
  }

  static void showinfo(BuildContext? context, String message) {
    _show(context, message, AppColors.infoColor, Icons.info_outline, true);
  }

  static void _show(
    BuildContext? context,
    String message,
    Color backgroundColor,
    IconData icon,
    bool isError,
  ) {
    final effectiveContext =
        context ?? AppRouter.rootNavigatorKey.currentContext;
    if (effectiveContext == null) return;

    final overlay =
        Overlay.maybeOf(effectiveContext) ??
        AppRouter.rootNavigatorKey.currentState?.overlay;
    if (overlay == null) return;
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _TopNotification(
        message: message,
        backgroundColor: backgroundColor,
        icon: icon,
        onDismiss: () {
          if (entry.mounted) entry.remove();
        },
      ),
    );

    overlay.insert(entry);

    Future.delayed(Duration(seconds: isError ? 8 : 5), () {
      if (entry.mounted) entry.remove();
    });
  }
}

class _TopNotification extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final IconData icon;
  final VoidCallback onDismiss;

  const _TopNotification({
    required this.message,
    required this.backgroundColor,
    required this.icon,
    required this.onDismiss,
  });

  @override
  State<_TopNotification> createState() => _TopNotificationState();
}

class _TopNotificationState extends State<_TopNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 12,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: widget.backgroundColor.withOpacity(0.93),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(widget.icon, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _dismiss,
                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
