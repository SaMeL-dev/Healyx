// 병원 찾기 상세 화면
// 로그인에 따라 리뷰쓰기 버튼 클릭 시 로그인 팝업 또는 리뷰 작성 화면으로 분기 (테스트용)
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

class FindHospitalDetailScreen extends StatefulWidget {
  const FindHospitalDetailScreen({
    super.key,
    required this.hasReview,
    required this.hasBadge,
    required this.isLoggedIn,
    required this.hospitalName,
    required this.address,
    required this.rating,
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

  @override
  State<FindHospitalDetailScreen> createState() =>
      _FindHospitalDetailScreenState();
}

class _FindHospitalDetailScreenState extends State<FindHospitalDetailScreen> {
  final Color mainBlue = const Color(0xFF2260FF);
  final Color lightBlue = const Color(0xFFCAD6FF);
  final Color softBg = const Color(0xFFECF1FF);
  final Color lineColor = const Color(0xFF4378FF);
  final Color greyColor = const Color(0xFF7E7E7E);

  // TODO: 현재는 UI 확인용 더미 데이터
  // 추후 API 연동 시 서버 리뷰 목록으로 교체
  final List<ReviewData> _reviewList = [
    ReviewData(
      nickname: '닉네임123',
      content: '의사 선생님이 친절하고 시설이 깨끗해요',
      rating: '5',
      hasImages: false,
    ),
    ReviewData(
      nickname: '닉네임456',
      content:
          '무엇보다 병원은 진료 자체는 매우 만족스러웠습니다. 제공받은 안내도 친절했고, 직원분들도 외국인 환자에게 설명을 잘해줬습니다.',
      rating: '3',
      hasImages: true,
      imageCount: 4,
    ),
    ReviewData(
      nickname: '닉네임789',
      content: '대기 시간이 조금 있었지만 안내가 잘 되어 있어서 이용하기 편했습니다.',
      rating: '4',
      hasImages: false,
    ),
    ReviewData(
      nickname: '닉네임101',
      content: '접수부터 진료까지 전반적으로 깔끔했고, 필요한 설명을 차분하게 해주셔서 좋았습니다.',
      rating: '5',
      hasImages: true,
      imageCount: 3,
    ),
    ReviewData(
      nickname: '닉네임202',
      content: '시설이 깨끗하고 위치도 찾기 쉬웠습니다. 다음에도 이용할 것 같아요.',
      rating: '4',
      hasImages: false,
    ),
  ];

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

    // TODO: 추후 병원 리뷰 작성 여부 API 응답값으로 교체
    // true = 해당 병원에 이미 리뷰 작성함 (중복 팝업)
    // false = 리뷰 작성 가능
    final bool hasAlreadyReviewed = false;

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
                            hasReview: widget.hasReview,
                            reviewCount: widget.hasReview
                                ? _reviewList.length
                                : 0,
                            mainBlue: mainBlue,
                            onPressed: _handleWriteReview,
                          ),

                          const SizedBox(height: 420),
                        ],
                      ),
                    ),
                  ),

                  // 리뷰 영역만 스크롤
                  widget.hasReview
                      ? _buildReviewSheet()
                      : HospitalEmptyReviewView(
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
              _buildRatingChip(widget.rating),
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
    return Column(
      children: [
        Divider(color: lineColor, thickness: 1),
        const SizedBox(height: 16),
        _infoRow(AppLanguage.t('hospital_type_label'), widget.hasReview ? '대학병원' : '의원'), // '병원 타입'
        const SizedBox(height: 16),
        _infoRow(AppLanguage.t('hospital_phone_label'), '02-0000-0000'), // '전화번호'
        const SizedBox(height: 18),
        Divider(color: lineColor, thickness: 1),
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

  Widget _buildReviewSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.48,
      minChildSize: 0.34,
      maxChildSize: 0.88,
      builder: (context, controller) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
          decoration: BoxDecoration(
            color: lightBlue,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: ListView.separated(
            controller: controller,
            itemCount: _reviewList.length + 1,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
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

              // 임시(더미) 리뷰 데이터 가져오기
              final review = _reviewList[index - 1];

              // review_card.dart에 만든 카드 UI 연결 부분
              // 리뷰 1개마다 카드 형태로 반복 출력됨
              return ReviewCard(review: review);
            },
          ),
        );
      },
    );
  }
}
