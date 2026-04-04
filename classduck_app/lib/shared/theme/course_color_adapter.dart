import 'package:flutter/material.dart';

class CourseColorAdapter {
  static const List<Color> basePalette = <Color>[
    Color(0xFFD45E6A),
    Color(0xFFCBA42F),
    Color(0xFF4A88D2),
    Color(0xFFB6C223),
    Color(0xFF896ED8),
    Color(0xFF2AA4A2),
    Color(0xFFD68152),
    Color(0xFFA19586),
  ];

  static const List<Color> legacyPalette = <Color>[
    Color(0xFFEAA4AF),
    Color(0xFFF2C27D),
    Color(0xFFA9CDFE),
    Color(0xFF9ED9A2),
    Color(0xFFC7C1F8),
    Color(0xFF8FD8D0),
    Color(0xFFF5B57A),
    Color(0xFFD9C1A5),
  ];

  static Color fromHex(String hex) {
    final String normalized = hex.replaceAll('#', '').trim();
    return Color(int.parse('FF$normalized', radix: 16));
  }

  static Color normalizeLegacy(Color source) {
    for (int i = 0; i < legacyPalette.length; i++) {
      if (source.toARGB32() == legacyPalette[i].toARGB32()) {
        return basePalette[i];
      }
    }
    return source;
  }

  static Color forLight(Color source) {
    final Color normalized = normalizeLegacy(source);
    if (normalized.computeLuminance() > 0.58) {
      return Color.alphaBlend(const Color(0x66000000), normalized);
    }
    return normalized;
  }

  static Color forDark(Color source) {
    final Color normalized = normalizeLegacy(source);
    final HSLColor hsl = HSLColor.fromColor(normalized);
    final double saturation = (hsl.saturation * 0.58).clamp(0.24, 0.62);
    final double lightness = (hsl.lightness * 0.56).clamp(0.20, 0.38);
    final Color toned = hsl
        .withSaturation(saturation)
        .withLightness(lightness)
        .toColor();
    return Color.alphaBlend(const Color(0x33000000), toned);
  }

  static Color adaptive(Color source, Brightness brightness) {
    return brightness == Brightness.dark ? forDark(source) : forLight(source);
  }

  static Color onColor(Color background) {
    final double whiteContrast = _contrastRatio(Colors.white, background);
    final double darkContrast = _contrastRatio(
      const Color(0xFF111111),
      background,
    );
    return whiteContrast >= darkContrast
        ? Colors.white
        : const Color(0xFF111111);
  }

  static double _contrastRatio(Color a, Color b) {
    final double l1 = a.computeLuminance();
    final double l2 = b.computeLuminance();
    final double light = l1 > l2 ? l1 : l2;
    final double dark = l1 > l2 ? l2 : l1;
    return (light + 0.05) / (dark + 0.05);
  }
}
