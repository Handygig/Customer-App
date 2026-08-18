import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/src/presentation/screens/chat/camera_preview_screen.dart';
import 'package:customer_app/src/presentation/widgets/dynamic_island_toast.dart';

enum MessageType { text, image, audio }

class ChatMessage {
  final String id;
  final String text;
  final bool isMe;
  final String timestamp;
  final MessageType type;
  final String? mediaUrl;
  final String? audioDuration;
  bool isPlaying;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isMe,
    required this.timestamp,
    this.type = MessageType.text,
    this.mediaUrl,
    this.audioDuration,
    this.isPlaying = false,
  });
}

class ChatScreen extends StatefulWidget {
  final String providerName;
  final String serviceTitle;
  final String jobId;
  final String? providerAvatar;

  const ChatScreen({
    super.key,
    this.providerName = 'David Miller',
    this.serviceTitle = 'Deep Home Sanitization',
    this.jobId = 'JOB-9842',
    this.providerAvatar,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late List<ChatMessage> _messages;
  bool _isRecordingAudio = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;

  final List<String> _quickReplies = [
    'Where are you now?',
    'Gate code is #4821',
    'Please ring the doorbell',
    'Thank you so much!',
  ];

  @override
  void initState() {
    super.initState();
    _messages = [
      ChatMessage(
        id: '1',
        text:
            'Hello! I am assigned to your booking for ${widget.serviceTitle}.',
        isMe: false,
        timestamp: '02:05 PM',
      ),
      ChatMessage(
        id: '2',
        text: 'Hi David! Here is a photo of the main entrance area:',
        isMe: true,
        timestamp: '02:07 PM',
        type: MessageType.image,
        mediaUrl: 'entrance_photo',
      ),
      ChatMessage(
        id: '3',
        text: 'Voice note from David',
        isMe: false,
        timestamp: '02:08 PM',
        type: MessageType.audio,
        audioDuration: '0:14',
      ),
      ChatMessage(
        id: '4',
        text:
            'Yes, absolutely! I bring eco-friendly sanitization solutions and industrial equipment.',
        isMe: false,
        timestamp: '02:09 PM',
      ),
      ChatMessage(
        id: '5',
        text: 'Great. I have left the front gate unlocked for you.',
        isMe: true,
        timestamp: '02:10 PM',
      ),
      ChatMessage(
        id: '6',
        text:
            'Perfect! I am currently en route and should arrive in about 10 minutes. 🚗',
        isMe: false,
        timestamp: '02:12 PM',
      ),
    ];
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _recordTimer?.cancel();
    super.dispose();
  }

  String _getFormattedTime() {
    final now = TimeOfDay.now();
    final hour = now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  void _sendMessage([String? customText]) {
    final text = customText ?? _messageController.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();

    setState(() {
      _messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: text,
          isMe: true,
          timestamp: _getFormattedTime(),
          type: MessageType.text,
        ),
      );
    });

    if (customText == null) {
      _messageController.clear();
    }

    _scrollToBottom();
  }

  void _sendPhotoMessage(String photoName, [String? caption]) {
    HapticFeedback.mediumImpact();
    setState(() {
      _messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: (caption != null && caption.isNotEmpty)
              ? caption
              : 'Attached Photo: $photoName',
          isMe: true,
          timestamp: _getFormattedTime(),
          type: MessageType.image,
          mediaUrl: photoName,
        ),
      );
    });
    _scrollToBottom();
  }

  void _openCameraLayout() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CameraPreviewScreen(
          onPhotoCaptured: (photoName, caption) {
            _sendPhotoMessage(photoName, caption);
          },
        ),
      ),
    );
  }

  void _sendAudioMessage(int seconds) {
    HapticFeedback.mediumImpact();
    final durationStr = '0:${seconds.toString().padLeft(2, '0')}';
    setState(() {
      _messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: 'Voice Message ($durationStr)',
          isMe: true,
          timestamp: _getFormattedTime(),
          type: MessageType.audio,
          audioDuration: durationStr,
        ),
      );
    });
    _scrollToBottom();
  }

  void _startAudioRecording() {
    HapticFeedback.heavyImpact();
    setState(() {
      _isRecordingAudio = true;
      _recordSeconds = 0;
    });
    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordSeconds++;
      });
    });
  }

  void _stopAndSendAudioRecording() {
    _recordTimer?.cancel();
    final duration = _recordSeconds > 0 ? _recordSeconds : 3;
    setState(() {
      _isRecordingAudio = false;
      _recordSeconds = 0;
    });
    _sendAudioMessage(duration);
  }

  void _cancelAudioRecording() {
    HapticFeedback.lightImpact();
    _recordTimer?.cancel();
    setState(() {
      _isRecordingAudio = false;
      _recordSeconds = 0;
    });
  }

  void _toggleAudioPlayback(ChatMessage msg) {
    HapticFeedback.lightImpact();
    setState(() {
      msg.isPlaying = !msg.isPlaying;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showAttachmentPicker() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 22.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Share Attachment',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      size: 20.r,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAttachmentOption(
                    icon: Icons.camera_alt_rounded,
                    color: const Color(0xFF2563EB),
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _openCameraLayout();
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.photo_library_rounded,
                    color: const Color(0xFF059669),
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _sendPhotoMessage('Selected Photo');
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.mic_rounded,
                    color: const Color(0xFFD97706),
                    label: 'Voice Note',
                    onTap: () {
                      Navigator.pop(context);
                      _startAudioRecording();
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.insert_drive_file_rounded,
                    color: const Color(0xFF7C3AED),
                    label: 'Document',
                    onTap: () {
                      Navigator.pop(context);
                      _sendMessage('Attached Document: Service_Gate_Info.pdf');
                    },
                  ),
                ],
              ),
              SizedBox(height: 14.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 54.r,
            height: 54.r,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(icon, color: color, size: 24.r),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFBFBFB),
        body: Column(
          children: [
            // Custom Header Bar
            _buildChatHeader(context),

            // Messages Container
            Expanded(
              child: ListView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
                children: [
                  // System Date Divider
                  _buildDateDivider('Today, Aug 02'),
                  SizedBox(height: 12.h),

                  // Job Reference Info Banner
                  _buildJobInfoBanner(),
                  SizedBox(height: 16.h),

                  // Chat Message List
                  ..._messages.map((msg) => _buildMessageBubble(msg)),
                ],
              ),
            ),

            // Quick Reply Chips (Hidden when recording audio)
            if (!_isRecordingAudio) _buildQuickRepliesRow(),

            // Bottom Input Bar
            _buildBottomInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildChatHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.primaryDark,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8.h,
        left: 12.w,
        right: 16.w,
        bottom: 16.h,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
            icon: Container(
              width: 36.r,
              height: 36.r,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 17.r,
                ),
              ),
            ),
          ),
          SizedBox(width: 4.w),

          // Provider Avatar with Online Indicator
          Stack(
            children: [
              CircleAvatar(
                radius: 22.r,
                backgroundColor: const Color(0xFFBAC095),
                child: Text(
                  widget.providerName
                      .split(' ')
                      .map((e) => e[0])
                      .take(2)
                      .join(''),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 13.r,
                  height: 13.r,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryDark, width: 2),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: 12.w),

          // Name and Status Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.providerName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.5.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '${widget.serviceTitle} • Active Now',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5.sp,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Call Icon
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              DynamicIslandToast.showSuccess(
                context,
                'Calling ${widget.providerName}...',
              );
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
                  Icons.call_rounded,
                  color: Colors.white,
                  size: 19.r,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateDivider(String dateLabel) {
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF2E4),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Text(
          dateLabel,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildJobInfoBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6E6),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFE2E6D5)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18.r,
            color: AppColors.primaryDark,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'Job Ref: ${widget.jobId} • Service messages are recorded for quality assurance.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final bool isMe = msg.isMe;

    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14.r,
              backgroundColor: AppColors.primaryDark,
              child: Text(
                widget.providerName[0],
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(width: 8.w),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.all(
                msg.type == MessageType.image ? 6.r : 14.r,
              ),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primaryDark : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18.r),
                  topRight: Radius.circular(18.r),
                  bottomLeft: Radius.circular(isMe ? 18.r : 4.r),
                  bottomRight: Radius.circular(isMe ? 4.r : 18.r),
                ),
                border: isMe
                    ? null
                    : Border.all(color: const Color(0xFFE8ECD8), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryDark.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (msg.type == MessageType.image)
                    _buildImageBubbleContent(msg)
                  else if (msg.type == MessageType.audio)
                    _buildAudioBubbleContent(msg)
                  else
                    Text(
                      msg.text,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: isMe ? Colors.white : AppColors.primaryDark,
                        height: 1.35,
                      ),
                    ),
                  SizedBox(height: 4.h),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: msg.type == MessageType.image ? 8.w : 0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          msg.timestamp,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5.sp,
                            color: isMe
                                ? Colors.white.withValues(alpha: 0.75)
                                : AppColors.textMuted,
                          ),
                        ),
                        if (isMe) ...[
                          SizedBox(width: 4.w),
                          Icon(
                            Icons.done_all_rounded,
                            size: 14.r,
                            color: AppColors.accentLime,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageBubbleContent(ChatMessage msg) {
    return Column(
      crossAxisAlignment: msg.isMe
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14.r),
          child: Container(
            width: 210.w,
            height: 140.h,
            color: msg.isMe ? const Color(0xFF505727) : const Color(0xFFF3F6E6),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_rounded,
                        size: 42.r,
                        color: msg.isMe
                            ? AppColors.accentLime
                            : AppColors.primaryDark,
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        msg.mediaUrl ?? 'Photo Attachment',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: msg.isMe
                              ? Colors.white
                              : AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 8.r,
                  right: 8.r,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 3.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.crop_original_rounded,
                          size: 12.r,
                          color: Colors.white,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'PHOTO',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (msg.text.isNotEmpty && !msg.text.startsWith('Attached Photo')) ...[
          SizedBox(height: 6.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Text(
              msg.text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5.sp,
                color: msg.isMe ? Colors.white : AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAudioBubbleContent(ChatMessage msg) {
    final bool isMe = msg.isMe;

    return Container(
      width: 200.w,
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _toggleAudioPlayback(msg),
            child: Container(
              width: 36.r,
              height: 36.r,
              decoration: BoxDecoration(
                color: isMe ? AppColors.accentLime : AppColors.primaryDark,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  msg.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: isMe ? AppColors.primaryDark : Colors.white,
                  size: 22.r,
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(14, (index) {
                    final heights = [
                      10.h,
                      16.h,
                      24.h,
                      14.h,
                      20.h,
                      28.h,
                      18.h,
                      12.h,
                      22.h,
                      16.h,
                      26.h,
                      14.h,
                      20.h,
                      12.h,
                    ];
                    final isPlayed = index < (msg.isPlaying ? 8 : 4);
                    return Container(
                      width: 3.w,
                      height: heights[index % heights.length],
                      decoration: BoxDecoration(
                        color: isMe
                            ? (isPlayed
                                  ? AppColors.accentLime
                                  : Colors.white.withValues(alpha: 0.4))
                            : (isPlayed
                                  ? AppColors.primaryDark
                                  : const Color(0xFFC7D0A8)),
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    );
                  }),
                ),
                SizedBox(height: 6.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      msg.audioDuration ?? '0:14',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: isMe
                            ? Colors.white.withValues(alpha: 0.9)
                            : AppColors.primaryDark,
                      ),
                    ),
                    Icon(
                      Icons.graphic_eq_rounded,
                      size: 14.r,
                      color: isMe ? AppColors.accentLime : AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickRepliesRow() {
    return Container(
      height: 40.h,
      margin: EdgeInsets.only(bottom: 8.h),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: _quickReplies.length,
        separatorBuilder: (context, index) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          final reply = _quickReplies[index];
          return GestureDetector(
            onTap: () => _sendMessage(reply),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: const Color(0xFFC7D0A8), width: 1.2),
              ),
              child: Center(
                child: Text(
                  reply,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomInputBar() {
    if (_isRecordingAudio) {
      return _buildAudioRecordingInputBar();
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
        16.w,
        10.h,
        16.w,
        MediaQuery.of(context).padding.bottom + 10.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Attachment Button (+)
          IconButton(
            onPressed: _showAttachmentPicker,
            icon: Icon(
              Icons.add_circle_outline_rounded,
              color: AppColors.primaryDark,
              size: 26.r,
            ),
          ),

          // Photo Quick Access Button
          IconButton(
            onPressed: _openCameraLayout,
            icon: Icon(
              Icons.camera_alt_outlined,
              color: AppColors.primaryDark,
              size: 23.r,
            ),
          ),

          // Message Input Field
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7EF),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(color: const Color(0xFFE2E6D5)),
              ),
              child: TextField(
                controller: _messageController,
                onSubmitted: (_) => _sendMessage(),
                onChanged: (_) => setState(() {}),
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.sp,
                  color: AppColors.primaryDark,
                ),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    color: AppColors.textMuted,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),

          // Mic or Send Button
          if (_messageController.text.trim().isEmpty)
            GestureDetector(
              onTap: _startAudioRecording,
              child: Container(
                width: 44.r,
                height: 44.r,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3F6E6),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.mic_rounded,
                    color: AppColors.primaryDark,
                    size: 22.r,
                  ),
                ),
              ),
            )
          else
            GestureDetector(
              onTap: () => _sendMessage(),
              child: Container(
                width: 44.r,
                height: 44.r,
                decoration: const BoxDecoration(
                  color: AppColors.primaryDark,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 18.r,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAudioRecordingInputBar() {
    final minutes = (_recordSeconds ~/ 60).toString().padLeft(1, '0');
    final secs = (_recordSeconds % 60).toString().padLeft(2, '0');

    return Container(
      padding: EdgeInsets.fromLTRB(
        16.w,
        10.h,
        16.w,
        MediaQuery.of(context).padding.bottom + 10.h,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _cancelAudioRecording,
            icon: Icon(
              Icons.delete_outline_rounded,
              color: const Color(0xFFDC2626),
              size: 24.r,
            ),
          ),
          SizedBox(width: 6.w),
          Container(
            width: 10.r,
            height: 10.r,
            decoration: const BoxDecoration(
              color: Color(0xFFDC2626),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            'Recording Audio... $minutes:$secs',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFDC2626),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _stopAndSendAudioRecording,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.send_rounded, color: Colors.white, size: 16.r),
                  SizedBox(width: 6.w),
                  Text(
                    'Send Note',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
