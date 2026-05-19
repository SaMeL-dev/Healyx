// 커뮤니티 검색 결과 화면 (검색창에서 검색 후 나오는 화면)
// 선택 언어 코드 기반으로 검색 결과 게시글 제목/내용 미리보기를 번역해서 표시
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_language.dart';

import 'community_search.dart';
import 'community_detail.dart';
import 'services/community_service.dart';

class CommunitySearchResultScreen extends StatefulWidget {
  final String keyword;

  const CommunitySearchResultScreen({
    super.key,
    this.keyword = '',
  });

  @override
  State<CommunitySearchResultScreen> createState() =>
      _CommunitySearchResultScreenState();
}

class _CommunitySearchResultScreenState
    extends State<CommunitySearchResultScreen> {
  static const Color mainBlue = Color(0xFF2260FF);
  static const Color softBg = Color(0xFFECF1FF);
  static const Color pageBg = Color(0xFFE2E9FF);
  static const Color tabInactive = Color(0xFFCAD6FF);

  String selectedFilter = '제목+글';
  String selectedSort = '최신순';

  bool _isLoading = false;
  String? _errorMessage;

  String _selectedLanguageCode = 'ko';

  List<_CommunitySearchPostViewData> posts = [];

  @override
  void initState() {
    super.initState();
    _loadSearchResults();
  }

  String get _searchField {
    if (selectedFilter == '제목') {
      return 'title';
    }

    if (selectedFilter == '글') {
      return 'content';
    }

    return 'all';
  }

  String get _sort {
    if (selectedSort == '인기순') {
      return 'popular';
    }

    return 'latest';
  }

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
        '[CommunitySearch] selected language from language_pref: $normalized',
      );

      return normalized;
    }

    final currentLang = AppLanguage.currentLang.value;

    if (currentLang.trim().isNotEmpty) {
      final normalized = _normalizeLanguageCode(currentLang);

      debugPrint(
        '[CommunitySearch] selected language from AppLanguage: $normalized',
      );

      return normalized;
    }

    debugPrint('[CommunitySearch] selected language fallback to ko');

    return 'ko';
  }

  Future<_CommunitySearchPostViewData> _translatePostForList({
    required CommunityPostSummary post,
    required String lang,
  }) async {
    try {
      final translation = await CommunityService().getPostTranslation(
        postId: post.postId,
        lang: lang,
      );

      final translatedTitle = translation.translatedTitle.trim();
      final translatedContent = translation.translatedContent.trim();

      return _CommunitySearchPostViewData(
        post: post,
        displayTitle: translatedTitle.isNotEmpty ? translatedTitle : post.title,
        displayContent: translatedContent.isNotEmpty
            ? translatedContent
            : post.contentPreview,
        isTranslated: true,
      );
    } catch (e) {
      debugPrint(
        '[CommunitySearch] translate failed postId=${post.postId}: $e',
      );

      return _CommunitySearchPostViewData(
        post: post,
        displayTitle: post.title,
        displayContent: post.contentPreview,
        isTranslated: false,
      );
    }
  }

  Future<List<_CommunitySearchPostViewData>> _translatePostList({
    required List<CommunityPostSummary> targetPosts,
    required String lang,
  }) async {
    if (targetPosts.isEmpty) {
      return [];
    }

    return Future.wait(
      targetPosts.map(
            (post) => _translatePostForList(
          post: post,
          lang: lang,
        ),
      ),
    );
  }

  Future<void> _loadSearchResults() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final selectedLanguageCode = await _loadSelectedLanguageCode();

      final result = await CommunityService().getPosts(
        page: 0,
        size: 10,
        sort: _sort,
        keyword: widget.keyword.trim().isEmpty ? null : widget.keyword.trim(),
        searchField: _searchField,
      );

      final translatedPosts = await _translatePostList(
        targetPosts: result.content,
        lang: selectedLanguageCode,
      );

      if (!mounted) return;

      setState(() {
        _selectedLanguageCode = selectedLanguageCode;
        posts = translatedPosts;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _changeFilter(String filter) {
    if (selectedFilter == filter) return;

    setState(() {
      selectedFilter = filter;
    });

    _loadSearchResults();
  }

  void _changeSort(String sort) {
    if (selectedSort == sort) return;

    setState(() {
      selectedSort = sort;
    });

    _loadSearchResults();
  }

  Future<void> _goToDetailScreen(_CommunitySearchPostViewData item) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CommunityDetailScreen(
          postId: item.post.postId,
        ),
      ),
    );

    if (result == true) {
      _loadSearchResults();
    }
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
                  onPressed: _loadSearchResults,
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

    if (posts.isEmpty) {
      return RefreshIndicator(
        color: mainBlue,
        onRefresh: _loadSearchResults,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 40, 14, 20),
          children: [
            const SizedBox(height: 120),
            const Icon(
              Icons.search_off,
              color: mainBlue,
              size: 44,
            ),
            const SizedBox(height: 14),
            Center(
              child: Text(
                AppLanguage.t('review_search_no_result'),
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
      onRefresh: _loadSearchResults,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 20),
        itemCount: posts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final item = posts[index];
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

  String _buildSearchResultSubtitle() {
    final keyword = widget.keyword.trim();

    if (keyword.isEmpty) {
      return AppLanguage.t('community_search_result_subtitle');
    }

    return '"$keyword" ${AppLanguage.t('community_search_result_title')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  const SizedBox(height: 16),

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
                                builder: (_) => const CommunitySearchScreen(),
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

                  const SizedBox(height: 28),

                  Text(
                    AppLanguage.t('community_search_result_title'),
                    style: const TextStyle(
                      color: mainBlue,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    _buildSearchResultSubtitle(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 28),

                  Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 12),
                    child: Row(
                      children: [
                        _FilterButton(
                          text: AppLanguage.t(
                            'community_filter_title_content',
                          ),
                          isSelected: selectedFilter == '제목+글',
                          onTap: () => _changeFilter('제목+글'),
                        ),
                        const SizedBox(width: 8),
                        _FilterButton(
                          text: AppLanguage.t('community_filter_title'),
                          isSelected: selectedFilter == '제목',
                          onTap: () => _changeFilter('제목'),
                        ),
                        const SizedBox(width: 8),
                        _FilterButton(
                          text: AppLanguage.t('community_filter_content'),
                          isSelected: selectedFilter == '글',
                          onTap: () => _changeFilter('글'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 10,
                      right: 16,
                      bottom: 4,
                    ),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: PopupMenuButton<String>(
                        color: Colors.white,
                        elevation: 4,
                        offset: const Offset(0, 30),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        onSelected: _changeSort,
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: '최신순',
                            child: Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  AppLanguage.t('community_sort_newest'),
                                ),
                                if (selectedSort == '최신순')
                                  const Icon(
                                    Icons.check,
                                    color: mainBlue,
                                    size: 18,
                                  ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: '인기순',
                            child: Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  AppLanguage.t('community_sort_popular'),
                                ),
                                if (selectedSort == '인기순')
                                  const Icon(
                                    Icons.check,
                                    color: mainBlue,
                                    size: 18,
                                  ),
                              ],
                            ),
                          ),
                        ],
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              AppLanguage.t('community_sort_label')
                                  .replaceAll(
                                '{sort}',
                                selectedSort == '최신순'
                                    ? AppLanguage.t('community_sort_newest')
                                    : AppLanguage.t(
                                  'community_sort_popular',
                                ),
                              ),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.black,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    child: _buildPostList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunitySearchPostViewData {
  final CommunityPostSummary post;
  final String displayTitle;
  final String displayContent;
  final bool isTranslated;

  const _CommunitySearchPostViewData({
    required this.post,
    required this.displayTitle,
    required this.displayContent,
    required this.isTranslated,
  });
}

class _FilterButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  static const Color mainBlue = Color(0xFF2260FF);
  static const Color tabInactive = Color(0xFFCAD6FF);

  const _FilterButton({
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
        constraints: const BoxConstraints(minWidth: 72),
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? mainBlue : tabInactive,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
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