// 리뷰 영수증 업로드 화면
// 리뷰 결과 목록에서 선택한 병원 정보와 함께 영수증 인증 방식을 선택하는 화면

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../app_language.dart'; 
import 'review_receipt_loading.dart';
import 'review_receipt_error.dart';

class ReviewReceiptUploadScreen extends StatefulWidget {
  // 리뷰 결과 목록에서 받아온 선택 병원 정보
  final String hospitalName;
  final String address;
  final double rating;
  final bool hasBadge;
  final bool hasReview;

  const ReviewReceiptUploadScreen({
    super.key,
    required this.hospitalName,
    required this.address,
    required this.rating,
    required this.hasBadge,
    required this.hasReview,
  });

  @override
  State<ReviewReceiptUploadScreen> createState() =>
      _ReviewReceiptUploadScreenState();
}

class _ReviewReceiptUploadScreenState extends State<ReviewReceiptUploadScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (!mounted) return;
      if (image == null) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ReviewReceiptLoadingScreen(
            isFromCamera: true,
            imagePath: image.path,
            // 영수증 인증 이후에도 선택 병원 정보를 유지하기 위해 전달(더미 데이터)
            hospitalName: widget.hospitalName,
            address: widget.address,
            rating: widget.rating,
            hasBadge: widget.hasBadge,
            hasReview: widget.hasReview,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ReviewReceiptErrorScreen(
            isCameraError: true,
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

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (!mounted) return;
      if (image == null) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ReviewReceiptLoadingScreen(
            isFromCamera: false,
            imagePath: image.path,
            // 영수증 인증 이후에도 선택 병원 정보를 유지하기 위해 전달(더미 데이터)
            hospitalName: widget.hospitalName,
            address: widget.address,
            rating: widget.rating,
            hasBadge: widget.hasBadge,
            hasReview: widget.hasReview,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ReviewReceiptErrorScreen(
            isCameraError: false,
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

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF2260FF);
    const Color cardBlue = Color(0xFFCAD6FF);
    const Color bgColor = Color(0xFFFFFFFF);
    const Color grayText = Color(0xFF767676);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
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
              const SizedBox(height: 120),
              Text(
                AppLanguage.t('review_receipt_select_method'), // '영수증 인증 방식을 선택해주세요.'
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: primaryBlue,
                ),
              ),
              const SizedBox(height: 36),
              _UploadOptionCard(
                icon: Icons.camera_alt_outlined,
                title: AppLanguage.t('review_upload_camera_title'), // '카메라 촬영'
                subtitle: AppLanguage.t('review_upload_camera_subtitle'), // '영수증을 촬영하세요'
                backgroundColor: cardBlue,
                titleColor: primaryBlue,
                subtitleColor: grayText,
                onTap: _pickFromCamera,
              ),
              const SizedBox(height: 28),
              _UploadOptionCard(
                icon: Icons.photo,
                title: AppLanguage.t('review_upload_gallery_title'), // '이미지 선택'
                subtitle: AppLanguage.t('review_upload_gallery_subtitle'), // '영수증 사진을 선택하세요'
                backgroundColor: cardBlue,
                titleColor: primaryBlue,
                subtitleColor: grayText,
                onTap: _pickFromGallery,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color backgroundColor;
  final Color titleColor;
  final Color subtitleColor;
  final VoidCallback onTap;

  const _UploadOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    required this.titleColor,
    required this.subtitleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 165,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              width: 108,
              height: 108,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 54,
                color: const Color(0xFF767676),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}