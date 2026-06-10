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
  final GlobalKey _regionButtonKey = GlobalKey(); // 지역 버튼 위치 추적용 키

  OverlayEntry? _overlayEntry; // 오버레이 엔트리

  // 버튼에 표시할 한국어 줄임말
  final List<String> regionLabels = [
    '서울',
    '부산',
    '대구',
    '인천',
    '광주',
    '대전',
    '울산',
    '세종',
    '경기',
    '강원',
    '충북',
    '충남',
    '전북',
    '전남',
    '경북',
    '경남',
    '제주',
  ];

  // 드롭다운에 표시할 한국어 줄임말 + 영문
  final List<String> regions = [
    '서울 (Seoul)',
    '부산 (Busan)',
    '대구 (Daegu)',
    '인천 (Incheon)',
    '광주 (Gwangju)',
    '대전 (Daejeon)',
    '울산 (Ulsan)',
    '세종 (Sejong)',
    '경기 (Gyeonggi)',
    '강원 (Gangwon)',
    '충북 (Chungbuk)',
    '충남 (Chungnam)',
    '전북 (Jeonbuk)',
    '전남 (Jeonnam)',
    '경북 (Gyeongbuk)',
    '경남 (Gyeongnam)',
    '제주 (Jeju)',
  ];

  // regionLabels, regions 리스트 아래에 추가
  final List<String> regionValues = [
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

  // 선택된 지역의 인덱스
  // - null: 아무것도 선택 안 된 상태 → 버튼에 '전체' 표시
  // - 0~16: 선택된 인덱스 → regionLabels[index]를 버튼에, regions[index]를 검색에 사용
  int? selectedIndex;

  // selectedRegion getter 수정
  String get selectedRegion =>
      selectedIndex == null ? '' : regionValues[selectedIndex!];

  @override
  void dispose() {
    _removeOverlay();
    _searchController.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showRegionOverlay() {
    if (_overlayEntry != null) {
      _removeOverlay();
      return;
    }

    const Color primaryBlue = Color(0xFF2260FF);
    const Color white = Color(0xFFFFFFFF);
    const Color selectedMenuColor = Color(0xFF809CFF);

    // 지역 버튼의 화면상 위치 계산
    final RenderBox renderBox =
        _regionButtonKey.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final double buttonBottom = offset.dy + renderBox.size.height;
    final double buttonLeft = offset.dx;

    final ScrollController scrollController = ScrollController();

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // 배경 탭 시 닫기
            Positioned.fill(
              child: GestureDetector(
                onTap: _removeOverlay,
                behavior: HitTestBehavior.translucent,
              ),
            ),
            // 드롭다운 카드 - 검색바 바로 아래, 왼쪽 정렬
            Positioned(
              top: buttonBottom + 6, // 검색바 바로 아래 6px 여백
              left: buttonLeft,      // 버튼 왼쪽 기준 정렬
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 220,
                  height: 300,
                  decoration: BoxDecoration(
                    color: white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Scrollbar(
                      controller: scrollController,
                      thumbVisibility: true, // 스크롤바 항상 표시
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        itemCount: regions.length,
                        itemBuilder: (context, index) {
                          final bool isSelected = selectedIndex == index;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedIndex = index;
                              });
                              _removeOverlay();
                            },
                            child: Container(
                              width: double.infinity,
                              height: 46,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? selectedMenuColor.withOpacity(0.25)
                                    : white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                regions[index], // 드롭다운엔 풀네임 표시
                                style: const TextStyle(
                                  color: primaryBlue,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
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
                    // 지역 선택 버튼 (Overlay 기반 드롭다운)
                    GestureDetector(
                      key: _regionButtonKey,
                      onTap: _showRegionOverlay,
                      child: Container(
                        height: 34,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min, // 텍스트 길이에 맞게 유동적으로
                          children: [
                            Text(
                              // 버튼엔 한국어 정식 명칭만 표시, 미선택 시 전체
                              selectedIndex == null
                                  ? AppLanguage.t('region_all')
                                  : regionLabels[selectedIndex!],
                              style: const TextStyle(
                                color: primaryBlue,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 2),
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