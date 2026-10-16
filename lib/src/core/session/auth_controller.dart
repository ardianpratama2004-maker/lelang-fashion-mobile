import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/api/api_client.dart';
import '../../data/models/auth_result.dart';
import '../../data/models/user_account.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._api);

  final ApiClient _api;
  bool _loading = true;
  UserAccount? _user;
  bool _reminderOfferPending = false;

  bool get loading => _loading;
  bool get isAuthenticated => _user != null;
  UserAccount? get user => _user;

  bool takeReminderOfferRequest() {
    final pending = _reminderOfferPending;
    _reminderOfferPending = false;
    return pending;
  }

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null) {
      _api.token = token;
      try {
        _user = await _api.me();
      } catch (_) {
        await prefs.remove('token');
        _api.token = null;
      }
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> authenticated(
    AuthResult result, {
    bool offerDailyReminder = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', result.token);
    _api.token = result.token;
    _user = result.user;
    _reminderOfferPending = offerDailyReminder;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    _user = await _api.me();
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (_) {
      // Local logout still clears the token when the server is unavailable.
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    _api.token = null;
    _user = null;
    notifyListeners();
  }
}
