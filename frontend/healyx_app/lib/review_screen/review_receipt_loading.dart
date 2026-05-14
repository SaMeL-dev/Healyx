// 리뷰 영수증 인증 로딩 화면
// POST /api/reviews/ocr 호출 → 성공 시 리뷰 작성, 실패 시 에러 화면으로 이동
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../app_language.dart';

import '../login_signup_screen/login_screen.dart';
import '../services/auth_service.dart';
import '../services/review_service.dart';
import 'review_receipt_upload.dart';
import 'review_receipt_error.dart';
import 'review_write.dart';

class ReviewReceiptLoadingScreen extends StatefulWidget {
  final bool isFromCamera;
  final String imagePath;

  // 리뷰 결과 목록에서 선택한 병원 정보
  final String ykiho;
  final String hospitalName;
  final String address;
  final double rating;
  final bool hasBadge;
  final bool hasReview;

  const ReviewReceiptLoadingScreen({
    super.key,
    required this.isFromCamera,
    required this.imagePath,
    required this.ykiho,
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
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _verifyReceipt();
  }

  Future<void> _verifyReceipt() async {
    bool isSuccess = false;
    bool isSessionExpired = false;
    try {
      isSuccess = await ReviewService.verifyReceipt(
        widget.ykiho,
        widget.imagePath,
      );
    } catch (e) {
      debugPrint('VERIFY_RECEIPT ERROR: $e');
      if (e.toString().contains('not_logged_in')) {
        isSessionExpired = true;
      }
      isSuccess = false;
    }

    if (!mounted) return;

    // 세션 만료 — 로그인 유도 다이얼로그 표시 후 로그인 화면으로 이동
    if (isSessionExpired) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: Text(
            AppLanguage.t('session_expired_title'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2260FF),
            ),
          ),
          content: Text(
            AppLanguage.t('session_expired_message'),
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                AppLanguage.t('confirm'),
                style: const TextStyle(color: Color(0xFF2260FF)),
              ),
            ),
          ],
        ),
      );
      if (!mounted) return;
      await AuthService.clearLocalCredentials();
      if (!mounted) return;
      // 모든 리뷰 화면을 닫고 로그인 화면으로 이동
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => route.isFirst,
      );
      return;
    }

    if (isSuccess) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ReviewWriteScreen(
            ykiho: widget.ykiho,
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
          builder: (context) => ReviewReceiptErrorScreen(
            isCameraError: widget.isFromCamera,
            ykiho: widget.ykiho,
            hospitalName: widget.hospitalName,
            address: widget.address,
            rating: widget.rating,
            hasBadge: widget.hasBadge,
            hasReview: widget.hasReview,
          ),
        ),
      );
    }
  }

  Future<void> _retryPickImage() async {
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
            ykiho: widget.ykiho,
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
          ykiho: widget.ykiho,
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