// 리뷰 검색 결과 화면
// GET /api/reviews/hospitals/search 결과를 표시하고 병원 선택 시 상세 화면으로 이동
import 'package:flutter/material.dart';
import '../app_language.dart';
import '../find_hospital_screen/find_hospital_detail.dart';
import '../services/review_service.dart';

class ReviewSearchResultScreen extends StatefulWidget {
  final String selectedRegion;
  final String searchKeyword;

  const ReviewSearchResultScreen({
    super.key,
    required this.selectedRegion,
    required this.searchKeyword,
  });

  @override
  State<ReviewSearchResultScreen> createState() =>
      _ReviewSearchResultScreenState();
}

class _ReviewSearchResultScreenState extends State<ReviewSearchResultScreen> {
  List<HospitalSearchResult> _hospitals = [];
  bool _isLoading = true;
  bool _hasError = false;

  static const Color primaryBlue = Color(0xFF2260FF);
  static const Color cardBlue = Color(0xFFCAD6FF);

  @override
  void initState() {
    super.initState();
    _fetchHospitals();
  }

  Future<void> _fetchHospitals() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // '지역' 기본값이면 빈 문자열로 전달 (서버에서 전체 검색)
      final region =
          widget.selectedRegion == '지역' ? '' : widget.selectedRegion;

      final results = await ReviewService.searchHospitals(
        name: widget.searchKeyword.trim(),
        region: region,
      );

      if (!mounted) return;
      setState(() {
        _hospitals = results;
        _isLoading = false;
      });
    } catch (e, st) {
      debugPrint('FETCH_HOSPITALS ERROR: $e\n$st');
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  void _goToDetail(HospitalSearchResult hospital) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FindHospitalDetailScreen(
          ykiho: hospital.ykiho,
          hospitalName: hospital.hospitalName,
          address: hospital.address,
          rating: hospital.avgRating,
          hasBadge: hospital.foreignCertified,
          hasReview: hospital.reviewCount > 0,
          isLoggedIn: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // 상단 헤더
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Stack(
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
                    AppLanguage.t('review'),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: primaryBlue,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 검색 조건 표시
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _buildSearchLabel(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF7C9CFF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 결과 영역
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  String _buildSearchLabel() {
    final region =
        widget.selectedRegion == '지역' ? '' : widget.selectedRegion;
    final keyword = widget.searchKeyword.trim();
    if (region.isEmpty && keyword.isEmpty) return AppLanguage.t('review_search_all'); // '전체 검색'
    if (region.isEmpty) return '"$keyword"';
    if (keyword.isEmpty) return region;
    return '$region · "$keyword"';
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: primaryBlue),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFAABBFF), size: 48),
            const SizedBox(height: 12),
            Text(
              AppLanguage.t('review_search_error'), // '검색 중 오류가 발생했습니다.'
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _fetchHospitals,
              child: Text(
                AppLanguage.t('error_retry'), // '다시 시도'
                style: const TextStyle(color: primaryBlue),
              ),
            ),
          ],
        ),
      );
    }

    if (_hospitals.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, color: Color(0xFFAABBFF), size: 48),
            const SizedBox(height: 12),
            Text(
              AppLanguage.t('review_search_no_result'), // '검색 결과가 없습니다.'
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      itemCount: _hospitals.length,
      separatorBuilder: (_, __) => const SizedBox(height: 18),
      itemBuilder: (_, index) => _buildHospitalCard(_hospitals[index]),
    );
  }

  Widget _buildHospitalCard(HospitalSearchResult hospital) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 14, 18),
      decoration: BoxDecoration(
        color: cardBlue,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 외국인 인증 배지
          if (hospital.foreignCertified)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: primaryBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium_outlined,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 병원명
              Text(
                hospital.hospitalName,
                style: const TextStyle(
                  color: primaryBlue,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 4),

              // 주소
              Text(
                hospital.address,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  // 상세 정보 버튼
                  Expanded(
                    child: SizedBox(
                      height: 31,
                      child: ElevatedButton(
                        onPressed: () => _goToDetail(hospital),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor: const Color(0x33000000),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(
                          AppLanguage.t('hospital_detail_btn'), // '상세 정보'
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // 별점 + 리뷰 수
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    height: 31,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_border,
                          color: primaryBlue,
                          size: 15,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          hospital.avgRating > 0
                              ? hospital.avgRating.toStringAsFixed(1)
                              : '-',
                          style: const TextStyle(
                            color: primaryBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (hospital.reviewCount > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(${hospital.reviewCount})',
                            style: const TextStyle(
                              color: primaryBlue,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
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