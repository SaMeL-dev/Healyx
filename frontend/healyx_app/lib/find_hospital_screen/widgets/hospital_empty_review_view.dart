// 병원 리뷰가 없는 경우 나타나는 뷰
// 첫번째 리뷰를 써보세요. 텍스트와 함께 드래그 가능한 시트 형태로 나타남
import 'package:flutter/material.dart';
import 'package:healyx_app/app_language.dart'; // 추가

class HospitalEmptyReviewView extends StatelessWidget {
  const HospitalEmptyReviewView({
    super.key,
    required this.lightBlue,
    required this.mainBlue,
    required this.onWriteReview,
  });

  final Color lightBlue;
  final Color mainBlue;
  final VoidCallback onWriteReview;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.48,
      minChildSize: 0.34,
      maxChildSize: 0.88,
      builder: (context, controller) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: lightBlue,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(22),
            ),
          ),
          child: ListView(
            controller: controller,
            children: [
              const SizedBox(height: 14),
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6E6E6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              SizedBox(
                height: 280,
                child: Center(
                  child: Text(
                    AppLanguage.t('hospital_first_review_prompt'), // '첫번째 리뷰를 써보세요.'
                    style: TextStyle(
                      color: mainBlue,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}