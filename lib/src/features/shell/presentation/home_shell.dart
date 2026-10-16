import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/notifications/daily_reminder_service.dart';
import '../../../core/session/auth_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/snackbar.dart';
import '../../../core/widgets/app_surface.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    required this.navigationShell,
    required this.auth,
    required this.reminders,
    super.key,
  });

  final StatefulNavigationShell navigationShell;
  final AuthController auth;
  final DailyReminderService reminders;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  bool _checkingReminderOffer = false;

  @override
  void initState() {
    super.initState();
    widget.auth.addListener(_onAuthChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeOfferReminder());
  }

  @override
  void dispose() {
    widget.auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeOfferReminder());
  }

  Future<void> _maybeOfferReminder() async {
    if (!mounted ||
        _checkingReminderOffer ||
        !widget.reminders.isSupported ||
        !widget.auth.takeReminderOfferRequest()) {
      return;
    }

    _checkingReminderOffer = true;
    try {
      if (!await widget.reminders.claimLoginOffer() || !mounted) return;
      final status = await widget.reminders.getStatus();
      if (!mounted || status.enabled) return;

      final activate = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Ingat lelang setiap hari'),
          content: const Text(
            'Aktifkan pengingat harian sekitar pukul 19.00 WIB agar kamu tidak '
            'melewatkan lelang menarik.',
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Nanti'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Aktifkan'),
                ),
              ],
            ),
          ],
        ),
      );

      if (activate != true || !mounted) return;
      final enabled = await widget.reminders.enable();
      if (!mounted || enabled) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Izin notifikasi belum aktif. Kamu bisa mengaturnya dari Profil.',
          ),
          action: SnackBarAction(
            label: 'Pengaturan',
            onPressed: widget.reminders.openNotificationSettings,
          ),
        ),
      );
    } catch (error) {
      if (mounted) showError(context, error.toString());
    } finally {
      _checkingReminderOffer = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final navigationShell = widget.navigationShell;
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.brandSoft,
      body: AppBackground(
        child: SafeArea(bottom: false, child: navigationShell),
      ),
      bottomNavigationBar: _FloatingHomeNav(
        currentIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}

class _FloatingHomeNav extends StatelessWidget {
  const _FloatingHomeNav({
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  static const _items = [
    (Icons.gavel_outlined, Icons.gavel, 'Lelang'),
    (Icons.dashboard_outlined, Icons.dashboard, 'Aktivitas'),
    (Icons.chat_bubble_outline, Icons.chat_bubble, 'Chat'),
    (Icons.person_outline, Icons.person, 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, bottom + 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.line),
          boxShadow: [
            BoxShadow(
              color: AppColors.brand950.withValues(alpha: 0.09),
              blurRadius: 20,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          bottom: false,
          child: SizedBox(
            height: 66,
            child: Row(
              children: [
                for (final entry in _items.indexed)
                  Expanded(
                    child: _FloatingNavItem(
                      icon: entry.$2.$1,
                      selectedIcon: entry.$2.$2,
                      label: entry.$2.$3,
                      selected: currentIndex == entry.$1,
                      onTap: () => onDestinationSelected(entry.$1),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingNavItem extends StatelessWidget {
  const _FloatingNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: selected ? 34 : 30,
                height: selected ? 34 : 30,
                decoration: BoxDecoration(
                  color: selected ? AppColors.brand100 : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  selected ? selectedIcon : icon,
                  size: selected ? 21 : 20,
                  color: selected ? AppColors.brand800 : AppColors.zinc500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? AppColors.brand800 : AppColors.zinc500,
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
