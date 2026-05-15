// 병원 찾기 결과 화면
// API 응답으로 받은 병원 목록을 카드와 지도에 표시함
// 로그인/비로그인 상태에 따라 의료비 표시가 달라질 수 있음

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:healyx_app/app_language.dart';
import 'package:latlong2/latlong.dart';

import '../services/auth_service.dart';
import 'find_hospital_detail.dart';
import 'model/hospital_recommend_response.dart';
import 'service/hospital_recommend_service.dart';

class FindHospitalResultScreen extends StatefulWidget {
  final HospitalRecommendResponse recommendResponse;
  final String symptom;
  final int riskLevel;
  final double latitude;
  final double longitude;
  final String sortBy;

  const FindHospitalResultScreen({
    super.key,
    required this.recommendResponse,
    required this.symptom,
    required this.riskLevel,
    required this.latitude,
    required this.longitude,
    required this.sortBy,
  });

  @override
  State<FindHospitalResultScreen> createState() =>
      _FindHospitalResultScreenState();
}

class _FindHospitalResultScreenState extends State<FindHospitalResultScreen> {
  bool isLoggedIn = false;
  bool isCheckingLogin = true;
  bool showLoginGuide = false;
  bool isRefreshingSort = false;

  late HospitalRecommendResponse recommendResponse;
  late String selectedSortBy;

  final Color mainBlue = const Color(0xFF2260FF);
  final Color cardColor = const Color(0xFFCAD6FF);
  final Color mapBgColor = const Color(0xFFECF1FF);
  final Color grayText = const Color(0xFF5B5B5B);

  List<RecommendedHospital> get hospitals {
    return recommendResponse.data?.hospitals ?? [];
  }

  List<RecommendedHospital> get validMapHospitals {
    return hospitals.where(_hasValidCoordinate).toList();
  }

  @override
  void initState() {
    super.initState();
    recommendResponse = widget.recommendResponse;
    selectedSortBy = widget.sortBy;
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

  Future<void> _changeSort(String sortBy) async {
    if (selectedSortBy == sortBy || isRefreshingSort) return;

    final previousSortBy = selectedSortBy;

    setState(() {
      selectedSortBy = sortBy;
      isRefreshingSort = true;
      showLoginGuide = false;
    });

    try {
      final response = await HospitalRecommendService.recommendHospitals(
        symptom: widget.symptom,
        latitude: widget.latitude,
        longitude: widget.longitude,
        riskLevel: widget.riskLevel,
        sortBy: sortBy,
      );

      if (!mounted) return;

      setState(() {
        recommendResponse = response;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        selectedSortBy = previousSortBy;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isRefreshingSort = false;
      });
    }
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
                Navigator.pop(context);
              },
              icon: Icon(Icons.arrow_back_ios_new, color: mainBlue, size: 21),
            ),
          ),
          Center(
            child: Text(
              AppLanguage.t('find_hospital'),
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
    final mapHospitals = validMapHospitals;
    final center = _getMapCenter(mapHospitals);

    return Container(
      height: 430,
      width: double.infinity,
      color: mapBgColor,
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: mapHospitals.isEmpty ? 14 : 13,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.healyx_app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(widget.latitude, widget.longitude),
                    width: 44,
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.my_location,
                        color: mainBlue,
                        size: 27,
                      ),
                    ),
                  ),
                  ...mapHospitals.map(
                        (hospital) => Marker(
                      point: LatLng(hospital.latitude, hospital.longitude),
                      width: 48,
                      height: 48,
                      child: GestureDetector(
                        onTap: () {
                          _showHospitalBrief(hospital);
                        },
                        child: Icon(
                          Icons.location_on,
                          color: hospital.foreignCertified
                              ? mainBlue
                              : Colors.redAccent,
                          size: 43,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                  ),
                ],
              ),
            ],
          ),
          if (mapHospitals.isEmpty)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(235),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '지도에 표시할 병원 위치 정보가 없습니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: grayText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
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
                  if (isRefreshingSort) ...[
                    const SizedBox(height: 12),
                    const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Color(0xFF2260FF),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  if (!isLoggedIn)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            AppLanguage.t('cost_uninsured_notice'),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: mainBlue, fontSize: 10.5),
                          ),
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
                    AppLanguage.t('cost_disclaimer'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: mainBlue,
                      fontSize: 10.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (hospitals.isEmpty)
                    _buildEmptyResult()
                  else
                    ...hospitals.map((hospital) => _buildHospitalCard(hospital)),
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
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: SizedBox(
                            width: 150,
                            child: Text(
                              AppLanguage.t('cost_login_for_insured'),
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
        _sortButton(
          title: AppLanguage.t('sort_recommended'),
          sortBy: 'recommend',
        ),
        const SizedBox(width: 18),
        _sortButton(
          title: AppLanguage.t('sort_by_distance'),
          sortBy: 'distance',
        ),
      ],
    );
  }

  Widget _sortButton({
    required String title,
    required String sortBy,
  }) {
    final bool isSelected = selectedSortBy == sortBy;

    return GestureDetector(
      onTap: () {
        _changeSort(sortBy);
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

  Widget _buildEmptyResult() {
    final emptyReason = recommendResponse.data?.emptyReason;

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: Text(
          emptyReason != null && emptyReason.isNotEmpty
              ? emptyReason
              : '조건에 맞는 병원을 찾지 못했습니다.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: mainBlue,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildHospitalCard(RecommendedHospital hospital) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          if (hospital.foreignCertified)
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
                hospital.hospitalName,
                style: TextStyle(
                  color: mainBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                hospital.address,
                style: const TextStyle(fontSize: 13, color: Colors.black),
              ),
              if (hospital.distance > 0) ...[
                const SizedBox(height: 4),
                Text(
                  '거리 ${_formatDistance(hospital.distance)}',
                  style: TextStyle(
                    color: grayText,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
                              _buildCostText(hospital),
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
                          AppLanguage.t('cost_reference_note'),
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
                              hospitalName: hospital.hospitalName,
                              address: hospital.address,
                              rating: 0.0,
                              hasBadge: hospital.foreignCertified,
                              hasReview: false,
                              isLoggedIn: isLoggedIn,
                              ykiho: hospital.ykiho,
                              hospitalType: hospital.hospitalType ?? '',
                              telephone: hospital.telephone ?? '',
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
                        AppLanguage.t('hospital_detail_btn'),
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
                          '-',
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

  String _buildCostText(RecommendedHospital hospital) {
    if (hospital.hasCost) {
      final min = _formatNumber(hospital.minCost!);
      final max = _formatNumber(hospital.maxCost!);

      final template = AppLanguage.t('cost_range');

      if (template == 'cost_range') {
        return '예측 의료비  최소 ${min}원 ~ 최대 ${max}원';
      }

      return template.replaceAll('{min}', min).replaceAll('{max}', max);
    }

    final reason = hospital.costUnavailableReason;

    if (reason != null && reason.trim().isNotEmpty) {
      return reason;
    }

    return AppLanguage.t('cost_login_for_insured').replaceAll('\n', ' ');
  }

  String _formatNumber(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
    );
  }

  String _formatDistance(double distance) {
    if (distance >= 1000) {
      return '${(distance / 1000).toStringAsFixed(1)}km';
    }

    return '${distance.toStringAsFixed(0)}m';
  }

  bool _hasValidCoordinate(RecommendedHospital hospital) {
    final lat = hospital.latitude;
    final lng = hospital.longitude;

    if (lat == 0.0 && lng == 0.0) return false;
    if (lat < -90 || lat > 90) return false;
    if (lng < -180 || lng > 180) return false;

    return true;
  }

  LatLng _getMapCenter(List<RecommendedHospital> mapHospitals) {
    if (mapHospitals.isNotEmpty) {
      return LatLng(
        mapHospitals.first.latitude,
        mapHospitals.first.longitude,
      );
    }

    return LatLng(widget.latitude, widget.longitude);
  }

  void _showHospitalBrief(RecommendedHospital hospital) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(hospital.hospitalName),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}