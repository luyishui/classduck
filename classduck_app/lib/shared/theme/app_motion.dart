import 'package:flutter/animation.dart';

class AppMotion {
  static const Duration quick = Duration(milliseconds: 160);
  static const Duration regular = Duration(milliseconds: 260);
  static const Duration leisurely = Duration(milliseconds: 360);

  static const Curve standard = Cubic(0.2, 0.0, 0.0, 1.0);
  static const Curve emphasized = Cubic(0.2, 0.8, 0.2, 1.0);
  static const Curve decelerate = Cubic(0.05, 0.7, 0.1, 1.0);
}
