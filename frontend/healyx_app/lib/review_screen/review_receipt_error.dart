// 리뷰 영수증 인식 실패 화면
// 영수증 인식이 실패했을 때 사용자에게 안내 메시지를 보여주는 화면
// 성공/실패 여부에 따라 '다시 촬영하기' 또는 '다시 선택하기' 버튼으로 분기 (true/false -> 퍼블리싱 테스트용)

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../app_language.dart'; 
import 'review_receipt_loading.dart';

class ReviewReceiptErrorScreen extends StatefulWidget {
  final bool isCameraError;

  // 이전 화면에서 전달받은 선택 병원 정보
  final String hospitalName;
  final String address;
  final double rating;
  final bool hasBadge;
  final bool hasReview;

  const ReviewReceiptErrorScreen({
    super.key,
    required this.isCameraError,
    required this.hospitalName,
    required this.address,
    required this.rating,
    required this.hasBadge,
    required this.hasReview,
  });

  @override
  State<ReviewReceiptErrorScreen> createState() =>
      _ReviewReceiptErrorScreenState();
}

class _ReviewReceiptErrorScreenState extends State<ReviewReceiptErrorScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _retryPickImage() async {
    final XFile? image = await _picker.pickImage(
      source: widget.isCameraError ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 85,
    );

    if (!mounted) return;
    if (image == null) return;

    // 다시 촬영/선택한 이미지를 로딩 화면으로 전달
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewReceiptLoadingScreen(
          isFromCamera: widget.isCameraError,
          imagePath: image.path,

          // 병원 정보 유지
          hospitalName: widget.hospitalName,
          address: widget.address,
          rating: widget.rating,
          hasBadge: widget.hasBadge,
          hasReview: widget.hasReview,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF4C5BFF);
    const Color bgColor = Color(0xFFFFFFFF);

    final String guideText = widget.isCameraError
        ? AppLanguage.t('review_error_guide_camera') // '사진이 흐리거나 일부만 촬영된 경우\n정확한 인식이 어려울 수 있어요.'
        : AppLanguage.t('review_error_guide_gallery'); // '사진이 흐리거나 전체가 아닌 일부의 이미지인\n경우 정확한 인식이 어려울 수 있어요.'

    final String buttonText =
        widget.isCameraError ? AppLanguage.t('review_retry_camera') : AppLanguage.t('review_retry_gallery'); // '다시 선택하기'

    return Scaffold(
      backgroundColor: bgColor,
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
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppLanguage.t('review_recognition_failed'), // '인식에\n실패하였습니다.' 
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        height: 1.5,
                        fontWeight: FontWeight.w700,
                        color: primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      guideText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                        color: primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 36),
                    SizedBox(
                      width: 200,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _retryPickImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 6,
                          shadowColor: const Color(0x33000000),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                        child: Text(
                          buttonText,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
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