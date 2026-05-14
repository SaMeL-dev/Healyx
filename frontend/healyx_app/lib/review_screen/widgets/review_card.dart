// 리뷰 카드 위젯
// 리뷰 검색 결과 화면에서 각 리뷰 항목을 카드 형태로 보여주는 위젯
// 리뷰 작성자 닉네임, 리뷰 내용, 별점, 이미지 유무 등을 표시
import 'package:flutter/material.dart';

import 'review_image_slider.dart';
import 'review_rating_stars.dart';

class ReviewData {
  final String nickname;
  final String content;
  final int rating;
  final List<String> imageUrls;

  ReviewData({
    required this.nickname,
    required this.content,
    required this.rating,
    this.imageUrls = const [],
  });
}

class ReviewCard extends StatelessWidget {
  final ReviewData review;

  const ReviewCard({
    super.key,
    required this.review,
  });

  @override
  Widget build(BuildContext context) {
    const Color mainBlue = Color(0xFF2260FF);
    const Color softBg = Color(0xFFECF1FF);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.12),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: softBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              review.nickname,
              style: const TextStyle(
                color: mainBlue,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          const SizedBox(height: 6),

          Text(
            review.content,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 11,
              height: 1.35,
            ),
          ),

          const SizedBox(height: 8),

          ReviewRatingStars(
            rating: review.rating,
            size: 14,
            showScore: true,
          ),

          if (review.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            ReviewImageSlider(
              imageUrls: review.imageUrls,
            ),
          ],
        ],
      ),
    );
  }
}