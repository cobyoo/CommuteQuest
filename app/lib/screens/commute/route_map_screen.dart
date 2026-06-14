import 'dart:math';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

class SubwayStation {
  final String name;
  final Offset position; // Normalised 0–1 coordinates

  const SubwayStation({required this.name, required this.position});
}

class SubwayRoute {
  final String lineName;
  final Color lineColor;
  final List<SubwayStation> stations;

  const SubwayRoute({
    required this.lineName,
    required this.lineColor,
    required this.stations,
  });
}

class RandomEvent {
  final String emoji;
  final String title;
  final String description;
  final int expBonus;

  const RandomEvent({
    required this.emoji,
    required this.title,
    required this.description,
    required this.expBonus,
  });
}

// ---------------------------------------------------------------------------
// Static data
// ---------------------------------------------------------------------------

const _line2 = SubwayRoute(
  lineName: '2호선',
  lineColor: Color(0xFF00A84D),
  stations: [
    SubwayStation(name: '합정', position: Offset(0.04, 0.25)),
    SubwayStation(name: '홍대입구', position: Offset(0.17, 0.20)),
    SubwayStation(name: '신촌', position: Offset(0.30, 0.18)),
    SubwayStation(name: '이대', position: Offset(0.43, 0.20)),
    SubwayStation(name: '아현', position: Offset(0.55, 0.25)),
    SubwayStation(name: '충정로', position: Offset(0.65, 0.33)),
    SubwayStation(name: '시청', position: Offset(0.72, 0.42)),
  ],
);

const _line9 = SubwayRoute(
  lineName: '9호선',
  lineColor: Color(0xFFBFA14A),
  stations: [
    SubwayStation(name: '노량진', position: Offset(0.60, 0.72)),
    SubwayStation(name: '여의도', position: Offset(0.48, 0.65)),
    SubwayStation(name: '당산', position: Offset(0.35, 0.60)),
    SubwayStation(name: '염창', position: Offset(0.22, 0.65)),
    SubwayStation(name: '등촌', position: Offset(0.13, 0.72)),
    SubwayStation(name: '가양', position: Offset(0.06, 0.80)),
  ],
);

const _sinbundang = SubwayRoute(
  lineName: '신분당선',
  lineColor: Color(0xFFD31145),
  stations: [
    SubwayStation(name: '강남', position: Offset(0.78, 0.52)),
    SubwayStation(name: '양재', position: Offset(0.84, 0.63)),
    SubwayStation(name: '판교', position: Offset(0.88, 0.76)),
    SubwayStation(name: '정자', position: Offset(0.90, 0.88)),
  ],
);

const List<SubwayRoute> _allRoutes = [_line2, _line9, _sinbundang];

const List<RandomEvent> _randomEvents = [
  RandomEvent(
    emoji: '🎵',
    title: '이어폰 발견!',
    description: '좌석 옆에 이어폰이 있다. 주인을 찾아줬다.',
    expBonus: 15,
  ),
  RandomEvent(
    emoji: '👴',
    title: '자리 양보',
    description: '어르신께 자리를 양보했다. 칭찬받았다!',
    expBonus: 25,
  ),
  RandomEvent(
    emoji: '📰',
    title: '무료 신문',
    description: '지하철 신문으로 세상 소식을 접했다.',
    expBonus: 10,
  ),
  RandomEvent(
    emoji: '☕',
    title: '커피 엎지름 위기',
    description: '급정거했지만 커피를 지켜냈다! 반사신경 +1',
    expBonus: 20,
  ),
  RandomEvent(
    emoji: '💼',
    title: '네트워킹 찬스',
    description: '옆자리 직장인과 명함을 교환했다.',
    expBonus: 30,
  ),
  RandomEvent(
    emoji: '🎮',
    title: '스마트폰 게임',
    description: '짧은 구간에 미니게임 클리어!',
    expBonus: 12,
  ),
  RandomEvent(
    emoji: '🌧️',
    title: '갑작스러운 비',
    description: '플랫폼에서 우산을 빌려줬다. 선행 포인트 획득!',
    expBonus: 18,
  ),
];

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class RouteMapScreen extends StatefulWidget {
  final String dungeonGrade;
  final String jobClass;
  final String characterName;

  const RouteMapScreen({
    super.key,
    required this.dungeonGrade,
    required this.jobClass,
    required this.characterName,
  });

  @override
  State<RouteMapScreen> createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends State<RouteMapScreen>
    with TickerProviderStateMixin {
  // ------------------------------------------------------------------
  // Animation controllers
  // ------------------------------------------------------------------
  late final AnimationController _characterController;
  late final AnimationController _pulseController;
  late final AnimationController _expController;
  late final AnimationController _eventController;

  late Animation<double> _characterProgress; // 0–1 along the route
  late Animation<double> _pulseAnimation;
  late Animation<double> _expAnimation;
  late Animation<double> _eventOpacity;

  // ------------------------------------------------------------------
  // State
  // ------------------------------------------------------------------
  late SubwayRoute _activeRoute;
  int _currentSegment = 0; // which pair of stations we're travelling between
  int _totalExpGained = 0;
  int _pendingSegmentExp = 0;
  Duration _elapsed = Duration.zero;
  RandomEvent? _activeEvent;
  bool _showEvent = false;

  late final Stopwatch _stopwatch;
  late final Stream<int> _ticker;

  static const int _expPerStation = 40;
  static const Duration _segmentDuration = Duration(seconds: 6);
  static const Duration _eventCheckInterval = Duration(seconds: 8);

  DateTime _lastEventCheck = DateTime.now();
  final Random _rng = Random();

  // ------------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------------
  String get _jobEmoji {
    const map = {
      'intern': '🧑‍💼',
      'staff': '💼',
      'senior': '📋',
      'manager': '🏢',
      'director': '🎩',
      'executive': '👑',
      'legend': '🌟',
    };
    return map[widget.jobClass] ?? '🧑‍💼';
  }

  SubwayRoute _routeForDungeon(String grade) {
    switch (grade) {
      case 'hell':
        return _line2;
      case 'hard':
        return _line9;
      default:
        return _sinbundang;
    }
  }

  int get _totalSegments => _activeRoute.stations.length - 1;

  // ------------------------------------------------------------------
  // Lifecycle
  // ------------------------------------------------------------------
  @override
  void initState() {
    super.initState();

    _activeRoute = _routeForDungeon(widget.dungeonGrade);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.7, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _characterController = AnimationController(
      vsync: this,
      duration: _segmentDuration,
    )..addStatusListener(_onSegmentComplete);
    _characterProgress = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _characterController, curve: Curves.easeInOut),
    );

    _expController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _expAnimation = Tween<double>(begin: 0, end: 0).animate(_expController);

    _eventController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _eventOpacity = CurvedAnimation(
      parent: _eventController,
      curve: Curves.easeOut,
    );

    _stopwatch = Stopwatch()..start();

    // Tick every second
    _ticker = Stream<int>.periodic(const Duration(seconds: 1), (i) => i);
    _ticker.listen(_onTick);

    // Start moving
    _characterController.forward();
  }

  @override
  void dispose() {
    _characterController.dispose();
    _pulseController.dispose();
    _expController.dispose();
    _eventController.dispose();
    _stopwatch.stop();
    super.dispose();
  }

  // ------------------------------------------------------------------
  // Event handlers
  // ------------------------------------------------------------------
  void _onTick(int tick) {
    if (!mounted) return;
    setState(() {
      _elapsed = _stopwatch.elapsed;
      // Accumulate segment EXP based on progress
      final segProg = _characterController.value;
      final targetExp = (_expPerStation * segProg).toInt();
      if (targetExp > _pendingSegmentExp) {
        _pendingSegmentExp = targetExp;
      }
    });

    // Random event check
    final now = DateTime.now();
    if (now.difference(_lastEventCheck) >= _eventCheckInterval &&
        !_showEvent &&
        _currentSegment < _totalSegments) {
      _lastEventCheck = now;
      if (_rng.nextDouble() < 0.45) {
        _triggerRandomEvent();
      }
    }
  }

  void _onSegmentComplete(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    if (!mounted) return;

    setState(() {
      _totalExpGained += _expPerStation;
      _pendingSegmentExp = 0;
      _currentSegment++;
    });

    if (_currentSegment < _totalSegments) {
      _characterController.reset();
      _characterController.forward();
    }
  }

  void _triggerRandomEvent() {
    final event = _randomEvents[_rng.nextInt(_randomEvents.length)];
    setState(() {
      _activeEvent = event;
      _showEvent = true;
    });
    _eventController.forward(from: 0);

    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      _eventController.reverse().then((_) {
        if (!mounted) return;
        setState(() {
          _totalExpGained += event.expBonus;
          _showEvent = false;
          _activeEvent = null;
        });
      });
    });
  }

  // ------------------------------------------------------------------
  // Computed position
  // ------------------------------------------------------------------
  /// Returns the current normalised character position on the map (0-1 coords).
  Offset _characterPosition() {
    if (_currentSegment >= _totalSegments) {
      return _activeRoute.stations.last.position;
    }
    final from = _activeRoute.stations[_currentSegment].position;
    final to = _activeRoute.stations[_currentSegment + 1].position;
    final t = _characterController.value;
    return Offset.lerp(from, to, t)!;
  }

  // ------------------------------------------------------------------
  // Build
  // ------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final bool completed = _currentSegment >= _totalSegments;
    final int displayExp = _totalExpGained + _pendingSegmentExp;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '${_activeRoute.lineName} 출근 퀘스트',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // ---- Status bar ----
          _buildStatusBar(displayExp),

          // ---- Map ----
          Expanded(
            child: Stack(
              children: [
                // Route map painter
                AnimatedBuilder(
                  animation: Listenable.merge([
                    _characterController,
                    _pulseController,
                  ]),
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _RouteMapPainter(
                        routes: _allRoutes,
                        activeRoute: _activeRoute,
                        characterPosition: _characterPosition(),
                        pulseScale: _pulseAnimation.value,
                        currentSegment: _currentSegment,
                        totalSegments: _totalSegments,
                      ),
                      child: const SizedBox.expand(),
                    );
                  },
                ),

                // Character avatar overlay
                AnimatedBuilder(
                  animation: _characterController,
                  builder: (context, _) {
                    return _buildCharacterAvatar(context);
                  },
                ),

                // Random event popup
                if (_showEvent && _activeEvent != null)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: FadeTransition(
                      opacity: _eventOpacity,
                      child: _buildEventCard(_activeEvent!),
                    ),
                  ),

                // Completed overlay
                if (completed)
                  _buildCompletedOverlay(displayExp),
              ],
            ),
          ),

          // ---- Station list footer ----
          _buildStationList(),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // Sub-widgets
  // ------------------------------------------------------------------

  Widget _buildStatusBar(int displayExp) {
    final minutes = _elapsed.inMinutes;
    final seconds = _elapsed.inSeconds % 60;
    final progress = _totalSegments > 0
        ? (_currentSegment + (_characterController.value)) / _totalSegments
        : 1.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6C5CE7).withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Character info
              Text(
                _jobEmoji,
                style: const TextStyle(fontSize: 26),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.characterName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${_activeRoute.stations.first.name} → ${_activeRoute.stations.last.name}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Time
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '⏱ ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: Color(0xFF00CEC9),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '✨ $displayExp EXP',
                    style: const TextStyle(
                      color: Color(0xFFFD79A8),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(
                _activeRoute.lineColor,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _activeRoute.stations.first.name,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 11,
                ),
              ),
              Text(
                '${(_currentSegment).clamp(0, _totalSegments)} / $_totalSegments 구간',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 11,
                ),
              ),
              Text(
                _activeRoute.stations.last.name,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterAvatar(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final mapHeight = size.height * 0.52; // approximate map area height
    final charPos = _characterPosition();

    final dx = 16 + charPos.dx * (size.width - 32) - 20;
    final dy = charPos.dy * mapHeight - 20;

    return Positioned(
      left: dx,
      top: dy,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulse ring
              Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF6C5CE7).withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                ),
              ),
              // Character circle
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6C5CE7),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C5CE7).withOpacity(0.6),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  _jobEmoji,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEventCard(RandomEvent event) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFD79A8).withOpacity(0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFD79A8).withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Text(event.emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '⚡ 랜덤 이벤트!',
                  style: TextStyle(
                    color: const Color(0xFFFD79A8),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  event.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  event.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '+${event.expBonus}',
                style: const TextStyle(
                  color: Color(0xFFFD79A8),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const Text(
                'EXP',
                style: TextStyle(
                  color: Color(0xFFFD79A8),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedOverlay(int totalExp) {
    return Container(
      color: Colors.black.withOpacity(0.75),
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF6C5CE7),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C5CE7).withOpacity(0.3),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text(
              '목적지 도착!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_activeRoute.stations.last.name} 도착 완료',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF6C5CE7).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '✨ 총 $totalExp EXP 획득!',
                style: const TextStyle(
                  color: Color(0xFFFD79A8),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(totalExp),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '결과 확인하기',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStationList() {
    return Container(
      height: 68,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _activeRoute.stations.length,
        itemBuilder: (context, index) {
          final station = _activeRoute.stations[index];
          final isPast = index < _currentSegment;
          final isCurrent = index == _currentSegment &&
              _currentSegment < _totalSegments;
          final isDestination = index == _activeRoute.stations.length - 1;

          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Station dot with connector
                Row(
                  children: [
                    if (index > 0)
                      Container(
                        width: 16,
                        height: 2,
                        color: isPast
                            ? _activeRoute.lineColor
                            : Colors.white24,
                      ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: isCurrent ? 14 : 10,
                      height: isCurrent ? 14 : 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isPast
                            ? _activeRoute.lineColor
                            : isCurrent
                                ? Colors.white
                                : Colors.white24,
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.6),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  isDestination ? '🏁 ${station.name}' : station.name,
                  style: TextStyle(
                    color: isCurrent
                        ? Colors.white
                        : isPast
                            ? _activeRoute.lineColor.withOpacity(0.9)
                            : Colors.white38,
                    fontSize: 10,
                    fontWeight: isCurrent || isDestination
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CustomPainter
// ---------------------------------------------------------------------------

class _RouteMapPainter extends CustomPainter {
  final List<SubwayRoute> routes;
  final SubwayRoute activeRoute;
  final Offset characterPosition; // normalised 0-1
  final double pulseScale;
  final int currentSegment;
  final int totalSegments;

  const _RouteMapPainter({
    required this.routes,
    required this.activeRoute,
    required this.characterPosition,
    required this.pulseScale,
    required this.currentSegment,
    required this.totalSegments,
  });

  Offset _toCanvas(Offset norm, Size size) {
    return Offset(norm.dx * size.width, norm.dy * size.height);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // ---- Draw all routes (inactive ones dimmed) ----
    for (final route in routes) {
      final isActive = route.lineName == activeRoute.lineName;
      _drawRoute(canvas, size, route, isActive);
    }

    // ---- Pulsing position highlight ----
    final charCanvas = _toCanvas(characterPosition, size);
    final pulsePaint = Paint()
      ..color = const Color(0xFF6C5CE7).withOpacity(0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(charCanvas, 22 * pulseScale, pulsePaint);
  }

  void _drawRoute(
    Canvas canvas,
    Size size,
    SubwayRoute route,
    bool isActive,
  ) {
    final linePaint = Paint()
      ..color = isActive ? route.lineColor : route.lineColor.withOpacity(0.25)
      ..strokeWidth = isActive ? 3.5 : 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final passedPaint = Paint()
      ..color = route.lineColor
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (int i = 0; i < route.stations.length; i++) {
      final pt = _toCanvas(route.stations[i].position, size);
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }

    // Draw full line
    canvas.drawPath(path, linePaint);

    // Draw passed segments with highlight for active route
    if (isActive && currentSegment > 0) {
      final passedPath = Path();
      for (int i = 0; i <= currentSegment && i < route.stations.length; i++) {
        final pt = _toCanvas(route.stations[i].position, size);
        if (i == 0) {
          passedPath.moveTo(pt.dx, pt.dy);
        } else {
          passedPath.lineTo(pt.dx, pt.dy);
        }
      }
      canvas.drawPath(passedPath, passedPaint);
    }

    // ---- Draw stations ----
    for (int i = 0; i < route.stations.length; i++) {
      final station = route.stations[i];
      final pt = _toCanvas(station.position, size);

      final bool isPast = isActive && i < currentSegment;
      final bool isCurrent = isActive && i == currentSegment && currentSegment < totalSegments;
      final bool isDestination = i == route.stations.length - 1;

      // Outer ring
      final outerPaint = Paint()
        ..color = isActive
            ? (isPast ? route.lineColor : route.lineColor.withOpacity(0.5))
            : route.lineColor.withOpacity(0.15)
        ..style = PaintingStyle.fill;

      // Inner dot
      final innerPaint = Paint()
        ..color = isPast
            ? Colors.white
            : isActive
                ? Colors.white.withOpacity(0.9)
                : Colors.white.withOpacity(0.2)
        ..style = PaintingStyle.fill;

      double outerR = isDestination ? 9.0 : 7.0;
      double innerR = isDestination ? 5.0 : 4.0;

      if (isCurrent) {
        outerR = 10.0;
        innerR = 6.0;
        // Glow for current
        canvas.drawCircle(
          pt,
          outerR + 4,
          Paint()
            ..color = Colors.white.withOpacity(0.15)
            ..style = PaintingStyle.fill,
        );
      }

      canvas.drawCircle(pt, outerR, outerPaint);
      canvas.drawCircle(pt, innerR, innerPaint);

      // ---- Station label ----
      if (isActive) {
        final labelStyle = TextStyle(
          color: isPast
              ? Colors.white
              : isCurrent
                  ? Colors.white
                  : Colors.white54,
          fontSize: isCurrent ? 11.5 : 10,
          fontWeight: isCurrent || isDestination
              ? FontWeight.bold
              : FontWeight.normal,
        );
        _drawLabel(canvas, station.name, pt, labelStyle, size);
      } else {
        // Inactive lines: lighter label
        _drawLabel(
          canvas,
          station.name,
          pt,
          const TextStyle(
            color: Color(0x44FFFFFF),
            fontSize: 9,
          ),
          size,
        );
      }
    }
  }

  void _drawLabel(
    Canvas canvas,
    String text,
    Offset center,
    TextStyle style,
    Size canvasSize,
  ) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    // Position label above or below depending on vertical space
    double dy = center.dy - tp.height - 8;
    if (dy < 4) dy = center.dy + 10;

    final dx = (center.dx - tp.width / 2).clamp(2.0, canvasSize.width - tp.width - 2);
    tp.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(_RouteMapPainter old) =>
      old.characterPosition != characterPosition ||
      old.pulseScale != pulseScale ||
      old.currentSegment != currentSegment;
}
