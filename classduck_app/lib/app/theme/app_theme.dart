import 'package:flutter/material.dart';

import '../../shared/theme/app_tokens.dart';

class AppTheme {
  static ThemeData light() {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: AppTokens.duckYellow,
      brightness: Brightness.light,
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppTokens.pageBackground,
      useMaterial3: true,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppTokens.duckYellow,
        selectionColor: AppTokens.duckYellow.withValues(alpha: 0.28),
        selectionHandleColor: AppTokens.duckYellow,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: AppTokens.surface,
        elevation: 0,
        margin: const EdgeInsets.all(AppTokens.space16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radius20),
        ),
      ),
    );
  }
}
