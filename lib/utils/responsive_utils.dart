import 'package:flutter/material.dart';

/// Responsive utilities untuk 800x1280 (16:10) 8-inch tablet @ 189 ppi
class ResponsiveUtils {
  static late MediaQueryData _mediaQuery;
  static late Size _screenSize;

  static void init(BuildContext context) {
    _mediaQuery = MediaQuery.of(context);
    _screenSize = _mediaQuery.size;
  }

  static double get screenWidth => _screenSize.width;
  static double get screenHeight => _screenSize.height;
  static double get aspectRatio => _screenSize.aspectRatio;

  /// Scale terhadap 800px baseline — di device 800px = 1.0 (no-op)
  static double get scaleFactor => (screenWidth / 800).clamp(0.75, 1.25);

  // ── Padding ──────────────────────────────────────────────
  static EdgeInsets get paddingSmall =>
      EdgeInsets.all(6 * scaleFactor);
  static EdgeInsets get paddingNormal =>
      EdgeInsets.all(12 * scaleFactor);
  static EdgeInsets get paddingLarge =>
      EdgeInsets.all(18 * scaleFactor);
  static EdgeInsets get paddingXLarge =>
      EdgeInsets.all(24 * scaleFactor);

  static EdgeInsets get paddingHorizontalSmall =>
      EdgeInsets.symmetric(horizontal: 6 * scaleFactor);
  static EdgeInsets get paddingHorizontalNormal =>
      EdgeInsets.symmetric(horizontal: 12 * scaleFactor);
  static EdgeInsets get paddingHorizontalLarge =>
      EdgeInsets.symmetric(horizontal: 18 * scaleFactor);

  static EdgeInsets get paddingVerticalSmall =>
      EdgeInsets.symmetric(vertical: 6 * scaleFactor);
  static EdgeInsets get paddingVerticalNormal =>
      EdgeInsets.symmetric(vertical: 10 * scaleFactor);
  static EdgeInsets get paddingVerticalLarge =>
      EdgeInsets.symmetric(vertical: 16 * scaleFactor);

  // ── Font ─────────────────────────────────────────────────
  static double get fontXSmall  => 10.0;
  static double get fontSmall   => 11.0;
  static double get fontNormal  => 13.0;
  static double get fontLarge   => 14.0;
  static double get fontXLarge  => 16.0;
  static double get font2XLarge => 18.0;
  static double get font3XLarge => 22.0;
  static double get fontDisplay => 26.0;

  // ── Icon ─────────────────────────────────────────────────
  static double get iconXSmall  => 14.0;
  static double get iconSmall   => 18.0;
  static double get iconNormal  => 22.0;
  static double get iconLarge   => 28.0;
  static double get iconXLarge  => 40.0;
  static double get icon2XLarge => 52.0;

  // ── Button ───────────────────────────────────────────────
  static double get buttonHeightSmall  => 32.0;
  static double get buttonHeightNormal => 40.0;
  static double get buttonHeightLarge  => 48.0;

  // ── Border radius ────────────────────────────────────────
  static double get radiusSmall  => 4.0;
  static double get radiusNormal => 8.0;
  static double get radiusMedium => 10.0;
  static double get radiusLarge  => 14.0;

  // ── Spacing ──────────────────────────────────────────────
  static double get spaceXSmall => 4.0;
  static double get spaceSmall  => 8.0;
  static double get spaceNormal => 12.0;
  static double get spaceLarge  => 20.0;
  static double get spaceXLarge => 28.0;

  // ── Tinggi widget umum ───────────────────────────────────
  static double get appBarHeight        => 60.0;
  static double get extendedAppBarHeight => 100.0;
  static double get tabBarHeight        => 44.0;
  static double get toolbarHeight       => 60.0;
  static double get bottomNavBarHeight  => 58.0;

  // ── Orientasi ────────────────────────────────────────────
  static bool get isPortrait  => screenHeight > screenWidth;
  static bool get isLandscape => screenWidth > screenHeight;

  // ── Helper ───────────────────────────────────────────────
  static double getResponsiveWidth({
    required double minWidth,
    double maxWidth = double.infinity,
  }) {
    return (screenWidth * 0.9).clamp(minWidth, maxWidth);
  }

  static int getGridCount({
    int minItemsPerRow = 2,
    int maxItemsPerRow = 4,
  }) {
    if (screenWidth < 600) return minItemsPerRow;
    if (screenWidth < 1000) return 3;
    return maxItemsPerRow;
  }

  static EdgeInsets get deviceSafePadding => _mediaQuery.padding;
  static EdgeInsets get deviceViewInsets  => _mediaQuery.viewInsets;
}

extension ResponsiveExtension on num {
  double get resp => this * ResponsiveUtils.scaleFactor;
}
