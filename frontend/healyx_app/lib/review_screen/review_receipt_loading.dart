// 리뷰 영수증 인증 로딩 화면
// 영수증 인증이 진행되는 동안 로딩 애니메이션과 함께 영수증 미리보기를 보여주는 화면
// 성공 시 리뷰 작성 화면으로 이동, 실패 시 영수증 인증 에러 화면으로 이동 (True/false로 분기)
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../app_language.dart'; 

import 'review_receipt_upload.dart';
import 'review_receipt_error.dart';
import 'review_write.dart';

class ReviewReceiptLoadingScreen extends StatefulWidget {
  final bool isFromCamera;
  final String imagePath;

  // 리뷰 결과 목록에서 선택한 병원 정보
  final String hospitalName;
  final String address;
  final double rating;
  final bool hasBadge;
  final bool hasReview;

  const ReviewReceiptLoadingScreen({
    super.key,
    required this.isFromCamera,
    required this.imagePath,
    required this.hospitalName,
    required this.address,
    required this.rating,
    required this.hasBadge,
    required this.hasReview,
  });

  @override
  State<ReviewReceiptLoadingScreen> createState() =>
      _ReviewReceiptLoadingScreenState();
}

class _ReviewReceiptLoadingScreenState
    extends State<ReviewReceiptLoadingScreen> {
  Timer? _timer;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    // 퍼블리싱 테스트용 로딩
    _timer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;

      // TODO: 프론트 연동 시 토큰/API 응답값으로 교체
      // true  = 인증 성공 → 리뷰 작성 화면
      // false = 인증 실패 → 영수증 인증 에러 화면
      final bool isSuccess = true;

      if (isSuccess) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            // 성공 시 리뷰 작성 화면으로 이동
            builder: (context) => ReviewWriteScreen(
              hospitalName: widget.hospitalName,
              address: widget.address,
              rating: widget.rating,
              hasBadge: widget.hasBadge,
              hasReview: widget.hasReview,
            ),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            // 실패 시 영수증 인증 에러 화면으로 이동
           builder: (context) => ReviewReceiptErrorScreen(
            isCameraError: widget.isFromCamera,

            // 선택 병원 정보 유지
            hospitalName: widget.hospitalName,
            address: widget.address,
            rating: widget.rating,
            hasBadge: widget.hasBadge,
            hasReview: widget.hasReview,
           ),
          ),
        );
      }
    });
  }

  Future<void> _retryPickImage() async {
    _timer?.cancel();

    final XFile? image = await _picker.pickImage(
      source: widget.isFromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 85,
    );

    if (!mounted) return;

    if (image == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ReviewReceiptUploadScreen(
            hospitalName: widget.hospitalName,
            address: widget.address,
            rating: widget.rating,
            hasBadge: widget.hasBadge,
            hasReview: widget.hasReview,
          ),
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewReceiptLoadingScreen(
          isFromCamera: widget.isFromCamera,
          imagePath: image.path,
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
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF4C5BFF);
    const Color bgColor = Colors.white;
    const Color darkGray = Color(0xFF5B5959);
    const Color lightGray = Color(0xFFA1A9C4);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Center(
                child: Text(
                  AppLanguage.t('review'), // '리뷰'
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: primaryBlue,
                  ),
                ),
              ),
              const SizedBox(height: 110),
              Text(
                AppLanguage.t('review_receipt_preview'), // '영수증 미리보기'
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: primaryBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLanguage.t('review_receipt_check_image'), // '인증할 영수증 이미지를 확인해주세요.'
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: lightGray,
                ),
              ),
              const SizedBox(height: 40),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: double.infinity,
                    height: 280,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: const Color(0xFFBDBDBD),
                        width: 1,
                      ),
                    ),
                    child: Image.file(
                      File(widget.imagePath),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 56,
                            color: darkGray,
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: -14,
                    right: -14,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        // 이미지 다시 선택
                        onPressed: _retryPickImage,
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 56),
              Text(
                AppLanguage.t('review_receipt_verifying'), // '영수증을 확인중입니다...'
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: primaryBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}