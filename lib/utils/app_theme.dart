import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryGreen = Color(0xFF27C840);
  static const Color darkBlue = Color(0xFF0C085C);
  static const Color orange = Color(0xFFFF7A28);
  static const Color neonGreen = Color(0xFF00FF2E);
  static const Color backgroundLight = Color(0xFFF4F4F4);
  static const Color gray = Color(0xFFACACAC);
  static const Color grayBorder = Color(0xFFE6E6E6);
  static const Color grayDivider = Color(0xFF8B8B8B);
  static const Color grayProfileBg = Color(0xFFD9D9D9);
  static const Color searchHint = Color(0xFFBDBDBD);
  static const Color error = Color(0xFFE53935);
}

class AppTypography {
  static const TextStyle headingBold = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.darkBlue,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.black,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Colors.black,
  );

  static const TextStyle price = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Colors.black87,
  );
}
