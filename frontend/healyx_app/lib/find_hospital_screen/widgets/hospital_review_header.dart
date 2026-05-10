// 병원 리뷰 헤더 (리뷰가 몇 개 쓰여있는지 보여주고, 리뷰쓰기 버튼이 있는 헤더)
// 리뷰 개수와 리뷰쓰기 버튼이 포함된 헤더
import 'package:flutter/material.dart';
import 'package:healyx_app/app_language.dart'; // 수정

class HospitalReviewHeader extends StatelessWidget {
  const HospitalReviewHeader({
    super.key,
    required this.hasReview,
    required this.reviewCount,
    required this.mainBlue,
    required this.onPressed,
  });

  final bool hasReview;
  final int reviewCount;
  final Color mainBlue;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            AppLanguage.t('hospital_review_count').replaceAll('{count}', hasReview ? '$reviewCount' : '0'), // '{count}개의 리뷰'
            style: const TextStyle(
              color: Colors.black,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 18),
          SizedBox(
            height: 38,
            width: 104,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: mainBlue,
                elevation: 2,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(
                AppLanguage.t('hospital_write_review'), // '리뷰쓰기'
                maxLines: 1,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}