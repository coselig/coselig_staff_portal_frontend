import 'dart:async';
import 'dart:js' as js;
import 'package:coselig_staff_portal/main.dart';
import 'package:coselig_staff_portal/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:universal_html/html.dart' as html;

class LoginFrame extends StatefulWidget {
  const LoginFrame({super.key});

  @override
  State<LoginFrame> createState() => _LoginFrameState();
}

class _LoginFrameState extends State<LoginFrame> {
  TextEditingController accountController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Color.fromARGB(28, 211, 80, 40),
      ),
      padding: const EdgeInsets.all(16.0),
      width: MediaQuery.of(context).size.width * 0.4,
      constraints: BoxConstraints(
        minHeight: 250,
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          TextField(
            controller: accountController,
            decoration: const InputDecoration(labelText: '電子郵件/帳號'),
          ),
          TextField(
            controller: passwordController,
            decoration: const InputDecoration(labelText: '密碼'),
            obscureText: true,
          ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  final success = await authService.login(
                    accountController.text,
                    passwordController.text,
                  );
                  if (success) {
                    if (mounted) {
                      navigatorKey.currentState!.pushReplacementNamed('/home');
                    }
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
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () async {
                  try {
                    // 初始化 Google Identity Services
                    html.ScriptElement script = html.ScriptElement()
                      ..src = 'https://accounts.google.com/gsi/client'
                      ..async = true
                      ..defer = true;
                    html.document.head?.append(script);

                    // 等待腳本載入
                    await Future.delayed(const Duration(seconds: 1));

                    // 初始化 GIS
                    html.ScriptElement initScript = html.ScriptElement()
                      ..innerHtml = '''
                        window.googleLoginResult = null;
                        window.googleLoginComplete = null;
                        if (window.google && window.google.accounts && window.google.accounts.id) {
                          window.google.accounts.id.initialize({
                            client_id: '120974904090-7i1lmj710vvvfjaf71du6tdb4sun8i8q.apps.googleusercontent.com',
                            callback: function(response) {
                              window.googleLoginResult = response.credential;
                              // 通知 Flutter 應用程式登入完成
                              if (window.googleLoginComplete) {
                                window.googleLoginComplete(response.credential);
                              }
                            },
                            scope: 'email'
                          });

                          // 立即顯示 One Tap 提示
                          window.google.accounts.id.prompt();
                        }
                      ''';
                    html.document.head?.append(initScript);

                    // 等待用戶完成登入 - 使用輪詢方式檢查結果
                    String? idToken;
                    for (int i = 0; i < 120; i++) {
                      await Future.delayed(const Duration(milliseconds: 500));
                      try {
                        // 使用 js 來訪問 window 屬性
                        final result = js.context['googleLoginResult'];
                        if (result != null &&
                            result is String &&
                            result.isNotEmpty) {
                          idToken = result;
                          // 清除結果
                          js.context['googleLoginResult'] = null;
                          break;
                        }
                      } catch (e) {
                        // 忽略屬性訪問錯誤，繼續輪詢
                      }
                    }

                    if (idToken != null) {
                      // 發送 ID Token 到後端驗證
                      final success = await authService.verifyGoogleToken(
                        idToken,
                      );
                      if (success) {
                        if (mounted) {
                          navigatorKey.currentState!.pushReplacementNamed(
                            '/home',
                          );
                        }
                      } else {
                        // 登入失敗，顯示錯誤訊息
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(authService.message)),
                          );
                        }
                      }
                    } else {
                      // 用戶取消或超時
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Google 登入已取消或超時')),
                        );
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Google 登入錯誤: $e')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.login),
                label: const Text('使用 Google 登入'),
                style: OutlinedButton.styleFrom(
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
                  side: const BorderSide(color: Colors.blue),
                ),
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () {
                  navigatorKey.currentState!.pushNamed('/privacy');
                },
                child: const Text(
                  '隱私權政策',
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            // SizedBox(height: 8),
          //     child: Text(
          //       authService.message,
          //       style: const TextStyle(fontFamily: 'Courier', fontSize: 14),
          //     ),
          //   ),
          // ),
          ],
        ),
      ),
    );
  }
}
