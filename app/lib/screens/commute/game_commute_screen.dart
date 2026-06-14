import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class GameCommuteScreen extends StatefulWidget {
  final String dungeonGrade;
  final String characterName;

  const GameCommuteScreen({
    super.key,
    required this.dungeonGrade,
    required this.characterName,
  });

  @override
  State<GameCommuteScreen> createState() => _GameCommuteScreenState();
}

class _GameCommuteScreenState extends State<GameCommuteScreen>
    with TickerProviderStateMixin {
  late AnimationController _runController;
  late AnimationController _bgController;
  late AnimationController _cloudController;
  late AnimationController _trainController;

  int _expGained = 0;
  int _stationsPassed = 0;
  double _speed = 1.0;
  bool _isOnTrain = false;
  bool _arrived = false;
  String _currentStation = '';
  String _nextStation = '';
  Timer? _gameTimer;
  Timer? _eventTimer;
  String? _eventText;
  final _random = Random();

  final List<String> _stations = [];
  int _stationIndex = 0;

  // 랜덤 이벤트
  final _events = [
    {'text': '⚡ 환승 퍼펙트! +80 EXP', 'exp': 80},
    {'text': '🎉 텅 빈 객차 발견! HP +20', 'exp': 50},
    {'text': '😵 사람 많다... 인내력 소모', 'exp': 20},
    {'text': '☕ 커피 부스트! 스피드 UP', 'exp': 40},
    {'text': '⭐ 연예인 발견?! LUCK +30', 'exp': 100},
    {'text': '📱 폰 충전 완료! MP 회복', 'exp': 30},
    {'text': '🎭 수상한 승객의 응원! EXP 2배', 'exp': 150},
  ];

  @override
  void initState() {
    super.initState();

    _setupStations();

    // 캐릭터 달리기 애니메이션 (다리 움직임)
    _runController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..repeat(reverse: true);

    // 배경 스크롤
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // 구름 스크롤 (느리게)
    _cloudController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();

    // 지하철 진입 애니메이션
    _trainController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _startGame();
  }

  void _setupStations() {
    switch (widget.dungeonGrade) {
      case 'hell':
        _stations.addAll(['암사', '천호', '강동구청', '잠실', '삼성', '선릉', '강남', '교대', '사당', '합정']);
      case 'hard':
        _stations.addAll(['노량진', '여의도', '당산', '염창', '등촌', '가양', '합정']);
      case 'bonus':
        _stations.addAll(['출발', '공원', '다리', '강변', '골목', '도착']);
      default:
        _stations.addAll(['강남', '양재', '판교', '정자', '합정']);
    }
    _currentStation = _stations[0];
    _nextStation = _stations.length > 1 ? _stations[1] : '';
  }

  void _startGame() {
    // 메인 게임 루프 (1초마다)
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_arrived) return;

      setState(() {
        // 경험치 누적
        _expGained += (5 * _speed).toInt();

        // 3~8초마다 다음 역 도착
        if (timer.tick % (3 + _random.nextInt(5)) == 0) {
          _arriveAtStation();
        }
      });
    });

    // 랜덤 이벤트 (5~10초마다)
    _eventTimer = Timer.periodic(Duration(seconds: 5 + _random.nextInt(5)), (_) {
      if (_arrived) return;
      _triggerEvent();
    });

    // 2초 후 지하철 탑승
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isOnTrain = true);
        _trainController.forward();
        _speed = 2.0;
      }
    });
  }

  void _arriveAtStation() {
    _stationIndex++;
    if (_stationIndex >= _stations.length) {
      _arrived = true;
      _gameTimer?.cancel();
      _eventTimer?.cancel();
      _showResult();
      return;
    }

    _stationsPassed++;
    _currentStation = _stations[_stationIndex];
    _nextStation = _stationIndex + 1 < _stations.length ? _stations[_stationIndex + 1] : '도착!';
    _expGained += 50; // 역 통과 보너스

    setState(() {
      _eventText = '🚉 $_currentStation역 통과! +50 EXP';
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _eventText = null);
    });
  }

  void _triggerEvent() {
    final event = _events[_random.nextInt(_events.length)];
    _expGained += event['exp'] as int;
    setState(() {
      _eventText = event['text'] as String;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _eventText = null);
    });
  }

  void _showResult() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('🎉 던전 클리어!', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('목적지 도착!', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Text('+$_expGained EXP',
                style: const TextStyle(fontSize: 32, color: Colors.amberAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('$_stationsPassed개 역 통과', style: TextStyle(color: Colors.grey[400])),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('결과 확인'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _runController.dispose();
    _bgController.dispose();
    _cloudController.dispose();
    _trainController.dispose();
    _gameTimer?.cancel();
    _eventTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 하늘 배경
          _buildSky(),
          // 구름
          _buildClouds(),
          // 빌딩 배경 (원경)
          _buildFarBuildings(),
          // 빌딩 근경
          _buildNearBuildings(),
          // 지하철 터널 / 레일
          if (_isOnTrain) _buildSubwayInterior(),
          if (!_isOnTrain) _buildGround(),
          // 캐릭터
          _buildCharacter(),
          // 스피드 라인
          if (_speed > 1.5) _buildSpeedLines(),
          // 상단 HUD
          _buildHUD(),
          // 역 표시
          _buildStationInfo(),
          // 이벤트 팝업
          if (_eventText != null) _buildEventPopup(),
          // EXP 파티클
          _buildExpParticles(),
        ],
      ),
    );
  }

  Widget _buildSky() {
    final isUnderground = _isOnTrain && widget.dungeonGrade != 'bonus';
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isUnderground
              ? [const Color(0xFF0a0a1a), const Color(0xFF1a1a2e)]
              : [const Color(0xFF1a1a3e), const Color(0xFF2a2a5e)],
        ),
      ),
    );
  }

  Widget _buildClouds() {
    if (_isOnTrain && widget.dungeonGrade != 'bonus') return const SizedBox();

    return AnimatedBuilder(
      animation: _cloudController,
      builder: (_, __) {
        return Stack(
          children: List.generate(5, (i) {
            final x = ((_cloudController.value * MediaQuery.of(context).size.width * 2) +
                    i * 150) %
                (MediaQuery.of(context).size.width + 100) -
                50;
            return Positioned(
              left: x,
              top: 30.0 + i * 25,
              child: Opacity(
                opacity: 0.3,
                child: Icon(Icons.cloud, size: 40.0 + i * 10, color: Colors.white24),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildFarBuildings() {
    if (_isOnTrain && widget.dungeonGrade != 'bonus') return const SizedBox();

    return AnimatedBuilder(
      animation: _bgController,
      builder: (_, __) {
        return Positioned(
          bottom: 100,
          left: -(_bgController.value * 200),
          child: Row(
            children: List.generate(15, (i) {
              final h = 80.0 + _random.nextDouble() * 60;
              return Container(
                width: 40,
                height: h,
                margin: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withValues(alpha: 0.3),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
                child: Column(
                  children: List.generate((h ~/ 20), (j) => Padding(
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Container(width: 6, height: 8, color: Colors.yellow.withValues(alpha: 0.3 + _random.nextDouble() * 0.4)),
                        Container(width: 6, height: 8, color: Colors.yellow.withValues(alpha: 0.3 + _random.nextDouble() * 0.4)),
                      ],
                    ),
                  )),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildNearBuildings() {
    if (_isOnTrain && widget.dungeonGrade != 'bonus') return const SizedBox();

    return AnimatedBuilder(
      animation: _bgController,
      builder: (_, __) {
        final screenW = MediaQuery.of(context).size.width;
        return Positioned(
          bottom: 80,
          left: -(_bgController.value * 400) % (screenW + 200),
          child: Row(
            children: List.generate(8, (i) {
              final h = 120.0 + (i % 3) * 40;
              return Container(
                width: 70,
                height: h,
                margin: const EdgeInsets.only(right: 30),
                decoration: BoxDecoration(
                  color: const Color(0xFF2a3a5a).withValues(alpha: 0.7),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildSubwayInterior() {
    return AnimatedBuilder(
      animation: _trainController,
      builder: (_, __) {
        return Opacity(
          opacity: _trainController.value,
          child: Container(
            color: const Color(0xFF1a2a3a),
            child: Stack(
              children: [
                // 천장 손잡이
                Positioned(
                  top: 120,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(8, (_) => Column(
                      children: [
                        Container(width: 2, height: 20, color: Colors.grey[600]),
                        Container(
                          width: 16, height: 24,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[500]!, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    )),
                  ),
                ),
                // 바닥
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 80,
                  child: Container(color: const Color(0xFF2a3a4a)),
                ),
                // 좌석
                Positioned(
                  bottom: 80,
                  left: 20,
                  child: Row(
                    children: List.generate(3, (_) => Container(
                      width: 40, height: 35,
                      margin: const EdgeInsets.only(right: 5),
                      decoration: BoxDecoration(
                        color: Colors.orange[800],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )),
                  ),
                ),
                Positioned(
                  bottom: 80,
                  right: 20,
                  child: Row(
                    children: List.generate(3, (_) => Container(
                      width: 40, height: 35,
                      margin: const EdgeInsets.only(right: 5),
                      decoration: BoxDecoration(
                        color: Colors.orange[800],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )),
                  ),
                ),
                // 창문 (흐릿한 배경 지나감)
                Positioned(
                  top: 160,
                  left: 0,
                  right: 0,
                  height: 100,
                  child: AnimatedBuilder(
                    animation: _bgController,
                    builder: (_, __) {
                      return ClipRect(
                        child: Transform.translate(
                          offset: Offset(-_bgController.value * 600, 0),
                          child: Row(
                            children: List.generate(20, (i) => Container(
                              width: 60,
                              height: 100,
                              margin: const EdgeInsets.only(right: 2),
                              color: Color.lerp(
                                const Color(0xFF0a1020),
                                const Color(0xFF1a3050),
                                _random.nextDouble(),
                              ),
                            )),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGround() {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (_, __) {
        return Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 80,
          child: Container(
            color: const Color(0xFF2a3a2a),
            child: Stack(
              children: [
                // 도로 라인
                Positioned(
                  bottom: 30,
                  left: -(_bgController.value * 300) % 100 - 50,
                  child: Row(
                    children: List.generate(20, (_) => Container(
                      width: 30, height: 3,
                      margin: const EdgeInsets.only(right: 20),
                      color: Colors.yellow.withValues(alpha: 0.5),
                    )),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCharacter() {
    return AnimatedBuilder(
      animation: _runController,
      builder: (_, __) {
        final bounce = sin(_runController.value * pi) * 6;
        final legAngle = (_runController.value - 0.5) * 0.5;

        return Positioned(
          bottom: _isOnTrain ? 100 : 80,
          left: MediaQuery.of(context).size.width * 0.3,
          child: Transform.translate(
            offset: Offset(0, -bounce),
            child: Column(
              children: [
                // 캐릭터 본체
                SizedBox(
                  width: 60,
                  height: 80,
                  child: Stack(
                    children: [
                      // 몸통
                      Positioned(
                        top: 15,
                        left: 10,
                        child: Container(
                          width: 40,
                          height: 35,
                          decoration: BoxDecoration(
                            color: _getJobColor(),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      // 머리
                      Positioned(
                        top: 0,
                        left: 15,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xFFe8b890),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Center(
                            child: Text('😤', style: TextStyle(fontSize: 18)),
                          ),
                        ),
                      ),
                      // 왼쪽 다리
                      Positioned(
                        bottom: 0,
                        left: 15,
                        child: Transform.rotate(
                          angle: _isOnTrain ? 0 : legAngle,
                          child: Container(
                            width: 12,
                            height: 25,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2a2a4a),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      // 오른쪽 다리
                      Positioned(
                        bottom: 0,
                        left: 33,
                        child: Transform.rotate(
                          angle: _isOnTrain ? 0 : -legAngle,
                          child: Container(
                            width: 12,
                            height: 25,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2a2a4a),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      // 가방
                      if (!_isOnTrain)
                        Positioned(
                          top: 20,
                          right: 0,
                          child: Container(
                            width: 20,
                            height: 25,
                            decoration: BoxDecoration(
                              color: Colors.brown[700],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      // 지하철 손잡이 잡는 팔
                      if (_isOnTrain)
                        Positioned(
                          top: 0,
                          right: 5,
                          child: Container(
                            width: 8,
                            height: 30,
                            decoration: BoxDecoration(
                              color: const Color(0xFFe8b890),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // 이름
                Text(
                  widget.characterName,
                  style: const TextStyle(fontSize: 10, color: Colors.white70),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpeedLines() {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (_, __) {
        return Stack(
          children: List.generate(8, (i) {
            final y = 150.0 + i * 50 + _random.nextDouble() * 30;
            final x = (_bgController.value * 500 + i * 100) %
                (MediaQuery.of(context).size.width + 100);
            return Positioned(
              left: MediaQuery.of(context).size.width - x,
              top: y,
              child: Container(
                width: 30 + _random.nextDouble() * 40,
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white.withValues(alpha: 0.3), Colors.transparent],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildHUD() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: Row(
        children: [
          // EXP
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Text('⚡', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  '$_expGained EXP',
                  style: const TextStyle(
                    color: Colors.amberAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // 스피드
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_speed.toStringAsFixed(1)}x',
              style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          // 역 카운트
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '🚉 $_stationsPassed/${_stations.length - 1}',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStationInfo() {
    return Positioned(
      bottom: 20,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _getDungeonColor().withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                color: _getDungeonColor(),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(_currentStation, style: const TextStyle(fontWeight: FontWeight.bold)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('→', style: TextStyle(color: Colors.grey)),
            ),
            Text(_nextStation, style: TextStyle(color: Colors.grey[400])),
            const Spacer(),
            // 진행바
            SizedBox(
              width: 80,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _stationIndex / (_stations.length - 1),
                  backgroundColor: Colors.grey[800],
                  color: _getDungeonColor(),
                  minHeight: 6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventPopup() {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.35,
      left: 40,
      right: 40,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 500),
        curve: Curves.elasticOut,
        builder: (_, value, child) {
          return Transform.scale(scale: value, child: child);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.amberAccent.withValues(alpha: 0.2),
                blurRadius: 20,
              ),
            ],
          ),
          child: Text(
            _eventText!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildExpParticles() {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (_, __) {
        if (_expGained == 0) return const SizedBox();
        return Stack(
          children: List.generate(3, (i) {
            final x = MediaQuery.of(context).size.width * 0.3 + 20 + i * 10.0;
            final phase = (_bgController.value * 3 + i * 0.3) % 1.0;
            return Positioned(
              left: x,
              bottom: 160 + phase * 60,
              child: Opacity(
                opacity: (1 - phase).clamp(0, 1),
                child: const Text('+', style: TextStyle(color: Colors.amberAccent, fontSize: 12)),
              ),
            );
          }),
        );
      },
    );
  }

  Color _getJobColor() {
    switch (widget.dungeonGrade) {
      case 'hell':
        return Colors.red[800]!;
      case 'hard':
        return Colors.orange[800]!;
      case 'bonus':
        return Colors.blue[600]!;
      default:
        return const Color(0xFF6C5CE7);
    }
  }

  Color _getDungeonColor() {
    switch (widget.dungeonGrade) {
      case 'hell':
        return Colors.red;
      case 'hard':
        return Colors.orange;
      case 'normal':
        return Colors.yellow;
      case 'field':
        return Colors.green;
      case 'bonus':
        return Colors.blue;
      default:
        return Colors.purple;
    }
  }
}
