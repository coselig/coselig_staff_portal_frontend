import 'dart:async';

import 'package:coselig_staff_portal/main.dart';
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

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  StreamSubscription<GoogleSignInAuthenticationEvent>? _googleAuthSubscription;
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
    super.dispose();
  }

  Future<void> _initializeGoogleSignIn() async {
    try {
      await _googleSignIn.initialize(clientId: _googleClientId);

      _googleAuthSubscription = _googleSignIn.authenticationEvents.listen((
        event,
      ) {
        if (event is GoogleSignInAuthenticationEventSignIn) {
          unawaited(_handleGoogleAuthentication(event.user));
        }
      }, onError: _handleGoogleAuthenticationError);

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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Google 登入錯誤: $error')));
  }

  Future<void> _handleGoogleAuthentication(GoogleSignInAccount user) async {
    if (_isGoogleSigningIn || !mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final authService = context.read<AuthService>();
    final uiSettingsProvider = context.read<UiSettingsProvider>();

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
        navigatorKey.currentState!.pushReplacementNamed(
          authService.isCustomer ? '/customer_home' : '/home',
        );
      } else {
        messenger.showSnackBar(SnackBar(content: Text(authService.message)));
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Google 登入錯誤: $e')));
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
    final brightness = Theme.of(context).brightness;
    final googleButtonTheme = brightness == Brightness.dark
        ? google_web.GSIButtonTheme.filledBlack
        : google_web.GSIButtonTheme.outline;

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
                    theme: googleButtonTheme,
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
          const Text('正在驗證 Google 登入...', textAlign: TextAlign.center),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final screenWidth = MediaQuery.of(context).size.width;
    final frameWidth = (screenWidth < 600 ? screenWidth * 0.85 : 360.0)
        .clamp(220.0, 400.0)
        .toDouble();

    return SizedBox(
      width: frameWidth,
      child: _buildGoogleLoginSection(
        context: context,
        buttonWidth: frameWidth,
        authService: authService,
      ),
    );
  }
}
