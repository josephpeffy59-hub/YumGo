import 'package:flutter/foundation.dart';
import '../api.dart';

class AuthState extends ChangeNotifier {
  Map<String, dynamic>? user;
  bool _loading = true;

  bool get isLoading => _loading;
  bool get isLoggedIn => user != null;
  String? get role => user?['role'];
  bool get isCustomer => role == 'CUSTOMER';
  bool get isOwner => role == 'OWNER';
  bool get isAdmin => role == 'ADMIN';

  Future<void> bootstrap() async {
    _loading = true;
    notifyListeners();
    await Api.loadToken();
    if (Api.token != null) {
      try {
        user = await Api.get('/auth/me');
      } catch (_) {
        await Api.saveToken(null);
        user = null;
      }
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final r = await Api.post('/auth/login', {
      'email': email,
      'password': password,
    });
    await Api.saveToken(r['token']);
    user = r['user'];
    notifyListeners();
  }

  Future<void> register(Map<String, dynamic> body) async {
    final r = await Api.post('/auth/register', body);
    await Api.saveToken(r['token']);
    user = r['user'];
    notifyListeners();
  }

  Future<void> logout() async {
    await Api.saveToken(null);
    user = null;
    notifyListeners();
  }
}