import 'dart:async';

import 'package:coselig_staff_portal/main.dart';
import 'package:coselig_staff_portal/services/attendance_service.dart';
import 'package:coselig_staff_portal/services/auth_service.dart';
import 'package:coselig_staff_portal/services/ui_settings_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/web_only.dart' as google_web;
import 'package:provider/provider.dart';

class LoginFrame extends StatefulWidget {
  const LoginFrame({super.key});

  @override
  State<LoginFrame> createState() => _LoginFrameState();
}

class _LoginFrameState extends State<LoginFrame> {
  static const String _googleClientId =
      '120974904090-7i1lmj710vvvfjaf71du6tdb4sun8i8q.apps.googleusercontent.com';

  final TextEditingController accountController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  StreamSubscription<GoogleSignInAuthenticationEvent>? _googleAuthSubscription;
  bool showPasswordLogin = false;
  bool _isGoogleReady = !kIsWeb;
  bool _isGoogleSigningIn = false;
  String? _googleErrorMessage;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      unawaited(_initializeGoogleSignIn());
    }
  }

  @override
  void dispose() {
    _googleAuthSubscription?.cancel();
    accountController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _initializeGoogleSignIn() async {
    try {
      await _googleSignIn.initialize(
        clientId: _googleClientId,
      );

      _googleAuthSubscription = _googleSignIn.authenticationEvents.listen(
        (event) {
          if (event is GoogleSignInAuthenticationEventSignIn) {
            unawaited(_handleGoogleAuthentication(event.user));
          }
        },
        onError: _handleGoogleAuthenticationError,
      );

      if (!mounted) return;
      setState(() {
        _isGoogleReady = true;
        _googleErrorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGoogleReady = false;
        _googleErrorMessage = 'Google 登入初始化失敗: $e';
      });
    }
  }

  void _handleGoogleAuthenticationError(Object error) {
    if (!mounted) return;
    setState(() {
      _isGoogleSigningIn = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Google 登入錯誤: $error')),
    );
  }

  Future<void> _handleGoogleAuthentication(GoogleSignInAccount user) async {
    if (_isGoogleSigningIn || !mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final authService = context.read<AuthService>();
    final uiSettingsProvider = context.read<UiSettingsProvider>();
    final attendanceService = context.read<AttendanceService>();

    setState(() {
      _isGoogleSigningIn = true;
    });

    try {
      final String? idToken = user.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Google 沒有回傳可用的登入憑證')),
        );
        return;
      }

      final success = await authService.verifyGoogleToken(idToken);
      if (!mounted) return;

      if (success) {
        uiSettingsProvider.bindAuthService(authService);
        attendanceService.fetchAndCacheWorkingStaff();
        navigatorKey.currentState!.pushReplacementNamed(
          authService.isCustomer ? '/customer_home' : '/home',
        );
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(authService.message)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Google 登入錯誤: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleSigningIn = false;
        });
      }
    }
  }

  Widget _buildGoogleLoginSection({
    required BuildContext context,
    required double buttonWidth,
    required AuthService authService,
  }) {
    final bool isBusy = _isGoogleSigningIn || authService.isLoading;

    if (!kIsWeb) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.desktop_windows_outlined),
          label: const Text('Google 登入目前先只支援網頁版'),
        ),
      );
    }

    if (_googleErrorMessage != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.error_outline),
              label: const Text('Google 登入目前無法使用'),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _googleErrorMessage!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 13,
            ),
          ),
        ],
      );
    }

    if (!_isGoogleReady) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: const OutlinedButton(
          onPressed: null,
          child: Text('Google 登入載入中...'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 56,
          child: IgnorePointer(
            ignoring: isBusy,
            child: Opacity(
              opacity: isBusy ? 0.7 : 1,
              child: Center(
                child: google_web.renderButton(
                  configuration: google_web.GSIButtonConfiguration(
                    theme: google_web.GSIButtonTheme.outline,
                    text: google_web.GSIButtonText.signinWith,
                    size: google_web.GSIButtonSize.large,
                    shape: google_web.GSIButtonShape.rectangular,
                    minimumWidth: buttonWidth,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (isBusy) ...[
          const SizedBox(height: 8),
          const Text(
            '正在驗證 Google 登入...',
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final frameWidth = isSmallScreen ? screenWidth * 0.85 : screenWidth * 0.4;
    final buttonWidth = (frameWidth - 32).clamp(220.0, 400.0).toDouble();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color.fromARGB(28, 211, 80, 40),
      ),
      padding: const EdgeInsets.all(16.0),
      width: frameWidth,
      constraints: BoxConstraints(
        minHeight: isSmallScreen ? 300 : 250,
        maxHeight:
            MediaQuery.of(context).size.height * (isSmallScreen ? 0.9 : 0.8),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildGoogleLoginSection(
              context: context,
              buttonWidth: buttonWidth,
              authService: authService,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    showPasswordLogin = !showPasswordLogin;
                  });
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  showPasswordLogin ? '隱藏帳號密碼登入' : '使用帳號密碼登入',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            if (showPasswordLogin) ...[
              const SizedBox(height: 16),
              TextField(
                controller: accountController,
                decoration: const InputDecoration(labelText: '電子郵件/帳號'),
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: '密碼'),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    final uiSettingsProvider = context
                        .read<UiSettingsProvider>();
                    final attendanceService = context.read<AttendanceService>();
                    final success = await authService.login(
                      accountController.text,
                      passwordController.text,
                    );
                    if (!mounted) return;
                    if (success) {
                      uiSettingsProvider.bindAuthService(authService);
                      attendanceService.fetchAndCacheWorkingStaff();
                      navigatorKey.currentState!.pushReplacementNamed(
                        authService.isCustomer ? '/customer_home' : '/home',
                      );
                    }
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 32,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 3,
                    tapTargetSize: MaterialTapTargetSize.padded,
                  ),
                  child: const Text('登入'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
