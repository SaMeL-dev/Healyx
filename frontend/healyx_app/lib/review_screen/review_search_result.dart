// 리뷰 검색 결과 화면
// 리뷰 검색 결과 목록을 보여주는 화면
import 'package:flutter/material.dart';
import '../find_hospital_screen/find_hospital_detail.dart';
import '../constants/hospital_constants.dart'; // 👈 더미 데이터 import

class ReviewSearchResultScreen extends StatelessWidget {
  final String selectedRegion;
  final String searchKeyword;

  const ReviewSearchResultScreen({
    super.key,
    required this.selectedRegion,
    required this.searchKeyword,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF2260FF);
    const Color cardBlue = Color(0xFFCAD6FF);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: primaryBlue,
                        size: 24,
                      ),
                    ),
                  ),
                  const Text(
                    '리뷰',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: primaryBlue,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                // 👈 REVIEW_SEARCH_HOSPITALS = 저 constants 파일에서 가져온 더미 데이터
                itemCount: REVIEW_SEARCH_HOSPITALS.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 18),
                itemBuilder: (context, index) {
                  final item = REVIEW_SEARCH_HOSPITALS[index];

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
                        if (item['hasBadge'] == true)
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
                            Text(
                              item['hospitalName'],
                              style: const TextStyle(
                                color: primaryBlue,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              item['hospitalName'],
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 15,
                              ),
                            ),

                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 31,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                FindHospitalDetailScreen(
                                                  hospitalName:
                                                      item['hospitalName'],
                                                  address: item['address'],
                                                  rating:
                                                      (item['rating'] as num)
                                                          .toDouble(),
                                                  hasBadge: item['hasBadge'],
                                                  hasReview: item['hasReview'],
                                                  isLoggedIn: true,
                                                ),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryBlue,
                                        foregroundColor: Colors.white,
                                        elevation: 4,
                                        shadowColor: const Color(0x33000000),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        '상세 정보',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 10),

                                Container(
                                  width: 58,
                                  height: 31,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.star_border,
                                        color: primaryBlue,
                                        size: 15,
                                      ),
                                      if (item['rating'].toString().isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 3,
                                          ),
                                          child: Text(
                                            item['rating'].toString(),
                                            style: const TextStyle(
                                              color: primaryBlue,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
