import 'dart:async';

import 'package:flutter/material.dart';

import '../core/config/app_config.dart';
import '../core/notifications/daily_reminder_service.dart';
import '../core/session/auth_controller.dart';
import '../data/api/api_client.dart';
import 'app_router.dart';
import 'app_theme.dart';

class LelangFashionApp extends StatefulWidget {
  const LelangFashionApp({super.key});

  @override
  State<LelangFashionApp> createState() => _LelangFashionAppState();
}

class _LelangFashionAppState extends State<LelangFashionApp> {
  late final DailyReminderService _reminders = DailyReminderService.instance;
  late final ApiClient _api = ApiClient(apiBaseUrl);
  late final AuthController _auth = AuthController(_api)..bootstrap();
  late final AppRouter _appRouter = AppRouter(
    api: _api,
    auth: _auth,
    reminders: _reminders,
  );
  StreamSubscription<void>? _reminderTapSubscription;

  @override
  void initState() {
    super.initState();
    _reminderTapSubscription = _reminders.reminderTaps.listen((_) {
      _openAuctionsFromReminder();
    });
    _reminders.consumeInitialReminderTap().then((wasOpened) {
      if (wasOpened && mounted) _openAuctionsFromReminder();
    });
  }

  void _openAuctionsFromReminder() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _appRouter.router.go('/lelang');
    });
  }

  @override
  void dispose() {
    _reminderTapSubscription?.cancel();
    _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Lelang Fashion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: _appRouter.router,
    );
  }
}
