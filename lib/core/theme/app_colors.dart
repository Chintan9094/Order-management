import 'package:flutter/material.dart';

/// Visual direction: charcoal ink + warm saffron on cool mist backgrounds.
abstract final class AppColors {
  static const Color ink = Color(0xFF0F1419);
  static const Color inkSoft = Color(0xFF2C3544);
  static const Color mist = Color(0xFFF5F6F8);
  static const Color mistDeep = Color(0xFFE8EAEE);
  static const Color stone = mist;
  static const Color stoneDark = mistDeep;
  static const Color surface = Color(0xFFFFFFFF);
  static const Color saffron = Color(0xFFE8910F);
  static const Color saffronDark = Color(0xFFC4740A);
  static const Color saffronSoft = Color(0xFFFFF4E5);
  static const Color sage = Color(0xFF2F6B52);
  static const Color sageSoft = Color(0xFFE6F3EC);
  static const Color danger = Color(0xFFC62828);
  static const Color dangerSoft = Color(0xFFFDECEA);
  static const Color warning = Color(0xFFD97706);
  static const Color info = Color(0xFF2563EB);
  static const Color infoSoft = Color(0xFFEFF4FF);
  static const Color muted = Color(0xFF6B7280);
  static const Color outline = Color(0xFFE2E5EA);
  static const Color outlineStrong = Color(0xFFC9CED6);

  static const Color statusPending = Color(0xFFD97706);
  static const Color statusPreparing = Color(0xFF2563EB);
  static const Color statusReady = Color(0xFF2F6B52);
  static const Color statusPaid = Color(0xFF15803D);
  static const Color statusCancelled = Color(0xFF6B7280);
}
