import 'dart:async';
import 'package:flutter/foundation.dart';

class TimerService {
  static final TimerService _instance = TimerService._internal();
  factory TimerService() => _instance;
  static TimerService get instance => _instance;
  TimerService._internal();

  Timer? _timer;
  final ValueNotifier<int> remainingSeconds = ValueNotifier(0);
  final ValueNotifier<bool> isActive = ValueNotifier(false);

  void startPomodoro(int minutes) {
    _timer?.cancel();
    remainingSeconds.value = minutes * 60;
    isActive.value = true;
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds.value > 0) {
        remainingSeconds.value--;
      } else {
        stop();
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    isActive.value = false;
  }
}
