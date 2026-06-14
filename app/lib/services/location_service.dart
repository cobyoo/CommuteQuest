import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';

enum TransportMode { walking, bicycle, subway, bus, stationary }

class LocationUpdate {
  final double latitude;
  final double longitude;
  final double speed; // m/s
  final TransportMode mode;
  final double distanceFromStart; // meters
  final double distanceToEnd; // meters
  final double progress; // 0.0 ~ 1.0

  LocationUpdate({
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.mode,
    required this.distanceFromStart,
    required this.distanceToEnd,
    required this.progress,
  });
}

class LocationService {
  StreamSubscription<Position>? _subscription;
  Position? _startPosition;
  Position? _currentPosition;
  double? _targetLat;
  double? _targetLng;
  double _totalDistance = 0;

  final _controller = StreamController<LocationUpdate>.broadcast();
  Stream<LocationUpdate> get updates => _controller.stream;

  TransportMode get currentMode => _detectMode(_currentPosition?.speed ?? 0);

  /// 이동수단 감지 (속도 기반)
  TransportMode _detectMode(double speedMs) {
    final kmh = speedMs * 3.6;
    if (kmh < 1) return TransportMode.stationary;
    if (kmh < 8) return TransportMode.walking;
    if (kmh < 28) return TransportMode.bicycle;
    if (kmh < 50) return TransportMode.bus;
    return TransportMode.subway;
  }

  /// 이동수단별 이모지
  static String modeEmoji(TransportMode mode) {
    switch (mode) {
      case TransportMode.walking:
        return '🚶';
      case TransportMode.bicycle:
        return '🚴';
      case TransportMode.subway:
        return '🚇';
      case TransportMode.bus:
        return '🚌';
      case TransportMode.stationary:
        return '⏸️';
    }
  }

  /// 이동수단별 캐릭터 모션 설명
  static String modeAction(TransportMode mode) {
    switch (mode) {
      case TransportMode.walking:
        return '걸어가는 중...';
      case TransportMode.bicycle:
        return '자전거 타는 중!';
      case TransportMode.subway:
        return '지하철 탑승 중!';
      case TransportMode.bus:
        return '버스 탑승 중!';
      case TransportMode.stationary:
        return '대기 중...';
    }
  }

  /// GPS 추적 시작
  Future<bool> startTracking({
    required double destinationLat,
    required double destinationLng,
  }) async {
    // 권한 체크
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;

    _targetLat = destinationLat;
    _targetLng = destinationLng;

    // 현재 위치 (출발점)
    _startPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    _totalDistance = _calculateDistance(
      _startPosition!.latitude,
      _startPosition!.longitude,
      destinationLat,
      destinationLng,
    );

    // 실시간 추적
    _subscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // 10m마다 업데이트
      ),
    ).listen(_onPositionUpdate);

    return true;
  }

  void _onPositionUpdate(Position position) {
    _currentPosition = position;

    final distFromStart = _calculateDistance(
      _startPosition!.latitude,
      _startPosition!.longitude,
      position.latitude,
      position.longitude,
    );

    final distToEnd = _calculateDistance(
      position.latitude,
      position.longitude,
      _targetLat!,
      _targetLng!,
    );

    final progress = _totalDistance > 0
        ? (distFromStart / _totalDistance).clamp(0.0, 1.0)
        : 0.0;

    _controller.add(LocationUpdate(
      latitude: position.latitude,
      longitude: position.longitude,
      speed: position.speed,
      mode: _detectMode(position.speed),
      distanceFromStart: distFromStart,
      distanceToEnd: distToEnd,
      progress: progress,
    ));
  }

  /// 도착 판정 (목적지 200m 이내)
  bool hasArrived() {
    if (_currentPosition == null) return false;
    final dist = _calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _targetLat!,
      _targetLng!,
    );
    return dist < 200;
  }

  /// 두 좌표 간 거리 (Haversine, meters)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) => degree * pi / 180;

  /// 추적 중지
  void stopTracking() {
    _subscription?.cancel();
    _subscription = null;
  }

  void dispose() {
    stopTracking();
    _controller.close();
  }
}
