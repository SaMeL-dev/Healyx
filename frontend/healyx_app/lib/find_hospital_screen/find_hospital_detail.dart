// 병원 찾기 상세 화면
// 리뷰쓰기 버튼 클릭 시 accessToken 유무로 로그인 상태를 판단함
import 'package:flutter/material.dart';
import 'package:healyx_app/app_language.dart';

import '../review_screen/review_receipt_upload.dart';
import '../review_screen/widgets/review_card.dart';
import 'widgets/hospital_empty_review_view.dart';
import 'widgets/hospital_review_header.dart';
import '../../dialogs/login_required_dialog.dart';
import '../../dialogs/duplicate_review_dialog.dart';
import '../services/auth_service.dart';
import '../services/review_service.dart';

class FindHospitalDetailScreen extends StatefulWidget {
  const FindHospitalDetailScreen({
    super.key,
    required this.hasReview,
    required this.hasBadge,
    required this.isLoggedIn,
    required this.hospitalName,
    required this.address,
    required this.rating,
    this.ykiho,
  });

  // true = 리뷰 목록이 있는 병원 상세 화면
  // false = 리뷰가 없는 병원 상세 화면
  final bool hasReview;

  // true = 병원 인증 배지 표시
  // false = 병원 인증 배지 숨김
  final bool hasBadge;

  // true = 로그인한 사용자
  // false = 비로그인 사용자
  // 현재 리뷰쓰기 버튼 권한은 AuthService.isLoggedIn()으로 판단함
  final bool isLoggedIn;

  final String hospitalName;
  final String address;
  final double rating;

  // HIRA 암호화 요양기호 — API 연동 시 병원 리뷰 조회에 사용
  final String? ykiho;

  @override
  State<FindHospitalDetailScreen> createState() =>
      _FindHospitalDetailScreenState();
}

class _FindHospitalDetailScreenState extends State<FindHospitalDetailScreen> {
  static const Color mainBlue = Color(0xFF2260FF);
  static const Color lightBlue = Color(0xFFCAD6FF);
  static const Color softBg = Color(0xFFECF1FF);
  static const Color lineColor = Color(0xFF4378FF);
  static const Color greyColor = Color(0xFF7E7E7E);

  HospitalDetailData? _detail;
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    if (widget.ykiho != null && widget.ykiho!.isNotEmpty) {
      _isLoading = true; // initState에서 직접 대입 → 첫 build 시 로딩 상태로 시작
      _fetchDetail();
    }
  }

  Future<void> _fetchDetail() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final detail = await ReviewService.getHospitalDetail(widget.ykiho!);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('FETCH_HOSPITAL_DETAIL ERROR: $e');
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleWriteReview() async {
    final loggedIn = await AuthService.isLoggedIn();

    if (!mounted) return;

    // 비로그인 사용자면 로그인 팝업 실행
    if (!loggedIn) {
      showDialog(
        context: context,
        builder: (_) => const LoginRequiredDialog(),
      );
      return;
    }

    // API 응답의 myReviewExists로 중복 리뷰 여부 판단
    final bool hasAlreadyReviewed = _detail?.myReviewExists ?? false;

    if (hasAlreadyReviewed) {
      showDialog(
        context: context,
        barrierColor: const Color.fromRGBO(34, 96, 255, 0.54),
        builder: (_) => const DuplicateReviewDialog(),
      );
      return;
    }

    Navigator.push(
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHospitalSummary(),
                          const SizedBox(height: 26),
                          _buildHospitalInfo(),
                          const SizedBox(height: 18),

                          // 리뷰 갯수 + 리뷰쓰기 버튼 (고정)
                          HospitalReviewHeader(
                            hasReview: _hasReviews,
                            reviewCount: _detail?.reviewCount ?? 0,
                            mainBlue: mainBlue,
                            onPressed: _handleWriteReview,
                          ),

                          const SizedBox(height: 420),
                        ],
                      ),
                    ),
                  ),

                  // 리뷰 영역 — 로딩/에러/빈 상태 처리
                  if (_isLoading)
                    const Positioned.fill(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: SizedBox(
                          height: 200,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: mainBlue,
                            ),
                          ),
                        ),
                      ),
                    )
                  else if (_hasReviews)
                    _buildReviewSheet()
                  else
                    HospitalEmptyReviewView(
                      lightBlue: lightBlue,
                      mainBlue: mainBlue,
                      onWriteReview: _handleWriteReview,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      height: 86,
      child: Stack(
        children: [
          Positioned(
            left: 8,
            top: 16,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back_ios_new, color: mainBlue, size: 21),
            ),
          ),
          Center(
            child: Text(
              AppLanguage.t('find_hospital'), // '병원 찾기'
              style: TextStyle(
                color: mainBlue,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHospitalSummary() {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          if (widget.hasBadge)
            Positioned(
              right: 0,
              top: 0,
              child: CircleAvatar(
                radius: 16,
                backgroundColor: mainBlue,
                child: const Icon(
                  Icons.workspace_premium_outlined,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.hospitalName,
                style: TextStyle(
                  color: mainBlue,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.address,
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
              const SizedBox(height: 10),
              _buildRatingChip(_detail?.averageRating ?? widget.rating),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingChip(double rating) {
    final String ratingText = rating.toStringAsFixed(1);

    return Container(
      width: 62,
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: lightBlue,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_border, color: mainBlue, size: 14),
          const SizedBox(width: 3),
          Text(
            ratingText,
            style: TextStyle(
              color: mainBlue,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHospitalInfo() {
    final type = _detail?.hospitalType ?? '';
    final phone = _detail?.telephone ?? '';
    return Column(
      children: [
        const Divider(color: lineColor, thickness: 1),
        const SizedBox(height: 16),
        if (type.isNotEmpty) ...[
          _infoRow(AppLanguage.t('hospital_type_label'), type),
          const SizedBox(height: 16),
        ],
        if (phone.isNotEmpty) ...[
          _infoRow(AppLanguage.t('hospital_phone_label'), phone),
          const SizedBox(height: 18),
        ],
        const Divider(color: lineColor, thickness: 1),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: mainBlue,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // API 리뷰 목록 → ReviewCard에 필요한 ReviewData로 변환
  List<ReviewData> get _reviewDataList =>
      (_detail?.reviews ?? []).map((item) => ReviewData(
            nickname: item.nickname,
            content: item.content,
            rating: item.rating,
            imageUrls: item.imageUrls,
          )).toList();

  bool get _hasReviews =>
      _detail != null ? _detail!.reviews.isNotEmpty : widget.hasReview;

  Widget _buildReviewSheet() {
    final reviews = _reviewDataList;
    return DraggableScrollableSheet(
      initialChildSize: 0.48,
      minChildSize: 0.34,
      maxChildSize: 0.88,
      builder: (context, controller) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
          decoration: const BoxDecoration(
            color: lightBlue,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: ListView.separated(
            controller: controller,
            itemCount: reviews.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, index) {
              if (index == 0) {
                return Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6E6E6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              }
              return ReviewCard(review: reviews[index - 1]);
            },
          ),
        );
      },
    );
  }
}
