import 'package:flutter/material.dart';

/// Responsive utilities untuk Android tablet 1280x800 (16:10) dengan 2GB RAM
/// Baseline: 800px width untuk landscape, 1280px untuk landscape full
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

  /// Scale terhadap 800px baseline — di device 800px = 1.0
  /// Clamp untuk mencegah scaling terlalu ekstrem di tablet 2GB
  static double get scaleFactor => (screenWidth / 800).clamp(0.85, 1.1);

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
  /// Ukuran font sedikit lebih besar untuk keterbacaan di tablet
  static double get fontXSmall  => 11.0;
  static double get fontSmall   => 12.0;
  static double get fontNormal  => 14.0;
  static double get fontLarge   => 15.0;
  static double get fontXLarge  => 17.0;
  static double get font2XLarge => 19.0;
  static double get font3XLarge => 23.0;
  static double get fontDisplay => 28.0;

  // ── Icon ─────────────────────────────────────────────────
  static double get iconXSmall  => 16.0;
  static double get iconSmall   => 20.0;
  static double get iconNormal  => 24.0;
  static double get iconLarge   => 30.0;
  static double get iconXLarge  => 42.0;
  static double get icon2XLarge => 56.0;

  // ── Button ───────────────────────────────────────────────
  static double get buttonHeightSmall  => 36.0;
  static double get buttonHeightNormal => 44.0;
  static double get buttonHeightLarge  => 52.0;

  // ── Border radius ────────────────────────────────────────
  static double get radiusSmall  => 5.0;
  static double get radiusNormal => 9.0;
  static double get radiusMedium => 11.0;
  static double get radiusLarge  => 15.0;

  // ── Spacing ──────────────────────────────────────────────
  static double get spaceXSmall => 5.0;
  static double get spaceSmall  => 9.0;
  static double get spaceNormal => 13.0;
  static double get spaceLarge  => 21.0;
  static double get spaceXLarge => 29.0;

  // ── Tinggi widget umum ───────────────────────────────────
  static double get appBarHeight        => 64.0;
  static double get extendedAppBarHeight => 104.0;
  static double get tabBarHeight        => 48.0;
  static double get toolbarHeight       => 64.0;
  static double get bottomNavBarHeight  => 62.0;

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

  /// Grid count optimized untuk tablet 1280x800
  static int getGridCount({
    int minItemsPerRow = 2,
    int maxItemsPerRow = 4,
  }) {
    if (screenWidth < 600) return minItemsPerRow;
    if (screenWidth < 900) return 3;
    return maxItemsPerRow;
  }

  static EdgeInsets get deviceSafePadding => _mediaQuery.padding;
  static EdgeInsets get deviceViewInsets  => _mediaQuery.viewInsets;
}

extension ResponsiveExtension on num {
  double get resp => this * ResponsiveUtils.scaleFactor;
}
