// 리뷰 등록 시, 이미 해당 병원에 리뷰를 작성한 경우 나타나는 팝업
// 해당 병원에 이미 리뷰를 작성하셨습니다. 확인 버튼
import 'package:flutter/material.dart';
import 'package:healyx_app/app_language.dart'; 

class DuplicateReviewDialog extends StatelessWidget {
  const DuplicateReviewDialog({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF2260FF);
    const Color white = Color(0xFFFFFFFF);

    return Dialog(
      backgroundColor: const Color(0x882260FF), // 뒤 배경 반투명 파란색
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 34, 24, 28),
        decoration: BoxDecoration(
          color: white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLanguage.t('dialog_duplicate_review'), // '해당 병원에 이미 리뷰를 작성하셨습니다.'  
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                height: 1.45,
                fontWeight: FontWeight.w700,
                color: primaryBlue,
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Text(
                  AppLanguage.t('confirm'), // '확인' 
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}