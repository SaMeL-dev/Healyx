// 리뷰 별점 위젯
// 리뷰 검색 결과 화면과 리뷰 작성 화면에서 리뷰의 별점을 표시하는 위젯
import 'package:flutter/material.dart';

class ReviewRatingStars extends StatelessWidget {
  final int rating;
  final double size;
  final bool showScore;

  const ReviewRatingStars({
    super.key,
    required this.rating,
    this.size = 16,
    this.showScore = false,
  });

  @override
  Widget build(BuildContext context) {
    const Color mainBlue = Color(0xFF2260FF);
    const Color softBg = Color(0xFFECF1FF);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 22,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: softBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.star_border,
                color: mainBlue,
                size: size,
              ),
              if (showScore) ...[
                const SizedBox(width: 4),
                Text(
                  '$rating',
                  style: const TextStyle(
                    color: mainBlue,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}