// 커뮤니티 검색 화면 (검색창과 추천 검색어 영역)
import 'package:flutter/material.dart';

import '../app_language.dart';
import 'community_search_result.dart';

class CommunitySearchScreen extends StatefulWidget {
  const CommunitySearchScreen({super.key});

  @override
  State<CommunitySearchScreen> createState() => _CommunitySearchScreenState();
}

class _CommunitySearchScreenState extends State<CommunitySearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  static const Color primaryBlue = Color(0xFF2260FF);
  static const Color lightBlue = Color(0xFFECF1FF);
  static const Color white = Color(0xFFFFFFFF);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _goToSearchResult({String? keyword}) {
    final String searchKeyword = (keyword ?? _searchController.text).trim();

    if (searchKeyword.isEmpty) {
      _showSnackBar('검색어를 입력해주세요.');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommunitySearchResultScreen(
          keyword: searchKeyword,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // 상단
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
                    AppLanguage.t('community'),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: primaryBlue,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 60),

              // 검색창
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
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _goToSearchResult(),
                        decoration: InputDecoration(
                          hintText: AppLanguage.t('search_hint'),
                          hintStyle: const TextStyle(
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

              // 추천 영역
              Row(
                children: [
                  const Icon(
                    Icons.search,
                    color: primaryBlue,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    AppLanguage.t('community_search_recommend_label'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              _RecommendText(
                text: AppLanguage.t('community_search_recommend_1'),
                onTap: () => _goToSearchResult(
                  keyword: AppLanguage.t('community_search_recommend_1'),
                ),
              ),
              _RecommendText(
                text: AppLanguage.t('community_search_recommend_2'),
                onTap: () => _goToSearchResult(
                  keyword: AppLanguage.t('community_search_recommend_2'),
                ),
              ),
              _RecommendText(
                text: AppLanguage.t('community_search_recommend_3'),
                onTap: () => _goToSearchResult(
                  keyword: AppLanguage.t('community_search_recommend_3'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecommendText extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _RecommendText({
    required this.text,
    required this.onTap,
  });

  static const Color mainBlue = Color(0xFF2260FF);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.only(left: 10, bottom: 10, top: 4),
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
      ),
    );
  }
}