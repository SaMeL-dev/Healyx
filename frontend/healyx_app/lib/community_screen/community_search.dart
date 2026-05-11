// 커뮤니티 검색 화면 (검색창과 추천 검색어 영역)
import 'package:flutter/material.dart';
import '../app_language.dart'; 
import 'community_search_result.dart';

class CommunitySearchScreen extends StatefulWidget {
  const CommunitySearchScreen({super.key});

  @override
  State<CommunitySearchScreen> createState() =>
      _CommunitySearchScreenState();
}

class _CommunitySearchScreenState extends State<CommunitySearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  void _goToSearchResult() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CommunitySearchResultScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF2260FF);
    const Color lightBlue = Color(0xFFECF1FF);
    const Color white = Color(0xFFFFFFFF);

    return Scaffold(
      backgroundColor: white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // 🔹 상단
              Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: primaryBlue,
                        size: 24,
                      ),
                    ),
                  ),
                  Text(
                    AppLanguage.t('community'), // '커뮤니티'
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: primaryBlue,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 60),

              // 🔥 검색창 (리뷰랑 동일 비율)
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: lightBlue,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),

                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: AppLanguage.t('search_hint'), // '검색어를 입력하세요.'
                          hintStyle: TextStyle(
                            color: Color(0xFF809CFF),
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),

                    GestureDetector(
                      onTap: _goToSearchResult,
                      child: Container(
                        width: 60,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: primaryBlue,
                          borderRadius: BorderRadius.horizontal(
                            right: Radius.circular(14),
                          ),
                        ),
                        child: const Icon(
                          Icons.search,
                          color: white,
                          size: 30,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // 추천 영역 복구
              Row(
                children: [
                  Icon(
                    Icons.search,
                    color: primaryBlue,
                    size: 24,
                  ),
                  SizedBox(width: 10),
                  Text(
                    AppLanguage.t('community_search_recommend_label'), // '이런 내용을 검색해보세요.'
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),
             _RecommendText(text: AppLanguage.t('community_search_recommend_1')), // '한의원 추천'
             _RecommendText(text: AppLanguage.t('community_search_recommend_2')), // '병원 주변 맛집'
             _RecommendText(text: AppLanguage.t('community_search_recommend_3')), // '약봉투 번역 팁'
            ],
          ),
        ),
      ),
    );
  }
}

class _RecommendText extends StatelessWidget {
  final String text;

  const _RecommendText({required this.text});

  static const Color mainBlue = Color(0xFF2260FF);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 10),
      child: Row(
        children: [
          const Text(
            '•',
            style: TextStyle(
              color: mainBlue,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}