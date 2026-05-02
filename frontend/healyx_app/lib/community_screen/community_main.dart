import 'package:flutter/material.dart';

import 'community_search.dart';
import 'community_write.dart';
import 'community_detail.dart';

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

  int _selectedTab = 0; // 0: 홈, 1: 인기

  // 더미 게시물 데이터 (탭과 무관하게 동일하게 표시)
  final List<Map<String, String>> _posts = [
    {
      'title': '서울에 24시간 하는 병원있나요?',
      'content': '서울에 밤에도 진료하는 곳 있는지 궁금해요!\n야간 진료 가능한 곳 추천해주세요 !',
    },
    {
      'title': '한국에서 치과 치료 보험',
      'content': '한국에서 치과치료 받을 때 보험이 어떤식으로\n적용되는지 궁금합니다.',
    },
    {
      'title': '서울에 24시간 하는 병원있나요?',
      'content': '서울에 밤에도 진료하는 곳 있는지 궁금해요!\n야간 진료 가능한 곳 추천해주세요 !',
    },
    {
      'title': '서울에 24시간 하는 병원있나요?',
      'content': '서울에 밤에도 진료하는 곳 있는지 궁금해요!\n야간 진료 가능한 곳 추천해주세요 !',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      floatingActionButton: FloatingActionButton(
        backgroundColor: subBlue,
        elevation: 4,
        shape: const CircleBorder(),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CommunityWriteScreen()),
          );
        },
        child: const Icon(Icons.edit_outlined, color: Color(0xFF2E498F), size: 28),
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
                          icon: const Icon(Icons.arrow_back_ios,
                              color: mainBlue, size: 20),
                        ),
                        const Expanded(
                          child: Center(
                            child: Text(
                              '커뮤니티',
                              style: TextStyle(
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
                                  builder: (_) => const CommunitySearchScreen()),
                            );
                          },
                          icon: Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: softBg,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.search,
                                color: Colors.black54, size: 22),
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
                                          horizontal: 2.5),
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

                          const Text(
                            '병원 / 약 / 번역 관련해서\n서로 소통해보세요!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: mainBlue,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 탭 버튼 (UI 토글만, 카드 데이터 변경 없음)
                  Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 12),
                    child: Row(
                      children: [
                        _TabButton(
                          text: '홈',
                          isSelected: _selectedTab == 0,
                          onTap: () => setState(() => _selectedTab = 0),
                        ),
                        const SizedBox(width: 8),
                        _TabButton(
                          text: '인기',
                          isSelected: _selectedTab == 1,
                          onTap: () => setState(() => _selectedTab = 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 포스트 리스트 (탭 무관하게 동일한 더미 데이터)
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(14, 20, 14, 20),
                itemCount: _posts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CommunityDetailScreen(),
                        ),
                      );
                    },
                    child: _PostCard(
                      title: _posts[index]['title']!,
                      content: _posts[index]['content']!,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
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

  static const Color mainBlue = Color(0xFF2260FF);
  static const Color softBg = Color(0xFFECF1FF);

  const _PostCard({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
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
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: mainBlue,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  content,
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: softBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_bubble_rounded,
                        color: mainBlue, size: 15),
                    SizedBox(width: 4),
                    Text(
                      '35',
                      style: TextStyle(
                        color: mainBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
