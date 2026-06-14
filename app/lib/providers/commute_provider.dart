import 'package:flutter/material.dart';

import '../models/commute_result.dart';
import '../services/api_service.dart';

enum CommuteState { idle, commuting, completed }

class CommuteProvider extends ChangeNotifier {
  CommuteState _state = CommuteState.idle;
  CommuteResult? _lastResult;
  String? _currentDungeon;
  DateTime? _startTime;

  CommuteState get state => _state;
  CommuteResult? get lastResult => _lastResult;
  String? get currentDungeon => _currentDungeon;
  DateTime? get startTime => _startTime;

  Duration get elapsed =>
      _startTime != null ? DateTime.now().difference(_startTime!) : Duration.zero;

  Future<void> startCommute(ApiService api, String dungeonGrade, DateTime targetArrival) async {
    _currentDungeon = dungeonGrade;
    _startTime = DateTime.now();
    _state = CommuteState.commuting;
    notifyListeners();

    await api.startCommute(dungeonGrade, targetArrival);
  }

  Future<CommuteResult> endCommute(ApiService api) async {
    _lastResult = await api.endCommute();
    _state = CommuteState.completed;
    notifyListeners();
    return _lastResult!;
  }

  void reset() {
    _state = CommuteState.idle;
    _currentDungeon = null;
    _startTime = null;
    notifyListeners();
  }
}
