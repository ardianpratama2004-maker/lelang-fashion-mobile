import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/session/auth_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/snackbar.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_surface.dart';
import '../domain/auth_repository.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    required this.repository,
    required this.auth,
    required this.register,
    super.key,
  });

  final AuthRepository repository;
  final AuthController auth;
  final bool register;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _submitting = false;
  bool _showPassword = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final result = widget.register
          ? await widget.repository.register(
              _name.text.trim(),
              _email.text.trim(),
              _password.text,
              _confirm.text,
            )
          : await widget.repository.login(_email.text.trim(), _password.text);
      await widget.auth.authenticated(
        result,
        offerDailyReminder: !widget.register,
      );
    } catch (error) {
      if (mounted) showError(context, error.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _AuthBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 760;

              return Center(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    14,
                    14,
                    14,
                    14 + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: wide ? 920 : 480),
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: _AuthBrandPanel(
                                  register: widget.register,
                                ),
                              ),
                              const SizedBox(width: 22),
                              Expanded(child: _buildAuthCard(context)),
                            ],
                          )
                        : Column(
                            children: [
                              _AuthBrandPanel(
                                compact: true,
                                register: widget.register,
                              ),
                              const SizedBox(height: 10),
                              _buildAuthCard(context),
                            ],
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAuthCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isRegister = widget.register;
    final authInputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.line),
    );
    final authFocusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.brand700, width: 1.6),
    );
    final authErrorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.danger600, width: 1.4),
    );
    InputDecoration authInputDecoration({
      required String labelText,
      required String hintText,
      required IconData prefixIcon,
      Widget? suffixIcon,
    }) {
      return InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(prefixIcon),
        suffixIcon: suffixIcon,
        fillColor: Colors.white,
        border: authInputBorder,
        enabledBorder: authInputBorder,
        focusedBorder: authFocusedBorder,
        errorBorder: authErrorBorder,
        focusedErrorBorder: authErrorBorder,
      );
    }

    return GlassSurface(
      radius: 22,
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                children: [
                  if (isRegister) ...[
                    TextFormField(
                      controller: _name,
                      textInputAction: TextInputAction.next,
                      decoration: authInputDecoration(
                        labelText: 'Nama',
                        hintText: 'Ardian Pratama',
                        prefixIcon: Icons.person_outline,
                      ),
                      validator: requiredField,
                    ),
                    const SizedBox(height: 9),
                  ],
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: authInputDecoration(
                      labelText: 'Email',
                      hintText: 'ardian@example.com',
                      prefixIcon: Icons.mail_outline,
                    ),
                    validator: requiredField,
                  ),
                  const SizedBox(height: 9),
                  TextFormField(
                    controller: _password,
                    obscureText: !_showPassword,
                    textInputAction: isRegister
                        ? TextInputAction.next
                        : TextInputAction.done,
                    onFieldSubmitted: (_) {
                      if (!isRegister) _submit();
                    },
                    decoration: authInputDecoration(
                      labelText: 'Password',
                      hintText: 'Masukkan password',
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        tooltip: _showPassword
                            ? 'Sembunyikan password'
                            : 'Tampilkan password',
                      ),
                    ),
                    validator: requiredField,
                  ),
                  if (isRegister) ...[
                    const SizedBox(height: 9),
                    TextFormField(
                      controller: _confirm,
                      obscureText: !_showConfirm,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: authInputDecoration(
                        labelText: 'Konfirmasi Password',
                        hintText: 'Ulangi password',
                        prefixIcon: Icons.verified_user_outlined,
                        suffixIcon: IconButton(
                          onPressed: () =>
                              setState(() => _showConfirm = !_showConfirm),
                          icon: Icon(
                            _showConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          tooltip: _showConfirm
                              ? 'Sembunyikan password'
                              : 'Tampilkan password',
                        ),
                      ),
                      validator: requiredField,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : Icon(isRegister ? Icons.person_add_alt : Icons.login),
                label: Text(
                  _submitting
                      ? 'Memproses...'
                      : isRegister
                      ? 'Daftar'
                      : 'Masuk ke aplikasi',
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _submitting
                    ? null
                    : () => context.go(isRegister ? '/masuk' : '/daftar'),
                child: Text(
                  isRegister
                      ? 'Sudah punya akun? Masuk'
                      : 'Belum punya akun? Daftar',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthBackground extends StatelessWidget {
  const _AuthBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 760) {
          return AppBackground(child: child);
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Image.asset(
                AppAssets.authBackground,
                fit: BoxFit.cover,
                alignment: const Alignment(0.14, -0.26),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.brand950.withValues(alpha: 0.38),
                    AppColors.brand950.withValues(alpha: 0.08),
                    AppColors.brand950.withValues(alpha: 0.16),
                    AppColors.brand950.withValues(alpha: 0.58),
                  ],
                  stops: const [0, 0.32, 0.62, 1],
                ),
              ),
            ),
            child,
          ],
        );
      },
    );
  }
}

class _AuthBrandPanel extends StatelessWidget {
  const _AuthBrandPanel({required this.register, this.compact = false});

  final bool compact;
  final bool register;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GlassSurface(
        radius: compact ? 28 : 22,
        padding: EdgeInsets.all(compact ? 14 : 18),
        color: compact
            ? AppColors.brand950.withValues(alpha: 0.72)
            : AppColors.glass,
        borderColor: compact
            ? Colors.white.withValues(alpha: 0.34)
            : AppColors.line,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: compact ? 48 : 54,
                  height: compact ? 48 : 54,
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brand950.withValues(alpha: 0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Image.asset(AppAssets.logo),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lelang Fashion',
                        style: TextStyle(
                          color: compact ? Colors.white : AppColors.ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Marketplace lelang fashion',
                        style: TextStyle(
                          color: compact ? Colors.white70 : AppColors.zinc500,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: compact ? AppColors.accent500 : AppColors.brand800,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    register ? Icons.person_add_alt : Icons.login,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
            SizedBox(height: compact ? 16 : 20),
            Text(
              register ? 'Buat akun lelang' : 'Masuk ke akunmu',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: compact ? Colors.white : AppColors.ink,
                fontWeight: FontWeight.w900,
                height: 1.08,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              register
                  ? 'Daftar dulu, lalu verifikasi WhatsApp dan eKYC di profil.'
                  : 'Lanjutkan bid, pantau favorit, dan chat admin.',
              style: TextStyle(
                color: compact ? Colors.white70 : AppColors.zinc500,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _AuthTrustPill(
                  icon: Icons.verified_user_outlined,
                  label: 'eKYC',
                  photoStyle: compact,
                ),
                _AuthTrustPill(
                  icon: Icons.phone_android,
                  label: 'WhatsApp OTP',
                  photoStyle: compact,
                ),
                _AuthTrustPill(
                  icon: Icons.gavel,
                  label: 'Live bid',
                  photoStyle: compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthTrustPill extends StatelessWidget {
  const _AuthTrustPill({
    required this.icon,
    required this.label,
    this.photoStyle = false,
  });

  final IconData icon;
  final String label;
  final bool photoStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: photoStyle
            ? Colors.white.withValues(alpha: 0.14)
            : AppColors.brand50,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: photoStyle
              ? Colors.white.withValues(alpha: 0.28)
              : AppColors.brand100,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: photoStyle ? Colors.white : AppColors.brand800,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: photoStyle ? Colors.white : AppColors.brand800,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
