import 'package:flutter/material.dart';

import '../models/character.dart';
import '../services/api_service.dart';

class CharacterProvider extends ChangeNotifier {
  Character? _character;
  bool _isLoading = false;

  Character? get character => _character;
  bool get isLoading => _isLoading;
  bool get hasCharacter => _character != null;

  Future<void> loadCharacter(ApiService api) async {
    _isLoading = true;
    notifyListeners();

    try {
      _character = await api.getMyCharacter();
    } catch (_) {
      _character = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createCharacter(ApiService api, String name) async {
    try {
      _character = await api.createCharacter(name);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  void updateFromResult(int newLevel, String? newJob) {
    if (_character == null) return;
    // Reload character from API after commute
    notifyListeners();
  }
}
