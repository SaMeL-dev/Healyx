// 커뮤니티 검색 결과 화면 (검색창에서 검색 후 나오는 화면)
import 'package:flutter/material.dart';

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

  List<CommunityPostSummary> posts = [];

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

  Future<void> _loadSearchResults() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final result = await CommunityService().getPosts(
        page: 0,
        size: 10,
        sort: _sort,
        keyword: widget.keyword.trim().isEmpty ? null : widget.keyword.trim(),
        searchField: _searchField,
      );

      if (!mounted) return;

      setState(() {
        posts = result.content;
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

  void _goToDetailScreen(CommunityPostSummary post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommunityDetailScreen(
          postId: post.postId,
        ),
      ),
    );
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
                  child: const Text(
                    '다시 시도',
                    style: TextStyle(
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
          children: const [
            SizedBox(height: 120),
            Icon(
              Icons.search_off,
              color: mainBlue,
              size: 44,
            ),
            SizedBox(height: 14),
            Center(
              child: Text(
                '검색 결과가 없습니다.',
                style: TextStyle(
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
          final post = posts[index];

          return GestureDetector(
            onTap: () => _goToDetailScreen(post),
            child: _PostCard(
              title: post.title,
              content: post.contentPreview,
              authorNickname: post.authorNickname,
              likeCount: post.likeCount,
              commentCount: post.commentCount,
              createdAt: post.createdAt,
            ),
          );
        },
      ),
    );
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
                    widget.keyword.trim().isEmpty
                        ? AppLanguage.t('community_search_result_subtitle')
                        : '"${widget.keyword}" 검색 결과',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // 필터 버튼
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

            // 리스트 영역
            Expanded(
              child: Column(
                children: [
                  // 정렬 드롭다운
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

  static const Color mainBlue = Color(0xFF2260FF);
  static const Color softBg = Color(0xFFECF1FF);

  const _PostCard({
    required this.title,
    required this.content,
    required this.authorNickname,
    required this.likeCount,
    required this.commentCount,
    required this.createdAt,
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
          // 제목
          Text(
            title.isEmpty ? '제목 없음' : title,
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
                  authorNickname.isEmpty ? '익명' : authorNickname,
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

          // 본문 + 좋아요/댓글 아이콘
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  content.isEmpty ? '내용 미리보기가 없습니다.' : content,
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