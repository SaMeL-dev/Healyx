import 'package:flutter/material.dart';
import 'find_hospital_screen/find_hospital_main.dart';
import 'translation_screen/translation_upload.dart';
import 'community_screen/community_main.dart';
import 'review_screen/review_search.dart';
import 'community_screen/community_notification.dart';
import 'menu_screen/menu_main.dart';
import 'login_signup_screen/login_screen.dart';

class MainScreen extends StatelessWidget {
  // true = 로그인 상태, false = 비로그인 상태
  final bool isLoggedIn;

  const MainScreen({
    super.key,
    this.isLoggedIn = false,
  });

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
                const Text(
                  '로그인이 필요한 기능입니다.\n로그인 하시겠습니까?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
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
                          child: const Text(
                            '예',
                            style: TextStyle(
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
                          child: const Text(
                            '아니오',
                            style: TextStyle(
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

  void _moveIfLoggedIn({
    required BuildContext context,
    required Widget screen,
  }) {
    if (isLoggedIn) {
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MenuScreen(
                            isLoggedIn: isLoggedIn,
                          ),
                        ),
                      );
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
                              title: '병원 찾기',
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
                              title: '의료 번역',
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
                            title: '리뷰',
                            // 리뷰 더보기 → 로그인 필요
                            onArrowTap: () {
                              _moveIfLoggedIn(
                                context: context,
                                screen: const ReviewSearchScreen(),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          _buildReviewCard(
                            title: '서대문 병원',
                            subtitle: '예약도 잘 되어있고 빠르게 진료됐음',
                            rating: '5',
                            comments: '5',
                          ),
                          const SizedBox(height: 10),
                          _buildReviewCard(
                            title: 'ㅇㅇ의원',
                            subtitle: '한국어가 가능한 간호사님이 있어서 좋아요',
                            rating: '4',
                            comments: '2',
                          ),
                          const SizedBox(height: 18),
                          _buildSectionTitle(
                            title: '커뮤니티',
                            // 커뮤니티 더보기 → 로그인 필요
                            onArrowTap: () {
                              _moveIfLoggedIn(
                                context: context,
                                screen: const CommunityMainScreen(),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          _buildCommunityCard(
                            title: '아산시 병원 추천',
                            subtitle: '제가 사는 아산은 병원이 많지도, 외국인을 수용할만한...',
                            likes: '5',
                            comments: '6',
                          ),
                          const SizedBox(height: 10),
                          _buildCommunityCard(
                            title: '건강보험 자동 가입',
                            subtitle: '내년에 자동 가입돼서 가격 가입한다는데 가능하나요...',
                            likes: '44',
                            comments: '10',
                          ),
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

  Widget _buildReviewCard({
    required String title,
    required String subtitle,
    required String rating,
    required String comments,
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
              const Icon(
                Icons.thumb_up_alt_outlined,
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