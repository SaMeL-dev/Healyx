// 커뮤니티 검색 결과 화면 (검색창에서 검색 후 나오는 화면)
import 'package:flutter/material.dart';

import 'community_search.dart';
import 'community_detail.dart';

class CommunitySearchResultScreen extends StatefulWidget {
  const CommunitySearchResultScreen({super.key});

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

  final posts = [
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
                            child: const Icon(Icons.search,
                                color: Colors.black54, size: 22),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  const Text(
                    '검색 결과',
                    style: TextStyle(
                      color: mainBlue,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    '원하는 정보를 찾아보세요.',
                    style: TextStyle(
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
                          text: '제목+글',
                          isSelected: selectedFilter == '제목+글',
                          onTap: () => setState(() => selectedFilter = '제목+글'),
                        ),
                        const SizedBox(width: 8),
                        _FilterButton(
                          text: '제목',
                          isSelected: selectedFilter == '제목',
                          onTap: () => setState(() => selectedFilter = '제목'),
                        ),
                        const SizedBox(width: 8),
                        _FilterButton(
                          text: '글',
                          isSelected: selectedFilter == '글',
                          onTap: () => setState(() => selectedFilter = '글'),
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
                    padding: const EdgeInsets.only(top: 10, right: 16, bottom: 4),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: PopupMenuButton<String>(
                        color: Colors.white,
                        elevation: 4,
                        offset: const Offset(0, 30),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        onSelected: (value) => setState(() => selectedSort = value),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: '최신순',
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('최신순'),
                                if (selectedSort == '최신순')
                                  const Icon(Icons.check, color: mainBlue, size: 18),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: '인기순',
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('인기순'),
                                if (selectedSort == '인기순')
                                  const Icon(Icons.check, color: mainBlue, size: 18),
                              ],
                            ),
                          ),
                        ],
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '정렬: $selectedSort',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down,
                                color: Colors.black, size: 22),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 포스트 리스트
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 6, 14, 20),
                      itemCount: posts.length,
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
                            title: posts[index]['title']!,
                            content: posts[index]['content']!,
                          ),
                        );
                      },
                    ),
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
        width: text == '제목+글' ? 90 : 72,
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
          // 제목
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
          // 본문 + 댓글 아이콘 같은 행
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
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: softBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_bubble_rounded, color: mainBlue, size: 15),
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