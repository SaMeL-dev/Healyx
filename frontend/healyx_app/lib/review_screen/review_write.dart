// 리뷰 작성 화면
// 리뷰 검색 결과 화면에서 선택한 병원 정보와 함께 리뷰 작성 폼을 보여주는 화면
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../dialogs/image_attach_dialog.dart';
import '../find_hospital_screen/find_hospital_detail.dart';
import '../login_signup_screen/login_screen.dart';
import '../services/review_service.dart';
import '../services/auth_service.dart';

import '../common/common_toast.dart';
import 'package:healyx_app/app_language.dart';

class ReviewWriteScreen extends StatefulWidget {
  // 리뷰 결과 목록에서 선택한 병원 정보
  final String ykiho;
  final String hospitalName;
  final String address;
  final double rating;
  final bool hasBadge;
  final bool hasReview;

  const ReviewWriteScreen({
    super.key,
    required this.ykiho,
    required this.hospitalName,
    required this.address,
    required this.rating,
    required this.hasBadge,
    required this.hasReview,
  });

  @override
  State<ReviewWriteScreen> createState() => _ReviewWriteScreenState();
}

class _ReviewWriteScreenState extends State<ReviewWriteScreen> {
  int selectedRating = 0;
  bool showRatingError = false;
  bool _isSubmitting = false;

  final TextEditingController _reviewController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  final List<XFile> _selectedImages = [];

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  void _showImageAttachDialog() {
    showDialog(
      context: context,
      builder: (_) => ImageAttachDialog(onSelect: _pickImage),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_selectedImages.length >= 5) return;

    if (source == ImageSource.camera) {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (!mounted) return;
      if (image == null) return;

      setState(() {
        _selectedImages.add(image);
      });

      return;
    }

    final List<XFile> images = await _picker.pickMultiImage(imageQuality: 85);

    if (!mounted) return;
    if (images.isEmpty) return;

    final int remainCount = 5 - _selectedImages.length;
    final List<XFile> limitedImages = images.take(remainCount).toList();

    setState(() {
      _selectedImages.addAll(limitedImages);
    });
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitReview() async {
    if (selectedRating == 0) {
      setState(() => showRatingError = true);
      return;
    }
    if (_isSubmitting) return;

    setState(() {
      showRatingError = false;
      _isSubmitting = true;
    });

    try {
      await ReviewService.submitReview(
        ykiho: widget.ykiho,
        rating: selectedRating,
        content: _reviewController.text.trim().isEmpty
            ? null
            : _reviewController.text.trim(),
        imagePaths: _selectedImages.map((f) => f.path).toList(),
      );

      if (!mounted) return;
      CommonToast.show(context, message: AppLanguage.t('review_submitted'));

      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => FindHospitalDetailScreen(
            ykiho: widget.ykiho,
            hospitalName: widget.hospitalName,
            address: widget.address,
            rating: widget.rating,
            hasBadge: widget.hasBadge,
            hasReview: true,
            isLoggedIn: true,
          ),
        ),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      final msg = e.toString();

      if (msg.contains('not_logged_in')) {
        // 세션 만료 — 로그인 화면으로 이동
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
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => route.isFirst,
        );
      } else if (msg.contains('duplicate_review')) {
        CommonToast.show(
          context,
          message: AppLanguage.t('review_duplicate_error'),
        );
      } else {
        CommonToast.show(
          context,
          message: AppLanguage.t('review_submit_error'),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF2260FF);
    const Color lightBlue = Color(0xFFEFF2FF);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
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

              const SizedBox(height: 27),

              Text(
                widget.hospitalName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: primaryBlue,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                AppLanguage.t('review_rating_prompt'), // '이 병원 어떠셨나요? (필수)'
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final int starIndex = index + 1;
                  final bool isSelected = starIndex <= selectedRating;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedRating = starIndex;
                        showRatingError = false;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Icon(
                        isSelected ? Icons.star : Icons.star_border,
                        color: primaryBlue,
                        size: 28,
                      ),
                    ),
                  );
                }),
              ),

              if (showRatingError) ...[
                const SizedBox(height: 6),
                Text(
                  AppLanguage.t('review_rating_error'), // '별점은 필수항목 입니다'
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],

              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                height: 1.2,
                color: primaryBlue,
              ),

              const SizedBox(height: 24),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  AppLanguage.t('review_content_label'), // '내용을 작성해주세요'
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: primaryBlue,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Container(
                height: 175,
                decoration: BoxDecoration(
                  color: lightBlue,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: TextField(
                  controller: _reviewController,
                  maxLines: null,
                  expands: true,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  autocorrect: true,
                  enableSuggestions: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(18),
                    hintText: AppLanguage.t('review_content_hint'), // '리뷰 내용을 입력해주세요.'
                  ),
                ),
              ),

              const SizedBox(height: 22),

              Container(
                width: double.infinity,
                height: 1.2,
                color: primaryBlue,
              ),

              const SizedBox(height: 26),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  AppLanguage.t('review_photo_label'), // '사진 첨부 (최대 5장)'
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: primaryBlue,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                height: 176,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    if (_selectedImages.length < 5)
                      GestureDetector(
                        onTap: _showImageAttachDialog,
                        child: Container(
                          width: 123,
                          height: 176,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: lightBlue,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.add,
                              color: primaryBlue,
                              size: 36,
                            ),
                          ),
                        ),
                      ),
                    ...List.generate(_selectedImages.length, (index) {
                      return Stack(
                        children: [
                          Container(
                            width: 123,
                            height: 176,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: lightBlue,
                              borderRadius: BorderRadius.circular(16),
                              image: DecorationImage(
                                image: FileImage(
                                  File(_selectedImages[index].path),
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 20,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: const BoxDecoration(
                                  color: primaryBlue,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 34),

              SizedBox(
                width: 250,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: primaryBlue.withOpacity(0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          AppLanguage.t('review_submit'), // '등록'
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}