import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_endpoints.dart';

class CustomMapMarkerHelper {
  CustomMapMarkerHelper._();

  static final Map<String, BitmapDescriptor> _markerCache = {};
  static final Map<String, ui.Image> _imageCache = {};

  static void clearCache() {
    _markerCache.clear();
    _imageCache.clear();
  }

  /// Resolve full image URL (handles relative backend paths)
  static String resolveUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return '';
    final trimmed = rawUrl.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final root = AppEndpoints.baseUrl.replaceAll('/api', '');
    if (trimmed.startsWith('/')) {
      return '$root$trimmed';
    }
    return '$root/$trimmed';
  }

  /// Downloads and decodes a network image into a ui.Image
  static Future<ui.Image?> loadNetworkUiImage(String rawUrl) async {
    final url = resolveUrl(rawUrl);
    if (url.isEmpty) return null;

    if (_imageCache.containsKey(url)) {
      return _imageCache[url];
    }

    try {
      final imageStream = NetworkImage(url).resolve(ImageConfiguration.empty);
      final completer = Completer<ui.Image?>();
      late ImageStreamListener listener;
      listener = ImageStreamListener(
        (ImageInfo info, bool synchronousCall) {
          _imageCache[url] = info.image;
          completer.complete(info.image);
          imageStream.removeListener(listener);
        },
        onError: (exception, stackTrace) {
          imageStream.removeListener(listener);
          completer.complete(null);
        },
      );
      imageStream.addListener(listener);
      return await completer.future.timeout(
        const Duration(seconds: 4),
        onTimeout: () => null,
      );
    } catch (_) {
      return null;
    }
  }

  /// Formats rate / price into clean badge pill text (e.g. "LKR 85", "LKR 65")
  static String formatPriceBadge(String price, double hourlyRate) {
    final upper = price.toUpperCase().trim();
    if (upper.contains('LKR')) {
      return upper.replaceAll('/HR', '').replaceAll('/H', '').trim();
    }
    if (price.contains('\$')) {
      final numStr = price.replaceAll('\$', '').replaceAll('/hr', '').trim();
      final parsed = double.tryParse(numStr);
      if (parsed != null && parsed > 0) {
        return 'LKR ${(parsed * 2.0).toInt()}';
      }
    }
    if (hourlyRate > 0) {
      return 'LKR ${hourlyRate.toInt()}';
    }
    return price.isNotEmpty ? price : 'LKR 50';
  }

  /// Generates a custom teardrop map pin with circular avatar and price pill
  static Future<BitmapDescriptor> getProviderMarker({
    required String id,
    required String name,
    required String price,
    required double hourlyRate,
    required bool isAvailable,
    required bool isSelected,
    String? profileImageUrl,
    VoidCallback? onImageLoaded,
  }) async {
    final badgeText = formatPriceBadge(price, hourlyRate);
    final cacheKey =
        'provider_${id}_${badgeText}_${isAvailable}_${isSelected}_${profileImageUrl ?? ""}';

    if (_markerCache.containsKey(cacheKey)) {
      return _markerCache[cacheKey]!;
    }

    final fullUrl = resolveUrl(profileImageUrl);
    ui.Image? uiImage = fullUrl.isNotEmpty ? _imageCache[fullUrl] : null;

    // If image not loaded yet, initiate background load
    if (uiImage == null && fullUrl.isNotEmpty) {
      unawaited(
        loadNetworkUiImage(fullUrl).then((img) {
          if (img != null) {
            _markerCache.remove(cacheKey);
            onImageLoaded?.call();
          }
        }),
      );
    }

    final descriptor = await _renderMarkerBitmap(
      title: badgeText,
      name: name,
      image: uiImage,
      isCustomer: false,
      isSelected: isSelected,
      isAvailable: isAvailable,
    );

    _markerCache[cacheKey] = descriptor;
    return descriptor;
  }

  /// Generates the custom customer pin (center search location / user location)
  static Future<BitmapDescriptor> getCustomerMarker({
    required String title,
    required String name,
    String? profileImageUrl,
    bool isSelected = false,
    VoidCallback? onImageLoaded,
  }) async {
    final cacheKey = 'customer_blue_v2_${title}_${profileImageUrl ?? ""}';

    if (_markerCache.containsKey(cacheKey)) {
      return _markerCache[cacheKey]!;
    }

    final fullUrl = resolveUrl(profileImageUrl);
    ui.Image? uiImage = fullUrl.isNotEmpty ? _imageCache[fullUrl] : null;

    if (uiImage == null && fullUrl.isNotEmpty) {
      unawaited(
        loadNetworkUiImage(fullUrl).then((img) {
          if (img != null) {
            _markerCache.remove(cacheKey);
            onImageLoaded?.call();
          }
        }),
      );
    }

    final descriptor = await _renderMarkerBitmap(
      title: title,
      name: name.isNotEmpty ? name : 'You',
      image: uiImage,
      isCustomer: true,
      isSelected: isSelected,
      isAvailable: true,
    );

    _markerCache[cacheKey] = descriptor;
    return descriptor;
  }

  /// Core canvas painter that produces the pixel-perfect teardrop pin
  static Future<BitmapDescriptor> _renderMarkerBitmap({
    required String title,
    required String name,
    required ui.Image? image,
    required bool isCustomer,
    required bool isSelected,
    required bool isAvailable,
  }) async {
    const double logicalWidth = 110.0;
    const double logicalHeight = 120.0;
    const double scale = 2.5; // High-DPI sharpness

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(scale, scale);

    const double cx = logicalWidth / 2; // 55.0
    const double tipY = 106.0;
    const double cy = 58.0;
    const double bulbRadius = 26.0;

    // 1. Ground Shadow below pointer tip
    final shadowPaint = Paint()
      ..shader = ui.Gradient.radial(
        const Offset(cx, tipY + 4),
        16.0,
        [
          Colors.black.withValues(alpha: 0.32),
          Colors.black.withValues(alpha: 0.12),
          Colors.transparent,
        ],
        [0.0, 0.55, 1.0],
      );
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(cx, tipY + 4),
        width: 30.0,
        height: 8.5,
      ),
      shadowPaint,
    );

    // 2. Price / Title Pill at the top
    if (title.isNotEmpty) {
      // Pill text style
      final textPainter = TextPainter(
        text: TextSpan(
          text: title,
          style: TextStyle(
            color: isCustomer
                ? const Color(0xFF1E40AF) // Deep Royal Blue for customer
                : const Color(0xFF262A17), // Dark olive for provider
            fontSize: 11.0,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final pillWidth = math.max(48.0, textPainter.width + 16.0);
      const pillHeight = 22.0;
      final pillRect = Rect.fromCenter(
        center: const Offset(cx, 14.0),
        width: pillWidth,
        height: pillHeight,
      );
      final pillRRect = RRect.fromRectAndRadius(
        pillRect,
        const Radius.circular(11.0),
      );

      // Pill shadow
      canvas.drawRRect(
        pillRRect.shift(const Offset(0, 1.5)),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.14)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
      );

      // Pill fill
      final pillBgColor = isCustomer
          ? const Color(0xFFEFF6FF) // Crisp ice-blue for customer
          : Colors.white; // Crisp white for providers
      canvas.drawRRect(pillRRect, Paint()..color = pillBgColor);

      // Pill border
      canvas.drawRRect(
        pillRRect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = isCustomer
              ? const Color(0xFF93C5FD) // Sky blue border
              : const Color(0xFFE2E6D5),
      );

      // Pill text
      textPainter.paint(
        canvas,
        Offset(
          cx - textPainter.width / 2,
          14.0 - textPainter.height / 2,
        ),
      );
    }

    // 3. Teardrop Pin Shape (Bulb + Downward Pointer)
    final pinPath = Path();

    // Tangent angle calculation from tip (cx, tipY) to circle at (cx, cy)
    const double dy = tipY - cy; // 48.0
    final double theta = math.asin(bulbRadius / dy); // ~32.8 deg (0.57 rad)
    final double rightAngle = theta;
    final double leftAngle = math.pi - theta;

    final double leftX = cx + bulbRadius * math.cos(leftAngle);
    final double leftY = cy + bulbRadius * math.sin(leftAngle);

    // Arc around top from leftAngle around top clockwise to rightAngle
    final sweepAngle = (2 * math.pi) - (leftAngle - rightAngle);
    pinPath.addArc(
      Rect.fromCircle(center: const Offset(cx, cy), radius: bulbRadius),
      leftAngle,
      sweepAngle,
    );

    // Line from right tangent down to tip
    pinPath.lineTo(cx + 2.0, tipY - 2.5);
    pinPath.quadraticBezierTo(cx, tipY, cx - 2.0, tipY - 2.5);
    pinPath.lineTo(leftX, leftY);
    pinPath.close();

    // Draw pin drop shadow
    canvas.drawPath(
      pinPath.shift(const Offset(0, 2)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0),
    );

    // Pin Body Color
    final pinColor = isCustomer
        ? const Color(0xFF2563EB) // Vibrant Electric Blue for customer
        : const Color(0xFF3D4127); // Deep dark olive for provider

    canvas.drawPath(
      pinPath,
      Paint()
        ..color = pinColor
        ..style = PaintingStyle.fill,
    );

    // Selected Halo Outline
    if (isSelected) {
      canvas.drawPath(
        pinPath,
        Paint()
          ..color = isCustomer ? const Color(0xFF60A5FA) : AppColors.accentLime
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0,
      );
    }

    // 4. Inner White Frame Ring for the photo
    const double photoRadius = 21.0;
    const double frameRadius = 23.5;
    canvas.drawCircle(
      const Offset(cx, cy),
      frameRadius,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    // 5. Circular Clipped Photo Avatar
    final avatarCenter = const Offset(cx, cy);
    final clipPath = Path()
      ..addOval(Rect.fromCircle(center: avatarCenter, radius: photoRadius));

    canvas.save();
    canvas.clipPath(clipPath);

    if (image != null) {
      final srcW = image.width.toDouble();
      final srcH = image.height.toDouble();
      final side = math.min(srcW, srcH);
      final srcRect = Rect.fromCenter(
        center: Offset(srcW / 2, srcH / 2),
        width: side,
        height: side,
      );
      final dstRect = Rect.fromCircle(center: avatarCenter, radius: photoRadius);
      canvas.drawImageRect(
        image,
        srcRect,
        dstRect,
        Paint()..filterQuality = FilterQuality.high,
      );
    } else {
      // Fallback: Elegant colored circle with Initials or Person Silhouette
      canvas.drawCircle(
        avatarCenter,
        photoRadius,
        Paint()
          ..color = isCustomer
              ? const Color(0xFF3B82F6) // Vibrant Blue fallback avatar
              : const Color(0xFF555C33), // Olive fallback avatar
      );

      final initials = _getInitials(name);
      if (initials.isNotEmpty) {
        final initialsPainter = TextPainter(
          text: TextSpan(
            text: initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.0,
              fontWeight: FontWeight.w800,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        initialsPainter.paint(
          canvas,
          Offset(
            cx - initialsPainter.width / 2,
            cy - initialsPainter.height / 2,
          ),
        );
      } else {
        // Fallback user icon
        final iconPaint = Paint()..color = Colors.white;
        canvas.drawCircle(const Offset(cx, cy - 4), 6.5, iconPaint);
        canvas.drawArc(
          Rect.fromCenter(center: const Offset(cx, cy + 12), width: 22, height: 18),
          math.pi,
          math.pi,
          true,
          iconPaint,
        );
      }
    }
    canvas.restore();

    // 6. Status Badge Dot on bottom-right of avatar
    final badgeCenter = Offset(cx + 15.0, cy + 15.0);
    // Outer white rim
    canvas.drawCircle(
      badgeCenter,
      5.5,
      Paint()..color = Colors.white,
    );
    // Inner badge color (Cyan for customer, Green for available, Blue for verified)
    final badgeColor = isCustomer
        ? const Color(0xFF38BDF8) // Bright Cyan dot for customer
        : (isAvailable
            ? const Color(0xFF10B981) // Vibrant green for available provider
            : const Color(0xFF0284C7)); // Blue dot for verified provider
    canvas.drawCircle(
      badgeCenter,
      4.0,
      Paint()..color = badgeColor,
    );

    // 7. Produce high-res PNG bytes
    final picture = recorder.endRecording();
    final img = await picture.toImage(
      (logicalWidth * scale).toInt(),
      (logicalHeight * scale).toInt(),
    );
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    // Width & height parameters ensure Google Maps scales the high-DPI image correctly
    return BitmapDescriptor.bytes(
      bytes,
      width: logicalWidth,
      height: logicalHeight,
    );
  }

  static String _getInitials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return '';
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      final first = parts[0].isNotEmpty ? parts[0][0] : '';
      final second = parts[1].isNotEmpty ? parts[1][0] : '';
      return (first + second).toUpperCase();
    }
    return clean.substring(0, math.min(2, clean.length)).toUpperCase();
  }

  /// Marker anchor point matching tip (cx, tipY) exactly
  static const Offset pinAnchor = Offset(0.5, 106.0 / 120.0);
}
