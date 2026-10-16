import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyReminderStatus {
  const DailyReminderStatus({
    required this.enabled,
    required this.permissionGranted,
  });

  final bool enabled;
  final bool permissionGranted;
}

class DailyReminderService {
  DailyReminderService._() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'openAuctionsFromReminder') {
        _reminderTaps.add(null);
      }
    });
  }

  static final DailyReminderService instance = DailyReminderService._();
  static const _channel = MethodChannel(
    'com.example.pelelangan_produk_fashion/daily_reminder',
  );
  static const _offerShownKey = 'daily_reminder_offer_shown';

  final StreamController<void> _reminderTaps =
      StreamController<void>.broadcast();

  bool get isSupported => defaultTargetPlatform == TargetPlatform.android;
  Stream<void> get reminderTaps => _reminderTaps.stream;

  Future<bool> consumeInitialReminderTap() async {
    if (!isSupported) return false;
    return await _channel.invokeMethod<bool>('consumeInitialReminderTap') ??
        false;
  }

  Future<DailyReminderStatus> getStatus() async {
    if (!isSupported) {
      return const DailyReminderStatus(
        enabled: false,
        permissionGranted: false,
      );
    }

    final values = await _channel.invokeMapMethod<String, dynamic>(
      'getReminderStatus',
    );
    return DailyReminderStatus(
      enabled: values?['enabled'] == true,
      permissionGranted: values?['permissionGranted'] == true,
    );
  }

  Future<bool> enable() async {
    if (!isSupported) return false;
    return await _channel.invokeMethod<bool>('enableDailyReminder') ?? false;
  }

  Future<void> disable() async {
    if (!isSupported) return;
    await _channel.invokeMethod<void>('disableDailyReminder');
  }

  Future<void> openNotificationSettings() async {
    if (!isSupported) return;
    await _channel.invokeMethod<void>('openNotificationSettings');
  }

  Future<bool> claimLoginOffer() async {
    final preferences = await SharedPreferences.getInstance();
    if (preferences.getBool(_offerShownKey) ?? false) return false;
    await preferences.setBool(_offerShownKey, true);
    return true;
  }
}
