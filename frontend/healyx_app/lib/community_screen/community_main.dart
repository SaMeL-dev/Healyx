// 커뮤니티 메인 화면 (홈/인기 탭, 게시글 리스트, 검색/글쓰기 버튼)
// 선택 언어 코드 기반으로 게시글 제목/내용 미리보기를 번역해서 표시
// 단, 내가 작성한 게시글은 번역하지 않고 원문 그대로 표시
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_language.dart';
import 'community_search.dart';
import 'community_write.dart';
import 'community_detail.dart';
import 'services/community_service.dart';

enum _CommunityToastType {
  success,
  warning,
  error,
}

class CommunityMainScreen extends StatefulWidget {
  const CommunityMainScreen({super.key});

  @override
  State<CommunityMainScreen> createState() => _CommunityMainScreenState();
}

class _CommunityMainScreenState extends State<CommunityMainScreen> {
  static const Color mainBlue = Color(0xFF2260FF);
  static const Color softBg = Color(0xFFECF1FF);
  static const Color subBlue = Color(0xFF809CFF);
  static const Color tabInactive = Color(0xFFCAD6FF);
  static const Color pageBg = Color(0xFFE2E9FF);
  static const int _pageSize = 10;

  int _selectedTab = 0; // 0: 홈, 1: 인기
  int _currentPage = 0;
  int _totalPages = 1;

  bool _isLoading = false;
  String? _errorMessage;

  String _selectedLanguageCode = 'ko';

  List<_CommunityMainPostViewData> _posts = [];

  final ScrollController _postScrollController = ScrollController();

  OverlayEntry? _toastEntry;
  Timer? _toastTimer;

  @override
  void initState() {
    super.initState();
    _loadPosts(
      page: 0,
      resetScroll: true,
    );
  }

  @override
  void dispose() {
    _removeCustomToast();
    _postScrollController.dispose();
    super.dispose();
  }

  String get _currentSort {
    if (_selectedTab == 0) {
      return 'latest';
    }
    return 'popular';
  }

  bool get _showPagination => _posts.isNotEmpty && _totalPages > 1;

  bool get _canGoPrevious => !_isLoading && _currentPage > 0;

  bool get _canGoNext => !_isLoading && _currentPage < _totalPages - 1;

  String _normalizeLanguageCode(String? value) {
    final code = value?.trim().toLowerCase();

    if (code == null || code.isEmpty) {
      return 'ko';
    }

    if (code.startsWith('ko')) return 'ko';
    if (code.startsWith('en')) return 'en';
    if (code.startsWith('zh')) return 'zh';
    if (code.startsWith('vi')) return 'vi';
    if (code.startsWith('th')) return 'th';
    if (code.startsWith('ja')) return 'ja';

    return 'ko';
  }

  Future<String> _loadSelectedLanguageCode() async {
    final prefs = await SharedPreferences.getInstance();

    final savedLanguage = prefs.getString('language_pref');

    if (savedLanguage != null && savedLanguage.trim().isNotEmpty) {
      final normalized = _normalizeLanguageCode(savedLanguage);

      debugPrint(
        '[CommunityMain] selected language from language_pref: $normalized',
      );

      return normalized;
    }

    final currentLang = AppLanguage.currentLang.value;

    if (currentLang.trim().isNotEmpty) {
      final normalized = _normalizeLanguageCode(currentLang);

      debugPrint(
        '[CommunityMain] selected language from AppLanguage: $normalized',
      );

      return normalized;
    }

    return 'ko';
  }

  Future<Set<int>> _loadMyPostIds() async {
    try {
      final myPosts = await CommunityService().getMyPosts();

      return myPosts.map((post) => post.postId).toSet();
    } catch (e) {
      debugPrint('[CommunityMain] getMyPosts failed: $e');

      // 비로그인 상태이거나 내 게시글 조회 실패 시에는
      // 목록 전체가 깨지지 않도록 내 글 판단 없이 진행
      return {};
    }
  }

  Future<_CommunityMainPostViewData> _translatePostForList({
    required CommunityPostSummary post,
    required String lang,
    required Set<int> myPostIds,
  }) async {
    final bool isMyPost = myPostIds.contains(post.postId);

    // 내가 작성한 게시글은 번역하지 않고 원문 그대로 표시
    if (isMyPost) {
      return _CommunityMainPostViewData(
        post: post,
        displayTitle: post.title,
        displayContent: post.contentPreview,
        isTranslated: false,
        isMyPost: true,
      );
    }

    try {
      final translation = await CommunityService().getPostTranslation(
        postId: post.postId,
        lang: lang,
      );

      final translatedTitle = translation.translatedTitle.trim();
      final translatedContent = translation.translatedContent.trim();

      return _CommunityMainPostViewData(
        post: post,
        displayTitle: translatedTitle.isNotEmpty ? translatedTitle : post.title,
        displayContent: translatedContent.isNotEmpty
            ? translatedContent
            : post.contentPreview,
        isTranslated: true,
        isMyPost: false,
      );
    } catch (e) {
      debugPrint('[CommunityMain] translate failed postId=${post.postId}: $e');

      return _CommunityMainPostViewData(
        post: post,
        displayTitle: post.title,
        displayContent: post.contentPreview,
        isTranslated: false,
        isMyPost: false,
      );
    }
  }

  Future<List<_CommunityMainPostViewData>> _translatePostList({
    required List<CommunityPostSummary> posts,
    required String lang,
    required Set<int> myPostIds,
  }) async {
    if (posts.isEmpty) {
      return [];
    }

    return Future.wait(
      posts.map(
            (post) => _translatePostForList(
          post: post,
          lang: lang,
          myPostIds: myPostIds,
        ),
      ),
    );
  }

  Future<void> _loadPosts({
    int? page,
    bool resetScroll = false,
  }) async {
    final int targetPage = page ?? _currentPage;

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final selectedLanguageCode = await _loadSelectedLanguageCode();

      final result = await CommunityService().getPosts(
        page: targetPage,
        size: _pageSize,
        sort: _currentSort,
      );

      final myPostIds = await _loadMyPostIds();

      final translatedPosts = await _translatePostList(
        posts: result.content,
        lang: selectedLanguageCode,
        myPostIds: myPostIds,
      );

      if (!mounted) return;

      setState(() {
        _selectedLanguageCode = selectedLanguageCode;
        _posts = translatedPosts;
        _currentPage = result.number;
        _totalPages = result.totalPages <= 0 ? 1 : result.totalPages;
      });

      if (resetScroll) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_postScrollController.hasClients) {
            _postScrollController.jumpTo(0);
          }
        });
      }
    } catch (e) {
      if (!mounted) return;

      final message = e.toString().replaceFirst('Exception: ', '');

      setState(() {
        _errorMessage = message;
      });

      _showCustomToast(
        message,
        type: _CommunityToastType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _changeTab(int index) {
    if (_selectedTab == index) return;

    setState(() {
      _selectedTab = index;
      _currentPage = 0;
      _totalPages = 1;
      _posts = [];
    });

    _loadPosts(
      page: 0,
      resetScroll: true,
    );
  }

  void _goToPage(int page) {
    if (_isLoading) return;
    if (page < 0 || page >= _totalPages) return;
    if (page == _currentPage) return;

    _loadPosts(
      page: page,
      resetScroll: true,
    );
  }

  Future<void> _goToWriteScreen() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const CommunityWriteScreen(),
      ),
    );

    if (result == true) {
      _loadPosts(
        page: 0,
        resetScroll: true,
      );
    }
  }

  Future<void> _goToDetailScreen(_CommunityMainPostViewData item) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CommunityDetailScreen(
          postId: item.post.postId,
        ),
      ),
    );

    if (result == true) {
      _loadPosts(
        page: _currentPage,
      );
    }
  }

  void _removeCustomToast() {
    _toastTimer?.cancel();
    _toastTimer = null;
    _toastEntry?.remove();
    _toastEntry = null;
  }

  void _showCustomToast(
      String message, {
        _CommunityToastType type = _CommunityToastType.success,
      }) {
    if (!mounted || message.trim().isEmpty) return;

    _removeCustomToast();

    final overlay = Overlay.maybeOf(context);

    if (overlay == null) {
      return;
    }

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final bool isSuccess = type == _CommunityToastType.success;

    final IconData iconData =
    isSuccess ? Icons.check_rounded : Icons.priority_high_rounded;

    final Color iconColor = isSuccess ? mainBlue : const Color(0xFFFF8A00);
    final Color iconBg = isSuccess ? softBg : const Color(0xFFFFF3E0);
    final Color borderColor =
    isSuccess ? const Color(0xFFD8E4FF) : const Color(0xFFFFD6A6);
    final Color textColor = isSuccess ? mainBlue : const Color(0xFFE06B00);

    _toastEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: 20,
          right: 20,
          bottom: bottomPadding + 26,
          child: IgnorePointer(
            ignoring: true,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 16 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: borderColor,
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: iconBg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          iconData,
                          color: iconColor,
                          size: 17,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            height: 1.35,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_toastEntry!);

    _toastTimer = Timer(const Duration(milliseconds: 2200), () {
      _removeCustomToast();
    });
  }

  Widget _buildPostList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: mainBlue,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: mainBlue,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 42,
                child: ElevatedButton(
                  onPressed: () => _loadPosts(page: _currentPage),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(21),
                    ),
                  ),
                  child: Text(
                    AppLanguage.t('retry'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_posts.isEmpty) {
      return RefreshIndicator(
        color: mainBlue,
        onRefresh: () => _loadPosts(page: _currentPage),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 40, 14, 20),
          children: [
            const SizedBox(height: 120),
            const Icon(
              Icons.chat_bubble_outline,
              color: mainBlue,
              size: 44,
            ),
            const SizedBox(height: 14),
            Center(
              child: Text(
                AppLanguage.t('community_no_posts'),
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: mainBlue,
      onRefresh: () => _loadPosts(page: _currentPage),
      child: ListView.separated(
        controller: _postScrollController,
        padding: const EdgeInsets.fromLTRB(14, 20, 14, 20),
        itemCount: _posts.length + (_showPagination ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          if (_showPagination && index == _posts.length) {
            return _buildPaginationControls();
          }

          final item = _posts[index];
          final post = item.post;

          return GestureDetector(
            onTap: () => _goToDetailScreen(item),
            child: _PostCard(
              title: item.displayTitle,
              content: item.displayContent,
              authorNickname: post.authorNickname,
              likeCount: post.likeCount,
              commentCount: post.commentCount,
              createdAt: post.createdAt,
              languageCode: _selectedLanguageCode,
              isTranslated: item.isTranslated,
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaginationControls() {
    return Padding(
      padding: const EdgeInsets.only(
        top: 8,
        bottom: 70,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PageArrowButton(
            icon: Icons.chevron_left_rounded,
            isEnabled: _canGoPrevious,
            onTap: () => _goToPage(_currentPage - 1),
          ),
          const SizedBox(width: 18),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${_currentPage + 1}',
                  style: const TextStyle(
                    color: mainBlue,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: ' / $_totalPages',
                  style: const TextStyle(
                    color: Colors.black45,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          _PageArrowButton(
            icon: Icons.chevron_right_rounded,
            isEnabled: _canGoNext,
            onTap: () => _goToPage(_currentPage + 1),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      floatingActionButton: FloatingActionButton(
        backgroundColor: subBlue,
        elevation: 4,
        shape: const CircleBorder(),
        onPressed: _goToWriteScreen,
        child: const Icon(
          Icons.edit_outlined,
          color: Color(0xFF2E498F),
          size: 28,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // 상단 헤더
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: mainBlue,
                            size: 20,
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              AppLanguage.t('community'),
                              style: const TextStyle(
                                color: mainBlue,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                const CommunitySearchScreen(),
                              ),
                            );
                          },
                          icon: Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: softBg,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.search,
                              color: Colors.black54,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 배너
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        color: softBg,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              const Icon(
                                Icons.chat_bubble_rounded,
                                color: subBlue,
                                size: 70,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(
                                    3,
                                        (i) => Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 2.5,
                                      ),
                                      width: 7,
                                      height: 7,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(width: 6),

                          const Icon(
                            Icons.medication_rounded,
                            color: subBlue,
                            size: 32,
                          ),

                          const SizedBox(width: 18),

                          Expanded(
                            child: Text(
                              AppLanguage.t('community_banner_text'),
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: mainBlue,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 탭 버튼
                  Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 12),
                    child: Row(
                      children: [
                        _TabButton(
                          text: AppLanguage.t('community_tab_home'),
                          isSelected: _selectedTab == 0,
                          onTap: () => _changeTab(0),
                        ),
                        const SizedBox(width: 8),
                        _TabButton(
                          text: AppLanguage.t('community_tab_popular'),
                          isSelected: _selectedTab == 1,
                          onTap: () => _changeTab(1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _buildPostList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageArrowButton extends StatelessWidget {
  final IconData icon;
  final bool isEnabled;
  final VoidCallback onTap;

  static const Color mainBlue = Color(0xFF2260FF);
  static const Color disabledGrey = Color(0xFFCFCFCF);

  const _PageArrowButton({
    required this.icon,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isEnabled ? mainBlue : disabledGrey,
          size: 30,
        ),
      ),
    );
  }
}

class _CommunityMainPostViewData {
  final CommunityPostSummary post;
  final String displayTitle;
  final String displayContent;
  final bool isTranslated;
  final bool isMyPost;

  const _CommunityMainPostViewData({
    required this.post,
    required this.displayTitle,
    required this.displayContent,
    required this.isTranslated,
    required this.isMyPost,
  });
}

class _TabButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  static const Color mainBlue = Color(0xFF2260FF);
  static const Color tabInactive = Color(0xFFCAD6FF);

  const _TabButton({
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 80,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? mainBlue : tabInactive,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final String title;
  final String content;
  final String authorNickname;
  final int likeCount;
  final int commentCount;
  final String createdAt;
  final String languageCode;
  final bool isTranslated;

  static const Color mainBlue = Color(0xFF2260FF);
  static const Color softBg = Color(0xFFECF1FF);

  const _PostCard({
    required this.title,
    required this.content,
    required this.authorNickname,
    required this.likeCount,
    required this.commentCount,
    required this.createdAt,
    required this.languageCode,
    required this.isTranslated,
  });

  String _formatDate(String value) {
    final dateTime = DateTime.tryParse(value);

    if (dateTime == null) {
      return '';
    }

    final local = dateTime.toLocal();

    final year = local.year.toString();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');

    return '$year.$month.$day';
  }

  @override
  Widget build(BuildContext context) {
    final dateText = _formatDate(createdAt);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isTranslated)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: softBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                AppLanguage.t('community_translation_badge').replaceAll(
                  '{lang}',
                  languageCode,
                ),
                style: const TextStyle(
                  color: mainBlue,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

          Text(
            title.isEmpty ? AppLanguage.t('community_no_title') : title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: mainBlue,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),

          Row(
            children: [
              Expanded(
                child: Text(
                  authorNickname.isEmpty
                      ? AppLanguage.t('community_anonymous')
                      : authorNickname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black45,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (dateText.isNotEmpty)
                Text(
                  dateText,
                  style: const TextStyle(
                    color: Colors.black38,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  content.isEmpty
                      ? AppLanguage.t('community_no_content_preview')
                      : content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CountBadge(
                    icon: Icons.favorite_rounded,
                    count: likeCount,
                  ),
                  const SizedBox(width: 6),
                  _CountBadge(
                    icon: Icons.chat_bubble_rounded,
                    count: commentCount,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final IconData icon;
  final int count;

  static const Color mainBlue = Color(0xFF2260FF);
  static const Color softBg = Color(0xFFECF1FF);

  const _CountBadge({
    required this.icon,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: softBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: mainBlue,
            size: 15,
          ),
          const SizedBox(width: 4),
          Text(
            count.toString(),
            style: const TextStyle(
              color: mainBlue,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
