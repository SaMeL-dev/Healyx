// 리뷰 검색 화면
// 리뷰 검색 화면에서는 사용자가 지역과 검색어를 입력하여 리뷰 검색 결과 화면으로 이동할 수 있도록 구성
import 'package:flutter/material.dart';
import '../app_language.dart';
import '../common/common_toast.dart';
import 'review_search_result.dart';

class ReviewSearchScreen extends StatefulWidget {
  const ReviewSearchScreen({super.key});

  @override
  State<ReviewSearchScreen> createState() => _ReviewSearchScreenState();
}

class _ReviewSearchScreenState extends State<ReviewSearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  String selectedRegion = '지역'; // 이거 퍼블리싱 임시로 넣어둔 거임!! 나중에는 실제 지역 데이터로 바꿔야 함!! 

  final List<String> regions = [
    '지역',
    '서울특별시',
    '부산광역시',
    '대구광역시',
    '인천광역시',
    '광주광역시',
    '대전광역시',
    '울산광역시',
    '세종특별자치시',
    '경기도',
    '강원특별자치도',
    '충청북도',
    '충청남도',
    '전북특별자치도',
    '전라남도',
    '경상북도',
    '경상남도',
    '제주특별자치도',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _goToSearchResult() {
    if (_searchController.text.trim().isEmpty) {
      CommonToast.show(context, message: AppLanguage.t('review_search_empty_name'));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewSearchResultScreen(
          selectedRegion: selectedRegion,
          searchKeyword: _searchController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF2260FF);
    const Color lightBlue = Color(0xFFECF1FF);
    const Color white = Color(0xFFFFFFFF);
    const Color selectedMenuColor = Color(0xFF809CFF);

    return Scaffold(
      backgroundColor: white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: primaryBlue,
                        size: 24,
                      ),
                    ),
                  ),
                  Text(
                    AppLanguage.t('review'), // '리뷰'
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: primaryBlue,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 86),

              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: lightBlue,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 4),
                    PopupMenuButton<String>(
                      color: white,
                      constraints: const BoxConstraints(
                        minWidth: 150,
                        maxWidth: 160,
                      ),
                      offset: const Offset(0, 40),
                      onSelected: (value) {
                        setState(() {
                          selectedRegion = value;
                        });
                      },
                      itemBuilder: (context) {
                        return regions.map((region) {
                          final bool isSelected = selectedRegion == region;

                          return PopupMenuItem<String>(
                            value: region,
                            height: 46,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? selectedMenuColor.withOpacity(0.25)
                                    : white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                region == '지역' ? AppLanguage.t('review_search_region_default') : region, // '지역'
                                style: const TextStyle(
                                  color: primaryBlue,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        }).toList();
                      },
                      child: Container(
                        width: 86,
                        height: 34,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                selectedRegion == '지역' ? AppLanguage.t('review_search_region_default') : selectedRegion, // '지역'
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: primaryBlue,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              color: primaryBlue,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: AppLanguage.t('review_search_hint'), // '검색어를 입력하세요.'
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
            ],
          ),
        ),
      ),
    );
  }
}