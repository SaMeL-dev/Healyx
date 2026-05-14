import 'package:flutter/material.dart';
import 'package:healyx_app/app_language.dart';

import 'find_hospital_result.dart';
import 'service/hospital_recommend_service.dart';
import 'service/location_service.dart';

class FindHospitalLoading extends StatefulWidget {
  final String symptom;
  final int riskLevel;
  final String sortBy;

  const FindHospitalLoading({
    super.key,
    required this.symptom,
    required this.riskLevel,
    this.sortBy = 'recommend',
  });

  @override
  State<FindHospitalLoading> createState() => _FindHospitalLoadingState();
}

class _FindHospitalLoadingState extends State<FindHospitalLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    _requestHospitalRecommend();
  }

  Future<void> _requestHospitalRecommend() async {
    try {
      debugPrint('1. 병원 추천 시작');

      // 1. 현재 위치 가져오기
      debugPrint('2. 위치 조회 시작');
      final position = await LocationService.getCurrentPosition();
      debugPrint('3. 위치 조회 완료: ${position.latitude}, ${position.longitude}');

      // 2. 실제 병원 추천 API 호출
      debugPrint('4. 병원 추천 API 호출 시작');
      final response = await HospitalRecommendService.recommendHospitals(
        symptom: widget.symptom,
        latitude: position.latitude,
        longitude: position.longitude,
        riskLevel: widget.riskLevel,
        sortBy: widget.sortBy,
      );
      debugPrint('5. 병원 추천 API 호출 완료');

      if (!mounted) return;

      // 3. 결과 화면으로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => FindHospitalResultScreen(
            recommendResponse: response,
            symptom: widget.symptom,
            riskLevel: widget.riskLevel,
            latitude: position.latitude,
            longitude: position.longitude,
            sortBy: widget.sortBy,
          ),
        ),
      );
    } catch (e) {
      debugPrint('병원 추천 오류: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );

      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double progress = (_controller.value + index * 0.18) % 1.0;
        final bool isActive = progress > 0.15 && progress < 0.45;

        return Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF2260FF)
                : const Color(0xFF9FC1FF),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Color(0xFF2260FF),
                      size: 22,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        AppLanguage.t('find_hospital'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2260FF),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            const Spacer(),

            Text(
              AppLanguage.t('hospital_searching'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2260FF),
              ),
            ),

            const SizedBox(height: 6),

            Text(
              AppLanguage.t('please_wait'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2260FF),
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: 40,
              height: 40,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDot(0),
                      _buildDot(1),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDot(2),
                      _buildDot(3),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}