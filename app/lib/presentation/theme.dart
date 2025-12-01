import 'package:flutter/material.dart';

final Color kBackgroundColor = Color(0xFF121212);
final Color kSurfaceColor = Color(0xFF1E1E1E);
final Color kAccentColor = Color(0xFF4FD1C5);
final Color kPrimaryTextColor = Color(0xFFFAFAFA);
final Color kSecondaryTextColor = Color(0xFFA0A0A0);

final Color kRiskHigh = Color(0xFFE57373);
final Color kRiskMedium = Color(0xFFFFD54F);
final Color kRiskLow = Color(0xFF81C784);

ThemeData buildDarkTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: kBackgroundColor,
    primaryColor: kAccentColor,
    cardColor: kSurfaceColor,
    fontFamily: 'Roboto',
    appBarTheme: AppBarTheme(
      backgroundColor: kSurfaceColor,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: kPrimaryTextColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: kPrimaryTextColor),
    ),
    textTheme: TextTheme(
      headlineSmall: TextStyle(
          color: kPrimaryTextColor,
          fontWeight: FontWeight.bold,
          fontSize: 26),
      titleMedium:
          TextStyle(color: kPrimaryTextColor, fontWeight: FontWeight.bold),
      bodyMedium: TextStyle(color: kSecondaryTextColor, fontSize: 16),
      labelLarge: TextStyle(
        color: kBackgroundColor,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kAccentColor,
        foregroundColor: kBackgroundColor,
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: kAccentColor,
      titleTextStyle:
          TextStyle(color: kPrimaryTextColor, fontSize: 16),
      subtitleTextStyle: TextStyle(color: kSecondaryTextColor),
    ),
  );
}