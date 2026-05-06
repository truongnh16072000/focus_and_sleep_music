import 'package:flutter/foundation.dart';
import 'focus_lock_service.dart';
import 'storage_service.dart';

class FocusSessionLockService {
  static final FocusSessionLockService _instance =
      FocusSessionLockService._internal();
  factory FocusSessionLockService() => _instance;
  static FocusSessionLockService get instance => _instance;
  FocusSessionLockService._internal();

  final ValueNotifier<bool> isEnabled = ValueNotifier(false);
  final ValueNotifier<bool> isActive = ValueNotifier(false);

  Future<void> init() async {
    isEnabled.value = StorageService.instance.isFocusScreenLockEnabled();
  }

  Future<bool> setEnabled(bool enabled) async {
    isEnabled.value = enabled;
    await StorageService.instance.setFocusScreenLockEnabled(enabled);

    if (!enabled) {
      final applied = await _setPlatformLock(false);
      isActive.value = await FocusLockService.instance.isFocusLockActive();
      return applied || !isActive.value;
    }

    if (!isActive.value) return true;
    final applied = await _setPlatformLock(enabled);
    isActive.value = enabled && applied;
    return applied;
  }

  Future<bool> activateForFocusPlayback() async {
    if (!isEnabled.value) return true;

    final applied = await _setPlatformLock(true);
    final active =
        applied || await FocusLockService.instance.isFocusLockActive();
    isActive.value = active;
    return applied;
  }

  Future<void> deactivateForFocusPlayback() async {
    if (!isActive.value) return;

    await _setPlatformLock(false);
    isActive.value = await FocusLockService.instance.isFocusLockActive();
  }

  Future<bool> _setPlatformLock(bool enabled) {
    return FocusLockService.instance.setFocusLockEnabled(enabled);
  }
}
