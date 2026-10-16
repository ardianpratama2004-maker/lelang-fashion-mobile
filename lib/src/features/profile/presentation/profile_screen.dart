import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/session/auth_controller.dart';
import '../../../core/notifications/daily_reminder_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/snackbar.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../data/models/identity_verification.dart';
import '../../../data/models/user_account.dart';
import '../domain/profile_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    required this.repository,
    required this.auth,
    super.key,
  });

  final ProfileRepository repository;
  final AuthController auth;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver {
  late Future<UserAccount> _userFuture = widget.repository.me();
  late Future<IdentityVerification?> _identityFuture = widget.repository
      .identityVerification();
  final _whatsapp = TextEditingController();
  final _otp = TextEditingController();
  final _nik = TextEditingController();
  final _ktpName = TextEditingController();
  final _picker = ImagePicker();
  XFile? _ktpImage;
  XFile? _selfieImage;
  bool _editingWhatsapp = false;
  bool _showEkycForm = false;
  bool _sendingOtp = false;
  bool _verifyingOtp = false;
  bool _submittingEkyc = false;
  DailyReminderStatus? _dailyReminderStatus;
  bool _loadingDailyReminder = true;
  bool _updatingDailyReminder = false;

  DailyReminderService get _dailyReminders => DailyReminderService.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshDailyReminderStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _whatsapp.dispose();
    _otp.dispose();
    _nik.dispose();
    _ktpName.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _dailyReminders.isSupported) {
      _refreshDailyReminderStatus();
    }
  }

  Future<void> _refreshDailyReminderStatus() async {
    if (!_dailyReminders.isSupported) return;
    try {
      final status = await _dailyReminders.getStatus();
      if (mounted) {
        setState(() {
          _dailyReminderStatus = status;
          _loadingDailyReminder = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _loadingDailyReminder = false);
        showError(context, error.toString());
      }
    }
  }

  Future<void> _setDailyReminder(bool enabled) async {
    if (_updatingDailyReminder) return;
    setState(() => _updatingDailyReminder = true);
    try {
      final activated = enabled ? await _dailyReminders.enable() : false;
      if (!enabled) await _dailyReminders.disable();
      await _refreshDailyReminderStatus();
      if (enabled && !activated && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Izin notifikasi belum aktif. Aktifkan dari pengaturan Android.',
            ),
            action: SnackBarAction(
              label: 'Pengaturan',
              onPressed: _dailyReminders.openNotificationSettings,
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) showError(context, error.toString());
    } finally {
      if (mounted) setState(() => _updatingDailyReminder = false);
    }
  }

  Widget _buildDailyReminderCard() {
    final status = _dailyReminderStatus;
    final hasPermission = status?.permissionGranted ?? false;
    final enabled = (status?.enabled ?? false) && hasPermission;

    return GlassSurface(
      radius: 20,
      child: Padding(
        padding: EdgeInsets.zero,
        child: SwitchListTile.adaptive(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 4,
          ),
          secondary: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.brand100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: AppColors.brand800,
            ),
          ),
          title: const Text(
            'Pengingat harian',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            _loadingDailyReminder
                ? 'Memeriksa pengaturan notifikasi...'
                : hasPermission
                ? 'Pengingat lelang setiap hari sekitar pukul 19.00 WIB.'
                : 'Izinkan notifikasi Android untuk menerima pengingat sekitar pukul 19.00 WIB.',
          ),
          value: enabled,
          onChanged: _loadingDailyReminder || _updatingDailyReminder
              ? null
              : _setDailyReminder,
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _userFuture = widget.repository.me();
      _identityFuture = widget.repository.identityVerification();
    });
    await widget.auth.refreshUser();
  }

  Future<void> _sendOtp(UserAccount user) async {
    if (_sendingOtp) return;
    setState(() => _sendingOtp = true);
    try {
      final whatsapp = _whatsapp.text.trim().isNotEmpty
          ? _whatsapp.text.trim()
          : user.whatsapp;

      if (whatsapp == null || whatsapp.isEmpty) {
        showError(context, 'Masukkan nomor WhatsApp terlebih dahulu.');
        return;
      }

      if (_whatsapp.text.trim().isNotEmpty || !user.whatsappVerified) {
        await widget.repository.updateWhatsapp(whatsapp);
        _whatsapp.clear();
      } else {
        await widget.repository.resendWhatsappOtp();
      }
      setState(() => _editingWhatsapp = false);
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('OTP WhatsApp dikirim.')));
      }
    } catch (error) {
      if (mounted) showError(context, error.toString());
    } finally {
      if (mounted) setState(() => _sendingOtp = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_verifyingOtp) return;
    final code = _otp.text.trim();
    if (code.length != 6) {
      showError(context, 'Masukkan kode OTP 6 digit.');
      return;
    }

    setState(() => _verifyingOtp = true);
    try {
      await widget.repository.verifyWhatsappOtp(code);
      _otp.clear();
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp terverifikasi.')),
        );
      }
    } catch (error) {
      if (mounted) showError(context, error.toString());
    } finally {
      if (mounted) setState(() => _verifyingOtp = false);
    }
  }

  Future<void> _pickKtp() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image != null && mounted) setState(() => _ktpImage = image);
  }

  Future<void> _pickSelfie() async {
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (image != null && mounted) setState(() => _selfieImage = image);
  }

  Future<void> _submitEkyc() async {
    if (_nik.text.trim().length != 16 ||
        _ktpName.text.trim().isEmpty ||
        _ktpImage == null ||
        _selfieImage == null) {
      showError(context, 'Lengkapi NIK, nama KTP, foto KTP, dan selfie.');
      return;
    }

    setState(() => _submittingEkyc = true);
    try {
      await widget.repository.submitIdentityVerification(
        nik: _nik.text.trim(),
        name: _ktpName.text.trim(),
        ktp: _ktpImage!,
        selfie: _selfieImage!,
      );
      _nik.clear();
      _ktpName.clear();
      setState(() {
        _ktpImage = null;
        _selfieImage = null;
      });
      setState(() => _showEkycForm = false);
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengajuan eKYC dikirim.')),
        );
      }
    } catch (error) {
      if (mounted) showError(context, error.toString());
    } finally {
      if (mounted) setState(() => _submittingEkyc = false);
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text(
          'Kamu perlu masuk kembali untuk mengakses lelang, bid, dan profil.',
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Keluar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await widget.auth.logout();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          102 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        children: [
          const SectionHeader(
            title: 'Profil',
            subtitle: 'Verifikasi akun dan kelola akses bid.',
          ),
          const SizedBox(height: 10),
          FutureBuilder<UserAccount>(
            future: _userFuture,
            builder: (context, snapshot) {
              final user = snapshot.data ?? widget.auth.user;
              if (user == null) return const SizedBox.shrink();
              return GlassSurface(
                radius: 20,
                child: Padding(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.brand100,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Icon(
                              Icons.person_outline,
                              color: AppColors.brand800,
                              size: 27,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.name,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 4),
                                Text(user.email),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          TrustChip(
                            label: user.whatsappVerified
                                ? 'WA terverifikasi'
                                : 'WA belum verifikasi',
                            ok: user.whatsappVerified,
                          ),
                          TrustChip(
                            label: 'eKYC ${ekycLabel(user.ekycStatus)}',
                            ok: user.ekycStatus == 'disetujui',
                          ),
                          TrustChip(
                            label: 'Skor ${user.creditScore}',
                            ok: !user.biddingLocked,
                          ),
                        ],
                      ),
                      if (user.biddingLockedReason != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          user.biddingLockedReason!,
                          style: const TextStyle(
                            color: AppColors.danger600,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _confirmLogout,
                        icon: const Icon(Icons.logout),
                        label: const Text('Keluar dari akun'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          FutureBuilder<UserAccount>(
            future: _userFuture,
            builder: (context, snapshot) {
              final user = snapshot.data ?? widget.auth.user;
              if (user == null) {
                return const SizedBox.shrink();
              }
              return _WhatsappVerificationCard(
                user: user,
                controller: _whatsapp,
                otpController: _otp,
                editing: _editingWhatsapp,
                sendingOtp: _sendingOtp,
                verifyingOtp: _verifyingOtp,
                onEdit: () => setState(() {
                  _editingWhatsapp = true;
                  _whatsapp.text = user.whatsapp ?? '';
                }),
                onCancelEdit: () => setState(() {
                  _editingWhatsapp = false;
                  _whatsapp.clear();
                }),
                onSendOtp: () => _sendOtp(user),
                onVerifyOtp: _verifyOtp,
              );
            },
          ),
          const SizedBox(height: 10),
          FutureBuilder<IdentityVerification?>(
            future: _identityFuture,
            builder: (context, snapshot) {
              final identity = snapshot.data;
              final user = widget.auth.user;
              return _IdentityVerificationCard(
                identity: identity,
                ekycStatus: user?.ekycStatus,
                showForm: _showEkycForm,
                nikController: _nik,
                nameController: _ktpName,
                ktpImage: _ktpImage,
                selfieImage: _selfieImage,
                submitting: _submittingEkyc,
                whatsappVerified: user?.whatsappVerified ?? false,
                onShowForm: () => setState(() => _showEkycForm = true),
                onCancelForm: () => setState(() {
                  _showEkycForm = false;
                  _nik.clear();
                  _ktpName.clear();
                  _ktpImage = null;
                  _selfieImage = null;
                }),
                onPickKtp: _pickKtp,
                onPickSelfie: _pickSelfie,
                onSubmit: _submitEkyc,
              );
            },
          ),
          if (_dailyReminders.isSupported) ...[
            const SizedBox(height: 10),
            _buildDailyReminderCard(),
          ],
        ],
      ),
    );
  }
}

class _WhatsappVerificationCard extends StatelessWidget {
  const _WhatsappVerificationCard({
    required this.user,
    required this.controller,
    required this.otpController,
    required this.editing,
    required this.sendingOtp,
    required this.verifyingOtp,
    required this.onEdit,
    required this.onCancelEdit,
    required this.onSendOtp,
    required this.onVerifyOtp,
  });

  final UserAccount user;
  final TextEditingController controller;
  final TextEditingController otpController;
  final bool editing;
  final bool sendingOtp;
  final bool verifyingOtp;
  final VoidCallback onEdit;
  final VoidCallback onCancelEdit;
  final VoidCallback onSendOtp;
  final VoidCallback onVerifyOtp;

  @override
  Widget build(BuildContext context) {
    final hasNumber = user.whatsapp != null && user.whatsapp!.isNotEmpty;
    final needsOtp = hasNumber && !user.whatsappVerified;
    final showNumberField = editing || !hasNumber || !user.whatsappVerified;

    return GlassSurface(
      radius: 20,
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionTitle(
              icon: Icons.phone_android,
              title: 'WhatsApp',
              subtitle: user.whatsappVerified
                  ? 'Nomor aktif dan sudah terverifikasi.'
                  : 'Verifikasi OTP diperlukan untuk membuka akses bid.',
            ),
            if (hasNumber && !editing) ...[
              const SizedBox(height: 10),
              _InlineStatus(
                label: user.whatsapp!,
                ok: user.whatsappVerified,
                message: user.whatsappVerified
                    ? 'Terverifikasi'
                    : 'Menunggu OTP',
              ),
            ],
            if (showNumberField) ...[
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Nomor WhatsApp',
                  hintText: user.whatsapp ?? '081234567890',
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
              ),
            ],
            if (needsOtp) ...[
              const SizedBox(height: 8),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Kode OTP 6 digit',
                  prefixIcon: Icon(Icons.password_outlined),
                  counterText: '',
                ),
              ),
            ],
            const SizedBox(height: 10),
            if (user.whatsappVerified && !editing)
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Update Nomor WhatsApp'),
              )
            else ...[
              FilledButton.icon(
                onPressed: sendingOtp ? null : onSendOtp,
                icon: sendingOtp
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_outlined),
                label: Text(
                  sendingOtp
                      ? 'Mengirim OTP...'
                      : hasNumber
                      ? 'Kirim Ulang OTP'
                      : 'Simpan & Kirim OTP',
                ),
              ),
              if (needsOtp) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: verifyingOtp ? null : onVerifyOtp,
                  icon: verifyingOtp
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.verified_outlined),
                  label: Text(
                    verifyingOtp ? 'Memverifikasi...' : 'Verifikasi OTP',
                  ),
                ),
              ],
              if (editing)
                TextButton(
                  onPressed: onCancelEdit,
                  child: const Text('Batal update nomor'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _IdentityVerificationCard extends StatelessWidget {
  const _IdentityVerificationCard({
    required this.identity,
    required this.ekycStatus,
    required this.showForm,
    required this.nikController,
    required this.nameController,
    required this.ktpImage,
    required this.selfieImage,
    required this.submitting,
    required this.whatsappVerified,
    required this.onShowForm,
    required this.onCancelForm,
    required this.onPickKtp,
    required this.onPickSelfie,
    required this.onSubmit,
  });

  final IdentityVerification? identity;
  final String? ekycStatus;
  final bool showForm;
  final TextEditingController nikController;
  final TextEditingController nameController;
  final XFile? ktpImage;
  final XFile? selfieImage;
  final bool submitting;
  final bool whatsappVerified;
  final VoidCallback onShowForm;
  final VoidCallback onCancelForm;
  final VoidCallback onPickKtp;
  final VoidCallback onPickSelfie;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final status = identity?.status ?? ekycStatus ?? 'belum_diajukan';
    final approved = status == 'disetujui';
    final shouldShowForm = showForm || !approved;

    return GlassSurface(
      radius: 20,
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionTitle(
              icon: Icons.verified_user_outlined,
              title: 'eKYC',
              subtitle: approved
                  ? 'Identitas sudah terverifikasi.'
                  : 'Kirim data KTP dan selfie untuk review admin.',
            ),
            const SizedBox(height: 10),
            _InlineStatus(
              label: identity?.name ?? 'Status eKYC',
              ok: approved,
              message: ekycLabel(status),
            ),
            if (identity?.rejectionReason != null) ...[
              const SizedBox(height: 8),
              Text(
                identity!.rejectionReason!,
                style: const TextStyle(
                  color: AppColors.danger600,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (approved && !showForm) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: onShowForm,
                icon: const Icon(Icons.edit_document),
                label: const Text('Update eKYC'),
              ),
            ],
            if (shouldShowForm) ...[
              const SizedBox(height: 10),
              if (approved)
                TextButton.icon(
                  onPressed: onCancelForm,
                  icon: const Icon(Icons.close),
                  label: const Text('Batal update eKYC'),
                ),
              if (!whatsappVerified) ...[
                const _FormNotice(
                  message:
                      'Verifikasi WhatsApp terlebih dahulu sebelum mengirim eKYC.',
                ),
                const SizedBox(height: 8),
              ],
              TextField(
                controller: nikController,
                keyboardType: TextInputType.number,
                maxLength: 16,
                decoration: const InputDecoration(
                  labelText: 'NIK 16 digit',
                  prefixIcon: Icon(Icons.badge_outlined),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama sesuai KTP',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onPickKtp,
                icon: const Icon(Icons.badge_outlined),
                label: Text(
                  ktpImage == null ? 'Pilih Foto KTP' : 'Foto KTP dipilih',
                ),
              ),
              OutlinedButton.icon(
                onPressed: onPickSelfie,
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(
                  selfieImage == null
                      ? 'Ambil Selfie/Liveness'
                      : 'Selfie dipilih',
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: submitting || !whatsappVerified ? null : onSubmit,
                icon: submitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.verified_user_outlined),
                label: Text(
                  submitting
                      ? 'Mengirim...'
                      : approved
                      ? 'Kirim Update eKYC'
                      : 'Kirim eKYC',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.brand50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.brand800, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.zinc500,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InlineStatus extends StatelessWidget {
  const _InlineStatus({
    required this.label,
    required this.ok,
    required this.message,
  });

  final String label;
  final bool ok;
  final String message;

  @override
  Widget build(BuildContext context) {
    final color = ok ? AppColors.success700 : AppColors.accent700;
    final background = ok ? AppColors.success50 : AppColors.accent50;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: color.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(ok ? Icons.check_circle : Icons.info_outline, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            message,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FormNotice extends StatelessWidget {
  const _FormNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.accent50,
        border: Border.all(color: AppColors.accent700.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.accent700, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.accent700,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TrustChip extends StatelessWidget {
  const TrustChip({required this.label, required this.ok, super.key});

  final String label;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final color = ok ? AppColors.success700 : AppColors.accent700;
    final backgroundColor = ok ? AppColors.success50 : AppColors.accent50;
    return Chip(
      visualDensity: VisualDensity.compact,
      avatar: Icon(
        ok ? Icons.check_circle : Icons.info_outline,
        size: 16,
        color: color,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
        ),
      ),
      backgroundColor: backgroundColor,
      side: BorderSide(color: color.withValues(alpha: 0.18)),
    );
  }
}
