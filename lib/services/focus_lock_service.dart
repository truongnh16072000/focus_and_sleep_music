import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class FocusLockService {
  static final FocusLockService _instance = FocusLockService._internal();
  factory FocusLockService() => _instance;
  static FocusLockService get instance => _instance;
  FocusLockService._internal();

  static const MethodChannel _channel = MethodChannel('neuroflow/focus_lock');

  Future<bool> setFocusLockEnabled(bool enabled) async {
    if (kIsWeb) return false;

    try {
      final result = await _channel.invokeMethod<bool>('setFocusLock', {
        'enabled': enabled,
      });
      return result ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> isFocusLockActive() async {
    if (kIsWeb) return false;

    try {
      final result = await _channel.invokeMethod<bool>('isFocusLockActive');
      return result ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
