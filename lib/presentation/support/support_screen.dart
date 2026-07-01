import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:kudipay/core/utils/responsive.dart';

import 'package:kudipay/presentation/ticket/features/tickets/presentation/screens/tickets_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data models
// ─────────────────────────────────────────────────────────────────────────────

class _Category {
  final String title;
  final String svgAsset; // path in assets/icons/
  final int articleCount;
  const _Category({
    required this.title,
    required this.svgAsset,
    this.articleCount = 12,
  });
}

class _Article {
  final String title;
  final String readTime;
  const _Article({required this.title, required this.readTime});
}

class _HelpVideo {
  final String title;
  final String duration;
  const _HelpVideo({required this.title, required this.duration});
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _searchController = TextEditingController();

  // ── Static data ────────────────────────────────────────────────────────────
  static const _categories = [
    _Category(title: 'Get started', svgAsset: 'assets/icons/rocket.svg'),
    _Category(title: 'Payment', svgAsset: 'assets/icons/cashout.svg'),
    _Category(title: 'Security', svgAsset: 'assets/icons/shield.svg'),
    _Category(title: 'Account', svgAsset: 'assets/icons/person.svg'),
    _Category(title: 'Troubleshooting', svgAsset: 'assets/icons/fix.svg'),
    _Category(title: 'Refund', svgAsset: 'assets/icons/clock.svg'),
  ];

  static const _articles = [
    _Article(
      title: 'How to request for a refund for transaction',
      readTime: '3 mins read',
    ),
    _Article(
      title: 'Why was my payment declined',
      readTime: '3 mins read',
    ),
    _Article(
      title: 'How do i update my BVN on Kudikit',
      readTime: '3 mins read',
    ),
  ];

  static const _videos = [
    _HelpVideo(title: 'Making first payment', duration: '1:20'),
    _HelpVideo(title: 'Resolving failed transfers', duration: '1:20'),
    _HelpVideo(title: 'Making first payment', duration: '1:20'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundScreen,
      appBar: _buildAppBar(context),
      // Sticky bottom button lives outside the scroll area
      bottomNavigationBar: _buildContactButton(context),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: AppLayout.scaleWidth(context, 16),
          right: AppLayout.scaleWidth(context, 16),
          top: AppLayout.scaleHeight(context, 16),
          bottom: AppLayout.scaleHeight(context, 24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            _buildSearchBar(context),
            SizedBox(height: AppLayout.scaleHeight(context, 20)),

            // Category 2×3 grid
            _buildCategoryGrid(context),
            SizedBox(height: AppLayout.scaleHeight(context, 28)),

            // Popular help articles
            _sectionLabel(context, 'Popular help articles'),
            SizedBox(height: AppLayout.scaleHeight(context, 12)),
            _buildArticlesList(context),
            SizedBox(height: AppLayout.scaleHeight(context, 28)),

            // Help videos
            _sectionLabel(context, 'Help Videos'),
            SizedBox(height: AppLayout.scaleHeight(context, 12)),
            _buildVideoRow(context),
            SizedBox(height: AppLayout.scaleHeight(context, 40)),
          ],
        ),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.backgroundScreen,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios,
          color: AppColors.textDark,
          size: AppLayout.scaleWidth(context, 18),
        ),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Text(
        'Support',
        style: TextStyle(
          fontFamily: 'PolySans',
          color: AppColors.textDark,
          fontSize: AppLayout.fontSize(context, 18),
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: true,
      actions: [
        TextButton(
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => TicketsScreen()));
          },
          // onPressed: () => _showReportSheet(context),
          child: Text(
            'Tickets',
            style: TextStyle(
              color: AppColors.primaryTeal,
              fontSize: AppLayout.fontSize(context, 14),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ── Search bar ─────────────────────────────────────────────────────────────
  Widget _buildSearchBar(BuildContext context) {
    return Container(
      height: AppLayout.scaleHeight(context, 48),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          fontSize: AppLayout.fontSize(context, 14),
          color: AppColors.textDark,
        ),
        decoration: InputDecoration(
          hintText: 'Search for what you want...',
          hintStyle: TextStyle(
            fontSize: AppLayout.fontSize(context, 14),
            color: AppColors.textGrey,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.textGrey,
            size: AppLayout.scaleWidth(context, 20),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            vertical: AppLayout.scaleHeight(context, 13),
          ),
        ),
      ),
    );
  }

  // ── Category grid ──────────────────────────────────────────────────────────
  Widget _buildCategoryGrid(BuildContext context) {
    // 2-column grid — we build it manually for full responsive control
    final List<Widget> rows = [];
    for (int i = 0; i < _categories.length; i += 2) {
      final left = _categories[i];
      final right = i + 1 < _categories.length ? _categories[i + 1] : null;
      rows.add(
        Row(
          children: [
            Expanded(child: _buildCategoryCard(context, left)),
            SizedBox(width: AppLayout.scaleWidth(context, 12)),
            Expanded(
              child: right != null
                  ? _buildCategoryCard(context, right)
                  : const SizedBox(),
            ),
          ],
        ),
      );
      if (i + 2 < _categories.length) {
        rows.add(SizedBox(height: AppLayout.scaleHeight(context, 12)));
      }
    }
    return Column(children: rows);
  }

  Widget _buildCategoryCard(BuildContext context, _Category cat) {
    final iconBoxSize = AppLayout.scaleWidth(context, 40);
    final iconSize = AppLayout.scaleWidth(context, 20);

    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius:
              BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon box
            Container(
              width: iconBoxSize,
              height: iconBoxSize,
              decoration: BoxDecoration(
                color: AppColors.checkGreen,
                borderRadius:
                    BorderRadius.circular(AppLayout.scaleWidth(context, 10)),
              ),
              child: Center(
                child: SvgPicture.asset(
                  cat.svgAsset,
                  width: iconSize,
                  height: iconSize,
                  colorFilter: const ColorFilter.mode(
                    AppColors.primaryTeal,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 12)),

            Text(
              cat.title,
              style: TextStyle(
                fontFamily: 'PolySans',
                fontSize: AppLayout.fontSize(context, 15),
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 3)),
            Text(
              '${cat.articleCount} Articles',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 12),
                color: AppColors.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Popular articles ───────────────────────────────────────────────────────
  Widget _buildArticlesList(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        children: List.generate(_articles.length, (i) {
          final isLast = i == _articles.length - 1;
          return Column(
            children: [
              _buildArticleRow(context, _articles[i],
                  isFirst: i == 0, isLast: isLast),
              if (!isLast)
                Divider(
                  height: 1,
                  color: const Color(0xFFF0F0F0),
                  indent: AppLayout.scaleWidth(context, 16),
                  endIndent: AppLayout.scaleWidth(context, 16),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildArticleRow(
    BuildContext context,
    _Article article, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.vertical(
        top: isFirst
            ? Radius.circular(AppLayout.scaleWidth(context, 12))
            : Radius.zero,
        bottom: isLast
            ? Radius.circular(AppLayout.scaleWidth(context, 12))
            : Radius.zero,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppLayout.scaleWidth(context, 16),
          vertical: AppLayout.scaleHeight(context, 14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 14),
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 3)),
                  Text(
                    article.readTime,
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 12),
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: AppLayout.scaleWidth(context, 14),
              color: AppColors.textLight,
            ),
          ],
        ),
      ),
    );
  }

  // ── Help videos ────────────────────────────────────────────────────────────
  Widget _buildVideoRow(BuildContext context) {
    final cardWidth = AppLayout.scaleWidth(context, 130);
    final thumbHeight = AppLayout.scaleHeight(context, 90);
    final playIconSize = AppLayout.scaleWidth(context, 28);

    return SizedBox(
      height: AppLayout.scaleHeight(context, 150),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _videos.length,
        separatorBuilder: (_, __) =>
            SizedBox(width: AppLayout.scaleWidth(context, 12)),
        itemBuilder: (context, i) {
          final video = _videos[i];
          return GestureDetector(
            onTap: () {},
            child: Container(
              width: cardWidth,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius:
                    BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thumbnail placeholder with play button
                  Container(
                    width: double.infinity,
                    height: thumbHeight,
                    decoration: BoxDecoration(
                      color: AppColors.checkGreen,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(AppLayout.scaleWidth(context, 12)),
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: playIconSize,
                        height: playIconSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primaryTeal,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: AppColors.primaryTeal,
                          size: AppLayout.scaleWidth(context, 18),
                        ),
                      ),
                    ),
                  ),
                  // Title + duration
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppLayout.scaleWidth(context, 10),
                      vertical: AppLayout.scaleHeight(context, 8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video.title,
                          style: TextStyle(
                            fontSize: AppLayout.fontSize(context, 12),
                            fontWeight: FontWeight.w500,
                            color: AppColors.textDark,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: AppLayout.scaleHeight(context, 3)),
                        Text(
                          video.duration,
                          style: TextStyle(
                            fontSize: AppLayout.fontSize(context, 11),
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Sticky Contact Support button ─────────────────────────────────────────
  Widget _buildContactButton(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppLayout.scaleWidth(context, 16),
          AppLayout.scaleHeight(context, 8),
          AppLayout.scaleWidth(context, 16),
          AppLayout.scaleHeight(context, 16),
        ),
        child: ElevatedButton.icon(
          onPressed: () => _launchLiveChat(context),
          icon: Icon(
            Icons.chat_bubble_outline_rounded,
            size: AppLayout.scaleWidth(context, 18),
            color: AppColors.white,
          ),
          label: Text(
            'Contact Support',
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 16),
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryTeal,
            minimumSize: Size(
              double.infinity,
              AppLayout.scaleHeight(context, 54),
            ),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(AppLayout.scaleWidth(context, 30)),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  // ── Section label ──────────────────────────────────────────────────────────
  Widget _sectionLabel(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'PolySans',
        fontSize: AppLayout.fontSize(context, 15),
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────────
  void _launchLiveChat(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Opening live chat…'),
        backgroundColor: AppColors.primaryTeal,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: AppLayout.scaleHeight(context, 16),
          left: AppLayout.scaleWidth(context, 16),
          right: AppLayout.scaleWidth(context, 16),
        ),
      ),
    );
  }

  void _showReportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReportIssueSheet(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Report Issue Bottom Sheet (preserved from original)
// ─────────────────────────────────────────────────────────────────────────────

class _ReportIssueSheet extends StatefulWidget {
  @override
  State<_ReportIssueSheet> createState() => _ReportIssueSheetState();
}

class _ReportIssueSheetState extends State<_ReportIssueSheet> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String? _selectedCategory;
  bool _isSubmitting = false;

  static const List<String> _categories = [
    'Transaction Issue',
    'Account Access',
    'Card Problem',
    'Transfer Failed',
    'KYC / Verification',
    'Other',
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _selectedCategory != null &&
      _subjectController.text.trim().isNotEmpty &&
      _messageController.text.trim().isNotEmpty;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
            'Your report has been submitted. We\'ll respond within 24 hours.'),
        backgroundColor: AppColors.primaryTeal,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: AppLayout.scaleHeight(context, 16),
          left: AppLayout.scaleWidth(context, 16),
          right: AppLayout.scaleWidth(context, 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          AppLayout.scaleWidth(context, 20),
          AppLayout.scaleHeight(context, 20),
          AppLayout.scaleWidth(context, 20),
          AppLayout.scaleHeight(context, 32) +
              MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppLayout.scaleWidth(context, 20)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: AppLayout.scaleWidth(context, 40),
                height: AppLayout.scaleHeight(context, 4),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 20)),
            Text(
              'Report an Issue',
              style: TextStyle(
                fontFamily: 'PolySans',
                fontSize: AppLayout.fontSize(context, 18),
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 20)),
            Wrap(
              spacing: AppLayout.scaleWidth(context, 8),
              runSpacing: AppLayout.scaleHeight(context, 8),
              children: _categories.map((cat) {
                final selected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppLayout.scaleWidth(context, 12),
                      vertical: AppLayout.scaleHeight(context, 6),
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primaryTeal
                          : AppColors.backgroundScreen,
                      borderRadius: BorderRadius.circular(
                          AppLayout.scaleWidth(context, 20)),
                      border: Border.all(
                        color: selected
                            ? AppColors.primaryTeal
                            : AppColors.divider,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 12),
                        fontWeight: FontWeight.w500,
                        color: selected ? AppColors.white : AppColors.textGrey,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 16)),
            _buildField(context, _subjectController, 'Subject', maxLines: 1),
            SizedBox(height: AppLayout.scaleHeight(context, 12)),
            _buildField(
                context, _messageController, 'Describe the issue in detail…',
                maxLines: 4),
            SizedBox(height: AppLayout.scaleHeight(context, 20)),
            ElevatedButton(
              onPressed: (_canSubmit && !_isSubmitting) ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                disabledBackgroundColor:
                    AppColors.primaryTeal.withValues(alpha: 0.4),
                minimumSize:
                    Size(double.infinity, AppLayout.scaleHeight(context, 52)),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppLayout.scaleWidth(context, 30)),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'Submit Report',
                      style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 16),
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    BuildContext context,
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      onChanged: (_) => setState(() {}),
      maxLines: maxLines,
      style: TextStyle(
        fontSize: AppLayout.fontSize(context, 14),
        color: AppColors.textDark,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: AppColors.textLight,
          fontSize: AppLayout.fontSize(context, 14),
        ),
        filled: true,
        fillColor: AppColors.backgroundScreen,
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(AppLayout.scaleWidth(context, 10)),
          borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(AppLayout.scaleWidth(context, 10)),
          borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(AppLayout.scaleWidth(context, 10)),
          borderSide:
              const BorderSide(color: AppColors.primaryTeal, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppLayout.scaleWidth(context, 14),
          vertical: AppLayout.scaleHeight(context, 12),
        ),
      ),
    );
  }
}
