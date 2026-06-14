import 'dart:async';
import 'package:flutter/material.dart';

import '../../services/location_service.dart';

class LiveCommuteScreen extends StatefulWidget {
  final String dungeonGrade;
  final String characterName;
  final String jobClass;
  final double destinationLat;
  final double destinationLng;
  final String destinationName;

  const LiveCommuteScreen({
    super.key,
    required this.dungeonGrade,
    required this.characterName,
    required this.jobClass,
    required this.destinationLat,
    required this.destinationLng,
    required this.destinationName,
  });

  @override
  State<LiveCommuteScreen> createState() => _LiveCommuteScreenState();
}

class _LiveCommuteScreenState extends State<LiveCommuteScreen>
    with TickerProviderStateMixin {
  final LocationService _locationService = LocationService();
  StreamSubscription<LocationUpdate>? _locationSub;

  LocationUpdate? _lastUpdate;
  int _expGained = 0;
  int _stationsCleared = 0;
  bool _isTracking = false;
  bool _hasArrived = false;

  late AnimationController _walkController;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  Timer? _expTimer;

  @override
  void initState() {
    super.initState();

    _walkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    _startTracking();
  }

  Future<void> _startTracking() async {
    final success = await _locationService.startTracking(
      destinationLat: widget.destinationLat,
      destinationLng: widget.destinationLng,
    );

    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('위치 권한이 필요합니다'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    setState(() => _isTracking = true);

    _locationSub = _locationService.updates.listen((update) {
      setState(() => _lastUpdate = update);

      // 도착 체크
      if (_locationService.hasArrived() && !_hasArrived) {
        _onArrived();
      }
    });

    // 매 30초마다 경험치 획득
    _expTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_lastUpdate != null && _lastUpdate!.mode != TransportMode.stationary) {
        setState(() {
          _expGained += _expPerTick(_lastUpdate!.mode);
        });
        _bounceController.forward(from: 0);
      }
    });
  }

  int _expPerTick(TransportMode mode) {
    switch (mode) {
      case TransportMode.walking:
        return 15;
      case TransportMode.bicycle:
        return 20;
      case TransportMode.bus:
        return 10;
      case TransportMode.subway:
        return 12;
      case TransportMode.stationary:
        return 0;
    }
  }

  void _onArrived() {
    setState(() => _hasArrived = true);
    _expTimer?.cancel();
    _locationService.stopTracking();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('🎉 보스 클리어!', style: TextStyle(fontSize: 24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${widget.destinationName} 도착!'),
            const SizedBox(height: 16),
            Text('+$_expGained EXP',
                style: const TextStyle(fontSize: 28, color: Colors.amberAccent, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, _expGained);
            },
            child: const Text('결과 확인'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _walkController.dispose();
    _bounceController.dispose();
    _locationSub?.cancel();
    _expTimer?.cancel();
    _locationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: Text('${widget.destinationName}까지'),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // 상단: 이동 상태
          _buildStatusHeader(),
          // 중앙: 캐릭터 애니메이션
          Expanded(child: _buildCharacterView()),
          // 하단: 진행률
          _buildProgressBar(),
        ],
      ),
    );
  }

  Widget _buildStatusHeader() {
    final mode = _lastUpdate?.mode ?? TransportMode.stationary;
    final speed = (_lastUpdate?.speed ?? 0) * 3.6; // km/h

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // 이동수단 아이콘
          Text(LocationService.modeEmoji(mode), style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocationService.modeAction(mode),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${speed.toStringAsFixed(1)} km/h',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ],
            ),
          ),
          // EXP 카운터
          ScaleTransition(
            scale: _bounceAnimation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amberAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '+$_expGained EXP',
                style: const TextStyle(
                  color: Colors.amberAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterView() {
    final mode = _lastUpdate?.mode ?? TransportMode.stationary;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 캐릭터 모션
          AnimatedBuilder(
            animation: _walkController,
            builder: (_, __) {
              return Transform.translate(
                offset: Offset(
                  0,
                  mode == TransportMode.stationary ? 0 : _walkController.value * 8 - 4,
                ),
                child: _buildCharacterSprite(mode),
              );
            },
          ),
          const SizedBox(height: 24),
          // 거리 정보
          if (_lastUpdate != null) ...[
            Text(
              '남은 거리: ${(_lastUpdate!.distanceToEnd / 1000).toStringAsFixed(1)} km',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              widget.characterName,
              style: TextStyle(color: Colors.grey[400]),
            ),
          ] else ...[
            const Text('GPS 신호 수신 중...'),
            const SizedBox(height: 8),
            const CircularProgressIndicator(),
          ],
        ],
      ),
    );
  }

  Widget _buildCharacterSprite(TransportMode mode) {
    String emoji;
    double size;

    switch (mode) {
      case TransportMode.walking:
        emoji = '🚶';
        size = 80;
      case TransportMode.bicycle:
        emoji = '🚴';
        size = 80;
      case TransportMode.subway:
        emoji = '🚇';
        size = 80;
      case TransportMode.bus:
        emoji = '🚌';
        size = 80;
      case TransportMode.stationary:
        emoji = '🧍';
        size = 80;
    }

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _modeColor(mode).withValues(alpha: 0.2),
        border: Border.all(color: _modeColor(mode), width: 3),
      ),
      child: Center(
        child: Text(emoji, style: TextStyle(fontSize: size)),
      ),
    );
  }

  Color _modeColor(TransportMode mode) {
    switch (mode) {
      case TransportMode.walking:
        return Colors.green;
      case TransportMode.bicycle:
        return Colors.lightBlue;
      case TransportMode.subway:
        return Colors.purple;
      case TransportMode.bus:
        return Colors.orange;
      case TransportMode.stationary:
        return Colors.grey;
    }
  }

  Widget _buildProgressBar() {
    final progress = _lastUpdate?.progress ?? 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('🏠 출발'),
              Text('${(progress * 100).toInt()}%'),
              Text('🏢 ${widget.destinationName}'),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[800],
              color: const Color(0xFF6C5CE7),
              minHeight: 12,
            ),
          ),
          if (!_isTracking)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('위치 추적 시작 중...', style: TextStyle(color: Colors.grey)),
            ),
        ],
      ),
    );
  }
}
