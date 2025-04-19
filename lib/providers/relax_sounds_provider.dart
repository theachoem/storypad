import 'dart:async';

import 'package:flutter/material.dart';
import 'package:storypad/core/objects/relax_sound_object.dart';

class RelaxSoundsProvider extends ChangeNotifier {
  List<RelaxSoundObject> get relaxSounds => RelaxSoundObject.defaultSoundsList();

  bool isSoundSelected(int index) => _selectedSoundIndexes.contains(index);
  double getVolumn(index) => _soundVolumnsByIndex[index] ?? 0.5;

  List<RelaxSoundObject> get selectedRelaxSounds =>
      _selectedSoundIndexes.map((index) => relaxSounds.elementAt(index)).toList();

  RelaxSoundObject? get lastSelectedSound =>
      _selectedSoundIndexes.isNotEmpty ? relaxSounds.elementAtOrNull(_selectedSoundIndexes.last) : null;

  final Set<int> _selectedSoundIndexes = {};
  final Map<int, double> _soundVolumnsByIndex = {};

  Timer? _stopTimer;
  bool get stopInEnded => _stopIn == null || _stopIn?.inSeconds == 0;
  Duration? _stopIn;
  Duration? get stopIn => _stopIn;

  bool get playing => _stopTimer?.isActive == true && _selectedSoundIndexes.isNotEmpty;
  bool get paused => _stopTimer == null && _selectedSoundIndexes.isNotEmpty;

  void setVolumn(int index, double volumn) {
    _soundVolumnsByIndex[index] = volumn;
    notifyListeners();
  }

  void toggleSound(int index) {
    if (_selectedSoundIndexes.contains(index)) {
      _selectedSoundIndexes.remove(index);
      _soundVolumnsByIndex.remove(index);
    } else {
      _selectedSoundIndexes.add(index);
    }

    if (stopInEnded) {
      _stopIn = const Duration(minutes: 30);
      _resetTimer();
    }

    notifyListeners();
  }

  void setStopIn(Duration duration) {
    _stopIn = duration;
    notifyListeners();
  }

  void togglePlayPause() {
    if (playing) {
      _stopTimer?.cancel();
      _stopTimer = null;
    } else if (paused) {
      _resetTimer();
    }

    notifyListeners();
  }

  void _resetTimer() {
    _stopTimer?.cancel();
    _stopTimer = null;
    _stopTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_stopIn != null) _stopIn = _stopIn! - const Duration(seconds: 1);
      if (_stopIn == null || _stopIn?.inSeconds == 0) {
        _forceStop();
      }
    });
  }

  void _forceStop() {
    _selectedSoundIndexes.clear();
    _stopTimer?.cancel();
    _stopTimer = null;
    _stopIn = null;

    notifyListeners();
  }

  @override
  void dispose() {
    _stopTimer?.cancel();
    _stopTimer = null;
    super.dispose();
  }
}
