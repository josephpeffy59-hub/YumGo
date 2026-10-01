import 'package:flutter/material.dart';

const kRed = Color(0xFFD32F2F);
const kRedDark = Color(0xFFB71C1C);
const kWhite = Colors.white;
const kGrey = Color(0xFFF7F7F7);
const kBorder = Color(0xFFEEEEEE);

ThemeData appTheme() {
  final base = ThemeData.light(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: kWhite,
    colorScheme: base.colorScheme.copyWith(
      primary: kRed,
      secondary: kRedDark,
      surface: kWhite,
      onPrimary: kWhite,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: kWhite,
      foregroundColor: kRed,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: kRed,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kRed,
        foregroundColor: kWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kRed,
        side: const BorderSide(color: kRed),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kGrey,
      hintStyle: const TextStyle(color: Colors.black45),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kRed, width: 2),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: kWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: kBorder),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: kWhite,
      selectedItemColor: kRed,
      unselectedItemColor: Colors.black45,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
  );
}

class YumGoLogo extends StatelessWidget {
  final double size;
  final Color color;
  const YumGoLogo({super.key, this.size = 32, this.color = kWhite});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.restaurant_menu, color: color, size: size),
        const SizedBox(width: 8),
        Text(
          'YumGo',
          style: TextStyle(
            color: color,
            fontSize: size * 0.75,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}