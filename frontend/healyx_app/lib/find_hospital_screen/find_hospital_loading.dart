import 'package:flutter/material.dart';
import 'package:healyx_app/app_language.dart';

import '../services/auth_service.dart';
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

  String? _errorMessage;

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

      final position = await _getCurrentPositionSafely();

      debugPrint('3. 위치 조회 완료: ${position.latitude}, ${position.longitude}');

      // 2. 로그인 토큰 가져오기
      // 로그인 상태면 accessToken이 들어오고, 비로그인 상태면 null이 들어옴
      final accessToken = await AuthService.getAccessToken();
      debugPrint(
        accessToken != null && accessToken.isNotEmpty
            ? '4. 로그인 토큰 확인 완료'
            : '4. 비로그인 상태로 병원 추천 요청',
      );

      // 3. 실제 병원 추천 API 호출
      debugPrint('5. 병원 추천 API 호출 시작');
      final response = await HospitalRecommendService.recommendHospitals(
        symptom: widget.symptom,
        latitude: position.latitude,
        longitude: position.longitude,
        riskLevel: widget.riskLevel,
        sortBy: widget.sortBy,
        accessToken: accessToken,
      );
      debugPrint('6. 병원 추천 API 호출 완료');

      if (!mounted) return;

      // 4. 결과 화면으로 이동
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

      setState(() {
        _errorMessage = _buildLocalizedErrorMessage(e);
      });

      // 커스텀 알림을 잠시 보여준 뒤 이전 화면으로 이동
      await Future.delayed(const Duration(milliseconds: 2300));

      if (!mounted) return;

      Navigator.pop(context);
    }
  }

  Future<dynamic> _getCurrentPositionSafely() async {
    try {
      return await LocationService.getCurrentPosition();
    } catch (e) {
      debugPrint('위치 조회 오류: $e');
      throw _HospitalLocationException(e);
    }
  }

  String _buildLocalizedErrorMessage(Object error) {
    // 위치 권한 꺼짐 / 위치 서비스 꺼짐 / 위치 조회 실패
    if (error is _HospitalLocationException) {
      return AppLanguage.t('hospital_location_error');
    }

    if (error is HospitalRecommendException) {
      if (error.statusCode == 504) {
        return AppLanguage.t('hospital_recommend_delayed');
      }

      final message = error.message.toLowerCase();

      if (_isLocationErrorText(message)) {
        return AppLanguage.t('hospital_location_error');
      }

      if (_isTimeoutText(message)) {
        return AppLanguage.t('hospital_recommend_timeout');
      }

      if (_isGatewayTimeoutText(message)) {
        return AppLanguage.t('hospital_recommend_delayed');
      }
    }

    final errorText = error.toString().toLowerCase();

    if (_isLocationErrorText(errorText)) {
      return AppLanguage.t('hospital_location_error');
    }

    if (_isGatewayTimeoutText(errorText)) {
      return AppLanguage.t('hospital_recommend_delayed');
    }

    if (_isTimeoutText(errorText)) {
      return AppLanguage.t('hospital_recommend_timeout');
    }

    return AppLanguage.t('hospital_recommend_failed');
  }

  bool _isLocationErrorText(String text) {
    return text.contains('location') ||
        text.contains('permission') ||
        text.contains('denied') ||
        text.contains('service') ||
        text.contains('위치') ||
        text.contains('권한') ||
        text.contains('거부');
  }

  bool _isTimeoutText(String text) {
    return text.contains('초과') ||
        text.contains('timeout') ||
        text.contains('time-out') ||
        text.contains('timed out');
  }

  bool _isGatewayTimeoutText(String text) {
    return text.contains('504') || text.contains('gateway');
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

  Widget _buildBottomWarningAlert() {
    final message = _errorMessage;

    if (message == null || message.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 22,
      right: 22,
      bottom: 34,
      child: SafeArea(
        top: false,
        child: AnimatedOpacity(
          opacity: 1,
          duration: const Duration(milliseconds: 180),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFFC999),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(18),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF0DC),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.priority_high_rounded,
                    color: Color(0xFFFF8A00),
                    size: 23,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Color(0xFFE46C0A),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
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

            _buildBottomWarningAlert(),
          ],
        ),
      ),
    );
  }
}

class _HospitalLocationException implements Exception {
  final Object originalError;

  const _HospitalLocationException(this.originalError);

  @override
  String toString() {
    return originalError.toString();
  }
}