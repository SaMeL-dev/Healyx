class HospitalRecommendResponse {
  final bool success;
  final HospitalRecommendData? data;
  final String? errorCode;
  final String? message;

  HospitalRecommendResponse({
    required this.success,
    required this.data,
    required this.errorCode,
    required this.message,
  });

  factory HospitalRecommendResponse.fromJson(Map<String, dynamic> json) {
    return HospitalRecommendResponse(
      success: _asBool(json['success']),
      data: json['data'] is Map<String, dynamic>
          ? HospitalRecommendData.fromJson(json['data'])
          : null,
      errorCode: _asString(json['errorCode']),
      message: _asString(json['message']),
    );
  }
}

class HospitalRecommendData {
  final String? departmentCode;
  final String? departmentName;
  final String? icd10Code;
  final List<RecommendedHospital> hospitals;
  final int totalCount;
  final bool hasResult;
  final String? emptyReason;

  HospitalRecommendData({
    required this.departmentCode,
    required this.departmentName,
    required this.icd10Code,
    required this.hospitals,
    required this.totalCount,
    required this.hasResult,
    required this.emptyReason,
  });

  factory HospitalRecommendData.fromJson(Map<String, dynamic> json) {
    final hospitalList = json['hospitals'];

    return HospitalRecommendData(
      departmentCode: _asString(json['departmentCode']),
      departmentName: _asString(json['departmentName']),
      icd10Code: _asString(json['icd10Code']),
      hospitals: hospitalList is List
          ? hospitalList
          .whereType<Map<String, dynamic>>()
          .map(RecommendedHospital.fromJson)
          .toList()
          : [],
      totalCount: _asInt(json['totalCount']) ?? 0,
      hasResult: _asBool(json['hasResult']),
      emptyReason: _asString(json['emptyReason']),
    );
  }
}

class RecommendedHospital {
  final String? ykiho;
  final String hospitalName;
  final String address;
  final String? telephone;
  final double longitude;
  final double latitude;
  final double distance;
  final String? clCd;
  final String? hospitalType;
  final String? sidoCd;
  final String? sidoCdNm;
  final bool foreignCertified;

  /// 게스트 사용자는 비용 필드가 null로 내려올 수 있으므로 nullable 처리
  final int? minCost;
  final int? maxCost;

  final String? visitType;
  final String? costUnavailableReason;

  RecommendedHospital({
    required this.ykiho,
    required this.hospitalName,
    required this.address,
    required this.telephone,
    required this.longitude,
    required this.latitude,
    required this.distance,
    required this.clCd,
    required this.hospitalType,
    required this.sidoCd,
    required this.sidoCdNm,
    required this.foreignCertified,
    required this.minCost,
    required this.maxCost,
    required this.visitType,
    required this.costUnavailableReason,
  });

  factory RecommendedHospital.fromJson(Map<String, dynamic> json) {
    return RecommendedHospital(
      ykiho: _asString(json['ykiho']),
      hospitalName: _asString(json['hospitalName']) ?? '',
      address: _asString(json['address']) ?? '',
      telephone: _asString(json['telephone']),
      longitude: _asDouble(json['longitude']) ?? 0.0,
      latitude: _asDouble(json['latitude']) ?? 0.0,
      distance: _asDouble(json['distance']) ?? 0.0,
      clCd: _asString(json['clCd']),
      hospitalType: _asString(json['hospitalType']),
      sidoCd: _asString(json['sidoCd']),
      sidoCdNm: _asString(json['sidoCdNm']),
      foreignCertified: _asBool(json['foreignCertified']),
      minCost: _asInt(json['minCost']),
      maxCost: _asInt(json['maxCost']),
      visitType: _asString(json['visitType']),
      costUnavailableReason: _asString(json['costUnavailableReason']),
    );
  }

  bool get hasCost => minCost != null && maxCost != null;
}

String? _asString(dynamic value) {
  if (value == null) return null;
  return value.toString();
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

bool _asBool(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true';
  return false;
}