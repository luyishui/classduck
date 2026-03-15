import 'package:flutter/foundation.dart';

class AppearanceState {
  const AppearanceState({
    required this.themeMode,
    this.backgroundBytes,
    this.backgroundName,
  });

  final String themeMode;
  final Uint8List? backgroundBytes;
  final String? backgroundName;

  AppearanceState copyWith({
    String? themeMode,
    Uint8List? backgroundBytes,
    bool clearBackground = false,
    String? backgroundName,
  }) {
    return AppearanceState(
      themeMode: themeMode ?? this.themeMode,
      backgroundBytes: clearBackground ? null : (backgroundBytes ?? this.backgroundBytes),
      backgroundName: clearBackground ? null : (backgroundName ?? this.backgroundName),
    );
  }
}

class AppearanceStore {
  AppearanceStore._();

  static final ValueNotifier<AppearanceState> state =
      ValueNotifier<AppearanceState>(const AppearanceState(themeMode: 'light'));

  static void setThemeMode(String mode) {
    state.value = state.value.copyWith(themeMode: mode);
  }

  static void setBackground({required Uint8List bytes, required String name}) {
    state.value = state.value.copyWith(
      backgroundBytes: bytes,
      backgroundName: name,
      clearBackground: false,
    );
  }

  static void clearBackground() {
    state.value = state.value.copyWith(clearBackground: true);
  }
}
