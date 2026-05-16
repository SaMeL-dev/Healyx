import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<Position> getCurrentPosition() async {
    // 1. 기기 위치 서비스가 켜져 있는지 확인
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw LocationException(
        message: '위치 서비스가 꺼져 있습니다. 위치 서비스를 켜주세요.',
      );
    }

    // 2. 현재 위치 권한 상태 확인
    LocationPermission permission = await Geolocator.checkPermission();

    // 3. 권한이 거부된 상태라면 권한 요청
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // 4. 사용자가 권한을 거부한 경우
    if (permission == LocationPermission.denied) {
      throw LocationException(
        message: '위치 권한이 거부되었습니다.',
      );
    }

    // 5. 사용자가 권한을 영구적으로 거부한 경우
    if (permission == LocationPermission.deniedForever) {
      throw LocationException(
        message: '위치 권한이 영구적으로 거부되었습니다. 앱 설정에서 위치 권한을 허용해주세요.',
      );
    }

    // 6. 현재 위치 가져오기
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }
}

class LocationException implements Exception {
  final String message;

  LocationException({
    required this.message,
  });

  @override
  String toString() => message;
}