import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/di/service_locator.dart';
import 'package:customer_app/src/domain/entities/faq/faq_item.dart';
import 'package:customer_app/src/domain/repositories/faq/faq_repository.dart';
import 'package:customer_app/src/data/repositories/faq/faq_repository_impl.dart';
import 'package:customer_app/src/presentation/widgets/dynamic_island_toast.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  late final FaqRepository _faqRepository;

  List<FaqItem> _faqs = FaqItem.defaultFaqs;
  List<String> _categories = ['All'];
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _faqRepository = sl.isRegistered<FaqRepository>()
        ? sl<FaqRepository>()
        : FaqRepositoryImpl();
    _extractCategories(_faqs);
    _loadFaqs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _extractCategories(List<FaqItem> items) {
    final unique = <String>{'All'};
    for (final item in items) {
      if (item.category.trim().isNotEmpty) {
        unique.add(item.category.trim());
      }
    }
    setState(() {
      _categories = unique.toList();
    });
  }

  Future<void> _loadFaqs({bool isRefresh = false}) async {
    if (!isRefresh && _faqs.isEmpty) {
      setState(() => _isLoading = true);
    }
    setState(() => _errorMessage = null);

    final result = await _faqRepository.getFaqs();

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          if (_faqs.isEmpty) {
            _errorMessage = 'Unable to load latest FAQs. Showing offline copy.';
            _faqs = FaqItem.defaultFaqs;
            _extractCategories(_faqs);
          }
        });
      },
      (fetchedFaqs) {
        setState(() {
          _isLoading = false;
          if (fetchedFaqs.isNotEmpty) {
            _faqs = fetchedFaqs;
            _extractCategories(fetchedFaqs);
          }
        });
      },
    );
  }

  List<FaqItem> get _filteredFaqs {
    return _faqs.where((faq) {
      if (!faq.isActive) return false;

      // Category filter
      if (_selectedCategory != 'All' &&
          faq.category.toLowerCase() != _selectedCategory.toLowerCase()) {
        return false;
      }

      // Search query filter
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.trim().toLowerCase();
        final matchQ = faq.question.toLowerCase().contains(query);
        final matchA = faq.answer.toLowerCase().contains(query);
        final matchC = faq.category.toLowerCase().contains(query);
        return matchQ || matchA || matchC;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final displayedFaqs = _filteredFaqs;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.darkHeaderBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Help & 24/7 Support',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: AppColors.primaryDark,
        onRefresh: () => _loadFaqs(isRefresh: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emergency Repair Banner
              Container(
                padding: EdgeInsets.all(18.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.r),
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: const BoxDecoration(
                        color: AppColors.accentLime,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.headset_mic_rounded,
                        color: AppColors.primaryDark,
                        size: 24.r,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '24/7 Emergency Dispatch',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Water leak or power outage? Call our priority line.',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFFC7CBC0),
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        DynamicIslandToast.showSuccess(
                          context,
                          'Calling Emergency Dispatch Line: +1 (800) 123-4567',
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentLime,
                        foregroundColor: AppColors.primaryDark,
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 8.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Call Now',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),

              // Live Chat Tile
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18.r),
                  border: Border.all(color: AppColors.borderUnselected),
                ),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18.r),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      DynamicIslandToast.showSuccess(
                        context,
                        'Connecting to live chat agent...',
                      );
                    },
                    leading: Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: AppColors.cardSelectedBg,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: AppColors.primary,
                        size: 22.r,
                      ),
                    ),
                    title: Text(
                      'Start Live Support Chat',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textHeadline,
                      ),
                    ),
                    subtitle: Text(
                      'Average response time: 2 mins',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.sp,
                        color: AppColors.textMuted,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14.r,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 28.h),

              // FAQ Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Frequently Asked Questions',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.5.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textHeadline,
                    ),
                  ),
                  if (_isLoading)
                    SizedBox(
                      height: 16.r,
                      width: 16.r,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    )
                  else
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: AppColors.cardSelectedBg,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        '${displayedFaqs.length} ${displayedFaqs.length == 1 ? 'item' : 'items'}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 12.h),

              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: AppColors.borderUnselected),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                      _expandedIndex = null;
                    });
                  },
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5.sp,
                    color: AppColors.textHeadline,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search questions or keywords...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 13.sp,
                      color: AppColors.textMuted,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: AppColors.textMuted,
                      size: 20.r,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              size: 18.r,
                              color: AppColors.textMuted,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _expandedIndex = null;
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 12.h,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.h),

              // Category Filter Pills
              if (_categories.length > 1) ...[
                SizedBox(
                  height: 34.h,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, _) => SizedBox(width: 8.w),
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = _selectedCategory == cat;

                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedCategory = cat;
                            _expandedIndex = null;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.borderUnselected,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              cat,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.sp,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 16.h),
              ],

              // Error notification banner if any
              if (_errorMessage != null) ...[
                Container(
                  padding: EdgeInsets.all(12.w),
                  margin: EdgeInsets.only(bottom: 12.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Colors.red.shade700,
                        size: 18.r,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.red.shade800,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _loadFaqs(isRefresh: true),
                        child: Text(
                          'Retry',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.red.shade900,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // FAQ Items or Empty State
              if (displayedFaqs.isEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 36.h, horizontal: 20.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18.r),
                    border: Border.all(color: AppColors.borderUnselected),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(14.r),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.search_off_rounded,
                          color: AppColors.textMuted,
                          size: 32.r,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'No matching questions found',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textHeadline,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Try searching for another keyword or change category filter.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.sp,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                ...List.generate(displayedFaqs.length, (index) {
                  final item = displayedFaqs[index];
                  final isExpanded = _expandedIndex == index;

                  return Container(
                    margin: EdgeInsets.only(bottom: 12.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: isExpanded
                            ? AppColors.primary
                            : AppColors.borderUnselected,
                        width: isExpanded ? 1.4 : 1.0,
                      ),
                      boxShadow: isExpanded
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.06),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                      ),
                      child: ExpansionTile(
                        key: ValueKey('faq_${item.id}_${item.question}'),
                        initiallyExpanded: isExpanded,
                        tilePadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 4.h,
                        ),
                        childrenPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                        iconColor: AppColors.primary,
                        collapsedIconColor: AppColors.textMuted,
                        onExpansionChanged: (expanded) {
                          HapticFeedback.selectionClick();
                          setState(() => _expandedIndex = expanded ? index : null);
                        },
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (item.category.isNotEmpty &&
                                item.category != 'General') ...[
                              Container(
                                margin: EdgeInsets.only(bottom: 4.h),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6.w,
                                  vertical: 2.h,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.cardSelectedBg,
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Text(
                                  item.category,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                            Text(
                              item.question,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textHeadline,
                              ),
                            ),
                          ],
                        ),
                        children: [
                          Text(
                            item.answer,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.sp,
                              height: 1.45,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
