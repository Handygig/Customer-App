import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer_app/core/constants/app_colors.dart';

class CameraPreviewScreen extends StatefulWidget {
  final Function(String photoName, String caption) onPhotoCaptured;

  const CameraPreviewScreen({super.key, required this.onPhotoCaptured});

  @override
  State<CameraPreviewScreen> createState() => _CameraPreviewScreenState();
}

class _CameraPreviewScreenState extends State<CameraPreviewScreen> {
  bool _isCaptured = false;
  bool _isFlashOn = false;
  bool _isFrontCamera = false;
  final TextEditingController _captionController = TextEditingController();

  final List<String> _samplePhotos = [
    'Service Area Inspection Photo',
    'Equipment & Parts Photo',
    'Property Entrance Photo',
    'Sanitization Progress Photo',
  ];

  late String _capturedPhotoLabel;

  @override
  void initState() {
    super.initState();
    _capturedPhotoLabel = _samplePhotos[0];
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  void _takeInstantPhoto() {
    HapticFeedback.heavyImpact();
    final randomIndex =
        DateTime.now().millisecondsSinceEpoch % _samplePhotos.length;
    setState(() {
      _capturedPhotoLabel = _samplePhotos[randomIndex];
      _isCaptured = true;
    });
  }

  void _retakePhoto() {
    HapticFeedback.lightImpact();
    setState(() {
      _isCaptured = false;
      _captionController.clear();
    });
  }

  void _sendPhoto() {
    HapticFeedback.mediumImpact();
    final caption = _captionController.text.trim();
    widget.onPhotoCaptured(_capturedPhotoLabel, caption);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Camera Viewfinder / Photo Preview Background
            Positioned.fill(
              child: _isCaptured
                  ? _buildCapturedPhotoPreview()
                  : _buildLiveCameraViewfinder(),
            ),

            // Top Action Controls Bar
            Positioned(
              top: MediaQuery.of(context).padding.top + 8.h,
              left: 16.w,
              right: 16.w,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pop();
                    },
                    icon: Container(
                      width: 40.r,
                      height: 40.r,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 22.r,
                      ),
                    ),
                  ),

                  if (!_isCaptured) ...[
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              _isFlashOn = !_isFlashOn;
                            });
                          },
                          icon: Container(
                            width: 40.r,
                            height: 40.r,
                            decoration: BoxDecoration(
                              color: _isFlashOn
                                  ? AppColors.accentLime
                                  : Colors.black.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isFlashOn
                                  ? Icons.flash_on_rounded
                                  : Icons.flash_off_rounded,
                              color: _isFlashOn
                                  ? AppColors.primaryDark
                                  : Colors.white,
                              size: 20.r,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        IconButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              _isFrontCamera = !_isFrontCamera;
                            });
                          },
                          icon: Container(
                            width: 40.r,
                            height: 40.r,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.flip_camera_ios_rounded,
                              color: Colors.white,
                              size: 20.r,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        IconButton(
                          onPressed: _retakePhoto,
                          icon: Container(
                            width: 40.r,
                            height: 40.r,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.replay_rounded,
                              color: Colors.white,
                              size: 22.r,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        IconButton(
                          onPressed: () {},
                          icon: Container(
                            width: 40.r,
                            height: 40.r,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.crop_rotate_rounded,
                              color: Colors.white,
                              size: 20.r,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Bottom Shutter Controls OR WhatsApp Caption Input Bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _isCaptured
                  ? _buildWhatsAppCaptionBar()
                  : _buildCameraShutterBar(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveCameraViewfinder() {
    return Container(
      color: const Color(0xFF181A1B),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Grid & Focus Target Mock
          Container(
            margin: EdgeInsets.all(40.r),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1.5,
              ),
            ),
          ),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90.r,
                height: 90.r,
                decoration: BoxDecoration(
                  color: AppColors.primaryDark.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.accentLime, width: 2),
                ),
                child: Center(
                  child: Icon(
                    Icons.camera_rounded,
                    size: 44.r,
                    color: AppColors.accentLime,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'LIVE CAMERA VIEWFINDER',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: 0.7),
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'Tap shutter button below to snap instant photo',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCapturedPhotoPreview() {
    return Container(
      color: const Color(0xFF2D3219),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120.r,
                height: 120.r,
                decoration: BoxDecoration(
                  color: AppColors.accentLime.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.accentLime, width: 3),
                ),
                child: Center(
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 64.r,
                    color: AppColors.accentLime,
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  _capturedPhotoLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Ready to send like WhatsApp',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5.sp,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCameraShutterBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24.w,
        20.h,
        24.w,
        MediaQuery.of(context).padding.bottom + 24.h,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withValues(alpha: 0.9), Colors.transparent],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _takeInstantPhoto,
            child: Container(
              width: 76.r,
              height: 76.r,
              padding: EdgeInsets.all(4.r),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatsAppCaptionBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16.w,
        14.h,
        16.w,
        MediaQuery.of(context).padding.bottom + 14.h,
      ),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.85)),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: const Color(0xFF262B16),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(color: const Color(0xFF4D5528)),
              ),
              child: TextField(
                controller: _captionController,
                onSubmitted: (_) => _sendPhoto(),
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5.sp,
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  hintText: 'Add a caption...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    color: Colors.white54,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          GestureDetector(
            onTap: _sendPhoto,
            child: Container(
              width: 48.r,
              height: 48.r,
              decoration: const BoxDecoration(
                color: AppColors.accentLime,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.send_rounded,
                  color: AppColors.primaryDark,
                  size: 22.r,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
