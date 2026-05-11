// 병원 찾기 결과 화면
// 로그인/비로그인 상태에 따라 화면이 조금 다름
// accessToken 유무를 기준으로 로그인 상태를 판단함

import 'package:flutter/material.dart';
import 'package:healyx_app/app_language.dart'; 
import 'find_hospital_detail.dart';
import 'pain_score_slide.dart';
import '../constants/hospital_constants.dart';
import '../services/auth_service.dart';

class FindHospitalResultScreen extends StatefulWidget {
  const FindHospitalResultScreen({super.key});

  @override
  State<FindHospitalResultScreen> createState() =>
      _FindHospitalResultScreenState();
}

class _FindHospitalResultScreenState extends State<FindHospitalResultScreen> {
  // accessToken 확인 전 기본값은 비로그인
  bool isLoggedIn = false;

  // 로그인 상태 확인 중 여부
  bool isCheckingLogin = true;

  // 비로그인 상태에서 물음표 클릭 시 로그인 안내 팝업 표시 여부
  bool showLoginGuide = false;

  String selectedSort = AppLanguage.t('sort_recommended'); // '추천순'

  final Color mainBlue = const Color(0xFF2260FF);
  final Color cardColor = const Color(0xFFCAD6FF);
  final Color mapBgColor = const Color(0xFFECF1FF);
  final Color grayText = const Color(0xFF5B5B5B);

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final loggedIn = await AuthService.isLoggedIn();

    if (!mounted) return;

    setState(() {
      isLoggedIn = loggedIn;
      isCheckingLogin = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isCheckingLogin) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF2260FF),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Stack(
                children: [
                  Column(
                    children: [
                      _buildMapArea(),
                      Expanded(child: Container(color: Colors.white)),
                    ],
                  ),
                  _buildBottomSheet(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 86,
      child: Stack(
        children: [
          Positioned(
            left: 8,
            top: 16,
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PainScoreSlide(),
                  ),
                );
              },
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

  Widget _buildMapArea() {
    return Container(
      height: 430,
      width: double.infinity,
      color: mapBgColor,
      child: Center(
        child: Text(
          '지도 영역',
          style: TextStyle(
            color: grayText,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.40,
      minChildSize: 0.25,
      maxChildSize: 0.86,
      builder: (context, controller) {
        return Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Stack(
            children: [
              ListView(
                controller: controller,
                children: [
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
                  const SizedBox(height: 22),
                  _buildSortRow(),
                  const SizedBox(height: 10),

                  if (!isLoggedIn)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLanguage.t('cost_uninsured_notice'), // '예측된 의료비는 건강보험 미적용 기준으로 계산되었습니다.'
                          style: TextStyle(color: mainBlue, fontSize: 10.5),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              showLoginGuide = !showLoginGuide;
                            });
                          },
                          child: Icon(Icons.info, color: mainBlue, size: 16),
                        ),
                      ],
                    ),

                  const SizedBox(height: 10),

                  Text(
                    AppLanguage.t('cost_disclaimer'), // '본 예측 비용은 통계 데이터에 기반한 참고용 수치입니다.\n정확한 의료비 산출을 위해 반드시 병원 관계자와 상담하시기 바랍니다.'
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: mainBlue,
                      fontSize: 10.5,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 12),
                  ...HOSPITAL_LIST.map((item) => _buildHospitalCard(item)),
                ],
              ),

              if (!isLoggedIn && showLoginGuide)
                Positioned(
                  right: 6,
                  top: 74,
                  child: Container(
                    width: 182,
                    padding: const EdgeInsets.fromLTRB(11, 5, 12, 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: 0,
                          top: 0,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                showLoginGuide = false;
                              });
                            },
                            child: const Text(
                              'X',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                        Padding( // 수정
                          padding: const EdgeInsets.only(top: 2),
                          child: SizedBox(
                            width: 150,
                            child: Text(
                              AppLanguage.t('cost_login_for_insured'), // '건강보험이 적용된 의료비를\n확인하려면 로그인을 해주세요'
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black87,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _sortButton(AppLanguage.t('sort_recommended')), // '추천순'
        const SizedBox(width: 18),
        _sortButton(AppLanguage.t('sort_by_distance')), // '거리순'
      ],
    );
  }

  Widget _sortButton(String title) {
    final bool isSelected = selectedSort == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedSort = title;
        });
      },
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              color: mainBlue,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 3),
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: mainBlue,
            size: 22,
          ),
        ],
      ),
    );
  }

  Widget _buildHospitalCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          if (item['foreign'] == true)
            Positioned(
              right: 0,
              top: 0,
              child: CircleAvatar(
                radius: 15,
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
                item['hospitalName'],
                style: TextStyle(
                  color: mainBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                item['address'],
                style: const TextStyle(fontSize: 13, color: Colors.black),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              isLoggedIn
                                  ? '예측 의료비  최소 4000원 ~ 최대15000원'
                                  : '예측 의료비  최소 12000원 ~ 최대30000원',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: mainBlue,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          AppLanguage.t('cost_reference_note'), // '*참고용입니다'
                          style: TextStyle(
                            color: mainBlue,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FindHospitalDetailScreen(
                              hospitalName: item['hospitalName'],
                              address: item['address'],
                              rating: (item['rating'] as num).toDouble(),
                              hasBadge: item['hasBadge'] == true,
                              hasReview: item['hasReview'] == true,
                              isLoggedIn: isLoggedIn,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainBlue,
                        minimumSize: const Size.fromHeight(33),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        AppLanguage.t('hospital_detail_btn'), // '상세 정보'
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 62,
                    height: 31,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_border, color: mainBlue, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          item['rating'].toString(),
                          style: TextStyle(
                            color: mainBlue,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
