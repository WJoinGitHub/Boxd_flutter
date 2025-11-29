import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';
import 'package:flutter_boxd_app_flow/pages/login/register_email_page.dart';
import 'package:flutter_boxd_app_flow/pages/login/verification_page.dart';
import 'package:flutter_boxd_app_flow/services/api_client.dart';
import 'package:flutter_boxd_app_flow/services/user_service.dart';
import 'package:flutter_boxd_app_flow/utils/app_colors.dart';
import 'package:flutter_boxd_app_flow/widgets/app_text_field.dart';

class EmailLoginPage extends StatefulWidget {
  const EmailLoginPage({super.key});

  @override
  State<EmailLoginPage> createState() => _EmailLoginPageState();
}

class _EmailLoginPageState extends State<EmailLoginPage> {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _pwdCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  bool get _canLogin => _isEmail(_emailCtrl.text) && _pwdCtrl.text.isNotEmpty;

  bool _isEmail(String v) {
    if (v.isEmpty) return false;
    final emailReg =
        RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
    return emailReg.hasMatch(v);
  }

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      final result = await ApiClient.login(
        email: _emailCtrl.text,
        password: _pwdCtrl.text,
      );
      
      if (result['code'] == 200 && mounted) {
        final data = result['data'];
        if (data != null) {
          final tokens = data['tokens'];
          final user = data['user'];
          
          if (tokens != null && user != null) {
            await UserService().saveTokens(
              accessToken: tokens['access_token'],
              refreshToken: tokens['refresh_token'],
              expiresAt: tokens['expires_at'],
            );
            
            final userInfo = UserInfo.fromJson(user);
            UserService().saveUserInfo(userInfo);
          }
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('登录成功！')),
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? '登录失败')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('登录失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: AppColors.pageBg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 13),
              Center(
                child: SizedBox(
                  height: 58,
                  child: Assets.login.images.logo.image(fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 25),
              AppTextField(
                controller: _emailCtrl,
                labelText: 'Enter your email',
                keyboardType: TextInputType.emailAddress,
                suffixIcon: _emailCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _emailCtrl.clear()),
                      )
                    : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 13),
              AppTextField(
                controller: _pwdCtrl,
                labelText: 'Password',
                obscureText: _obscure,
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_pwdCtrl.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _pwdCtrl.clear()),
                      ),
                    IconButton(
                      icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ],
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 2),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => VerificationPage(
                              codeLength: 4,
                              isForReset: true,
                              email: _emailCtrl.text,
                            )));
                  },
                  child: Text(
                    'Forget Password?',
                    style: TextStyle(color: AppColors.orange, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _canLogin && !_loading ? _login : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: Center(
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Sign In',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const RegisterEmailPage()));
                    },
                    child: Text(
                      'Sign Up',
                      style: TextStyle(color: AppColors.orange, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
