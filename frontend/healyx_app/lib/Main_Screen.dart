import 'package:flutter/material.dart';
import 'find_hospital_main.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
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
                    onPressed: () {
                      _showMessage(context, '메뉴 버튼 클릭');
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
                    onPressed: () {
                      _showMessage(context, '알림 버튼 클릭');
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
                                _showMessage(context, '의료 번역 클릭');
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
                            onArrowTap: () {
                              _showMessage(context, '리뷰 더보기 클릭');
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
                            onArrowTap: () {
                              _showMessage(context, '커뮤니티 더보기 클릭');
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
            Icon(
              icon,
              size: 42,
              color: const Color(0xFF4E7CFF),
            ),
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
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black87,
            ),
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
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black87,
            ),
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