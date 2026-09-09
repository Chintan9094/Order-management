import 'package:flutter/painting.dart';

abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 16,
  );

  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(10));
  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(16));
  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(22));
}
