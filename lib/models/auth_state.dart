import 'package:flutter/material.dart';

enum LoginStatus {
  success,
  failed,
  cancelled,
  loading,
}

class AuthUser {
  final String id;
  final String? email;
  final String? name;
  final String? photoUrl;
  final String loginType; // 'google', 'apple', 'facebook', 'email'

  const AuthUser({
    required this.id,
    this.email,
    this.name,
    this.photoUrl,
    required this.loginType,
  });
}

class AuthStateManager extends ChangeNotifier {
  static final AuthStateManager _instance = AuthStateManager._internal();
  factory AuthStateManager() => _instance;
  AuthStateManager._internal();

  AuthUser? _currentUser;
  LoginStatus _loginStatus = LoginStatus.loading;
  String? _errorMessage;

  AuthUser? get currentUser => _currentUser;
  LoginStatus get loginStatus => _loginStatus;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;

  void setLoading() {
    _loginStatus = LoginStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void setSuccess(AuthUser user) {
    _currentUser = user;
    _loginStatus = LoginStatus.success;
    _errorMessage = null;
    notifyListeners();
  }

  void setFailed(String error) {
    _loginStatus = LoginStatus.failed;
    _errorMessage = error;
    notifyListeners();
  }

  void setCancelled() {
    _loginStatus = LoginStatus.cancelled;
    _errorMessage = null;
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _loginStatus = LoginStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void showMessage(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}
