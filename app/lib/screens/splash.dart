import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/auth.dart';
import '../theme.dart';
import 'auth/login.dart';
import 'customer/home.dart';
import 'owner/dashboard.dart';
import 'admin/dashboard.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    if (auth.isLoading) {
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

    if (!auth.isLoggedIn) return const LoginScreen();
    if (auth.isOwner) return const OwnerDashboard();
    if (auth.isAdmin) return const AdminDashboard();
    return const CustomerHome();
  }
}