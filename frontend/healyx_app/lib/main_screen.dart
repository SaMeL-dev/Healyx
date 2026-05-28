import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'find_hospital_screen/find_hospital_main.dart';
import 'translation_screen/translation_upload.dart';
import 'community_screen/community_main.dart';
import 'community_screen/community_detail.dart';
import 'review_screen/review_search.dart';
import 'community_screen/community_notification.dart';
import 'menu_screen/menu_main.dart';
import 'login_signup_screen/login_screen.dart';
import 'services/auth_service.dart';
import 'services/review_service.dart';
import 'community_screen/services/community_service.dart';
import 'app_language.dart';

class MainScreen extends StatefulWidget {
  // true = 로그인 상태, false = 비로그인 상태
  final bool isLoggedIn;

  const MainScreen({
    super.key,
    this.isLoggedIn = false,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late bool _isLoggedIn;

  bool _isCommunityLoading = false;
  String? _communityErrorMessage;

  bool _isReviewLoading = false;
  List<LatestReviewData> _latestReviews = [];

  String _selectedLanguageCode = 'ko';

  List<_MainCommunityPostViewData> _latestCommunityPosts = [];

  @override
  void initState() {
    super.initState();

    // LoginScreen에서 MainScreen(isLoggedIn: true)로 넘어온 경우를 먼저 반영
    _isLoggedIn = widget.isLoggedIn;

    // 실제 저장된 accessToken 기준으로 로그인 상태 다시 확인
    _checkLoginStatus();

    // 메인 화면 리뷰 영역 내 최신 리뷰 2개 조회
    _loadLatestReviews();

    // 메인 화면 커뮤니티 영역 최신 게시글 2개 조회
    _loadLatestCommunityPosts();
  }

  Future<bool> _checkLoginStatus() async {
    final result = await AuthService.isLoggedIn();

    if (!mounted) return false;

    setState(() {
      _isLoggedIn = result;
    });

    return result;
  }

  Future<void> _loadLatestReviews() async {
    try {
      setState(() => _isReviewLoading = true);
      final reviews = await ReviewService.getLatestReviews(size: 2);
      if (!mounted) return;
      setState(() {
        _latestReviews = reviews;
      });
    } catch (e) {
      debugPrint('[MainScreen] _loadLatestReviews failed: $e');
    } finally {
      if (mounted) setState(() => _isReviewLoading = false);
    }
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
      return _normalizeLanguageCode(savedLanguage);
    }

    final currentLang = AppLanguage.currentLang.value;

    if (currentLang.trim().isNotEmpty) {
      return _normalizeLanguageCode(currentLang);
    }

    return 'ko';
  }

  Future<Set<int>> _loadMyPostIds() async {
    try {
      final myPosts = await CommunityService().getMyPosts();

      return myPosts.map((post) => post.postId).toSet();
    } catch (e) {
      debugPrint('[MainScreen] getMyPosts failed: $e');

      // 내 게시글 조회에 실패해도 메인 화면 전체가 깨지지 않도록 빈 Set 반환
      return {};
    }
  }

  Future<_MainCommunityPostViewData> _buildCommunityPostViewData({
    required CommunityPostSummary post,
    required String lang,
    required Set<int> myPostIds,
    required bool canTranslate,
  }) async {
    final isMyPost = myPostIds.contains(post.postId);

    // 비로그인 상태이거나 내가 작성한 게시글이면 원문 그대로 표시
    if (!canTranslate || isMyPost) {
      return _MainCommunityPostViewData(
        post: post,
        displayTitle: post.title,
        displayContent: post.contentPreview,
        isTranslated: false,
        isMyPost: isMyPost,
      );
    }

    try {
      final translation = await CommunityService().getPostTranslation(
        postId: post.postId,
        lang: lang,
      );

      final translatedTitle = translation.translatedTitle.trim();
      final translatedContent = translation.translatedContent.trim();

      final hasTranslatedText =
          translatedTitle.isNotEmpty || translatedContent.isNotEmpty;

      return _MainCommunityPostViewData(
        post: post,
        displayTitle: translatedTitle.isNotEmpty ? translatedTitle : post.title,
        displayContent: translatedContent.isNotEmpty
            ? translatedContent
            : post.contentPreview,
        isTranslated: hasTranslatedText,
        isMyPost: false,
      );
    } catch (e) {
      debugPrint(
        '[MainScreen] translate failed postId=${post.postId}: $e',
      );

      return _MainCommunityPostViewData(
        post: post,
        displayTitle: post.title,
        displayContent: post.contentPreview,
        isTranslated: false,
        isMyPost: false,
      );
    }
  }

  Future<void> _loadLatestCommunityPosts() async {
    try {
      setState(() {
        _isCommunityLoading = true;
        _communityErrorMessage = null;
      });

      final selectedLanguageCode = await _loadSelectedLanguageCode();

      final loggedIn = await AuthService.isLoggedIn();

      final result = await CommunityService().getPosts(
        page: 0,
        size: 2,
        sort: 'latest',
      );

      Set<int> myPostIds = {};

      if (loggedIn) {
        myPostIds = await _loadMyPostIds();
      }

      final viewPosts = await Future.wait(
        result.content.map(
              (post) => _buildCommunityPostViewData(
            post: post,
            lang: selectedLanguageCode,
            myPostIds: myPostIds,
            canTranslate: loggedIn,
          ),
        ),
      );

      if (!mounted) return;

      setState(() {
        _isLoggedIn = loggedIn;
        _selectedLanguageCode = selectedLanguageCode;
        _latestCommunityPosts = viewPosts;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _communityErrorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCommunityLoading = false;
        });
      }
    }
  }

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 34, 24, 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLanguage.t('login_required'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2260FF),
                  ),
                ),
                const SizedBox(height: 34),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2260FF),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: Text(
                            AppLanguage.t('yes'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC9D6FF),
                            foregroundColor: const Color(0xFF2260FF),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: Text(
                            AppLanguage.t('no'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _moveIfLoggedIn({
    required BuildContext context,
    required Widget screen,
  }) async {
    final loggedIn = await _checkLoginStatus();

    if (!context.mounted) return;

    if (loggedIn) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => screen,
        ),
      );
    } else {
      _showLoginRequiredDialog(context);
    }
  }

  Future<void> _openCommunityMain(BuildContext context) async {
    final loggedIn = await _checkLoginStatus();

    if (!context.mounted) return;

    if (loggedIn) {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => const CommunityMainScreen(),
        ),
      );

      if (result == true) {
        _loadLatestCommunityPosts();
      } else {
        _loadLatestCommunityPosts();
      }
    } else {
      _showLoginRequiredDialog(context);
    }
  }

  Future<void> _openCommunityDetail({
    required BuildContext context,
    required int postId,
  }) async {
    final loggedIn = await _checkLoginStatus();

    if (!context.mounted) return;

    if (loggedIn) {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => CommunityDetailScreen(
            postId: postId,
          ),
        ),
      );

      if (result == true) {
        _loadLatestCommunityPosts();
      } else {
        _loadLatestCommunityPosts();
      }
    } else {
      _showLoginRequiredDialog(context);
    }
  }

  Future<void> _openMenu(BuildContext context) async {
    final loggedIn = await _checkLoginStatus();

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MenuScreen(
          isLoggedIn: loggedIn,
        ),
      ),
    );
  }

  Widget _buildCommunityPreviewList() {
    if (_isCommunityLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF4E7CFF),
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_communityErrorMessage != null) {
      return _buildCommunityInfoCard(
        message: _communityErrorMessage!,
      );
    }

    if (_latestCommunityPosts.isEmpty) {
      return _buildCommunityInfoCard(
        message: AppLanguage.t('community_no_posts'),
      );
    }

    return Column(
      children: List.generate(_latestCommunityPosts.length, (index) {
        final item = _latestCommunityPosts[index];
        final post = item.post;

        return Padding(
          padding: EdgeInsets.only(
            bottom: index == _latestCommunityPosts.length - 1 ? 0 : 10,
          ),
          child: GestureDetector(
            onTap: () {
              _openCommunityDetail(
                context: context,
                postId: post.postId,
              );
            },
            child: _buildCommunityCard(
              title: item.displayTitle.trim().isEmpty
                  ? AppLanguage.t('community_no_title')
                  : item.displayTitle,
              subtitle: item.displayContent.trim().isEmpty
                  ? AppLanguage.t('community_no_content_preview')
                  : item.displayContent,
              likes: post.likeCount.toString(),
              comments: post.commentCount.toString(),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCommunityInfoCard({
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE6FF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      body: SafeArea(
        child: Column(
          children: [
            // 상단 헤더
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  IconButton(
                    // 햄버거 메뉴 → menu_screen/menu_main.dart
                    onPressed: () {
                      _openMenu(context);
                    },
                    icon: const Icon(
                      Icons.menu,
                      color: Colors.black87,
                      size: 24,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/healyx_logo2.png',
                            width: 35,
                            height: 35,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'HEALYX',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF4E7CFF),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    // 알림 아이콘 → 로그인 필요
                    onPressed: () {
                      _moveIfLoggedIn(
                        context: context,
                        screen: const CommunityNotificationScreen(),
                      );
                    },
                    icon: const Icon(
                      Icons.notifications_none,
                      color: Color(0xFF4E7CFF),
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 상단 연파랑 배경 + 기능 카드 영역
                    Container(
                      width: double.infinity,
                      color: const Color(0xFFDCE6FF),
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildTopMenuCard(
                              icon: Icons.search,
                              title: AppLanguage.t('find_hospital'),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                    const FindHospitalMain(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildTopMenuCard(
                              icon: Icons.translate,
                              title: AppLanguage.t('medical_translation'),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                    const TranslationUploadScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle(
                            title: AppLanguage.t('review'),
                            // 리뷰 더보기 → 로그인 필요
                            onArrowTap: () {
                              _moveIfLoggedIn(
                                context: context,
                                screen: const ReviewSearchScreen(),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          _buildReviewPreviewList(),
                          const SizedBox(height: 18),
                          _buildSectionTitle(
                            title: AppLanguage.t('community'),
                            // 커뮤니티 더보기 → 로그인 필요
                            onArrowTap: () {
                              _openCommunityMain(context);
                            },
                          ),
                          const SizedBox(height: 8),
                          _buildCommunityPreviewList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopMenuCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 122,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFD8E4FF),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 42, color: const Color(0xFF4E7CFF)),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4E7CFF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle({
    required String title,
    required VoidCallback onArrowTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        IconButton(
          onPressed: onArrowTap,
          icon: const Icon(
            Icons.chevron_right,
            color: Color(0xFF7C9CFF),
            size: 22,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          splashRadius: 18,
        ),
      ],
    );
  }

  Widget _buildReviewPreviewList() {
    if (_isReviewLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF4E7CFF),
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_latestReviews.isEmpty) {
      return _buildReviewInfoCard(
        message: AppLanguage.t('review_no_reviews'),
      );
    }

    return Column(
      children: List.generate(_latestReviews.length, (index) {
        final review = _latestReviews[index];
        return Padding(
          padding: EdgeInsets.only(
            bottom: index == _latestReviews.length - 1 ? 0 : 10,
          ),
          child: _buildReviewCard(
            title: review.hospitalName,
            subtitle: review.content.trim().isEmpty
                ? review.nickname
                : review.content,
            rating: review.rating.toString(),
          ),
        );
      }),
    );
  }

  Widget _buildReviewInfoCard({required String message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD8E4FF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildReviewCard({
    required String title,
    required String subtitle,
    required String rating,
    String? comments,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD8E4FF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4E7CFF),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star, size: 14, color: Color(0xFF7C9CFF)),
              const SizedBox(width: 4),
              Text(
                rating,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF7C9CFF),
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (comments != null) ...[
                const SizedBox(width: 14),
                const Icon(
                  Icons.chat_bubble_outline,
                  size: 14,
                  color: Color(0xFF7C9CFF),
                ),
                const SizedBox(width: 4),
                Text(
                  comments,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF7C9CFF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityCard({
    required String title,
    required String subtitle,
    required String likes,
    required String comments,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE6FF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4E7CFF),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.favorite_border,
                size: 14,
                color: Color(0xFF7C9CFF),
              ),
              const SizedBox(width: 4),
              Text(
                likes,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF7C9CFF),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 14),
              const Icon(
                Icons.chat_bubble_outline,
                size: 14,
                color: Color(0xFF7C9CFF),
              ),
              const SizedBox(width: 4),
              Text(
                comments,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF7C9CFF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MainCommunityPostViewData {
  final CommunityPostSummary post;
  final String displayTitle;
  final String displayContent;
  final bool isTranslated;
  final bool isMyPost;

  const _MainCommunityPostViewData({
    required this.post,
    required this.displayTitle,
    required this.displayContent,
    required this.isTranslated,
    required this.isMyPost,
  });
}