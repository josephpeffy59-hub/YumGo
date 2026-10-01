import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'state/auth.dart';
import 'screens/auth/login.dart';
import 'screens/customer/home.dart';
import 'screens/owner/dashboard.dart';
import 'screens/admin/dashboard.dart';

void main() => runApp(const YumGoApp());

class YumGoApp extends StatelessWidget {
  const YumGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthState()..bootstrap(),
      child: MaterialApp(
        title: 'YumGo',
        debugShowCheckedModeBanner: false,
        theme: appTheme(),
        home: const RootGate(),
      ),
    );
  }
}

class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    if (auth.isLoading) {
      return const _SplashLoadingScreen();
    }
    if (!auth.isLoggedIn) {
      return const LoginScreen();
    }
    if (auth.isOwner) {
      return const OwnerDashboard();
    }
    if (auth.isAdmin) {
      return const AdminDashboard();
    }
    return const CustomerHome();
  }
}

class _SplashLoadingScreen extends StatelessWidget {
  const _SplashLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: kRed,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restaurant_menu, color: kWhite, size: 72),
            SizedBox(height: 20),
            Text(
              'YumGo',
              style: TextStyle(
                color: kWhite,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Order. Chat. Enjoy.',
              style: TextStyle(color: kWhite, fontSize: 14),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(color: kWhite),
          ],
        ),
      ),
    );
  }
}