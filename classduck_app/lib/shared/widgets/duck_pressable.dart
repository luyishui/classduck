import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

class DuckPressable extends StatefulWidget {
  const DuckPressable({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    this.pressedScale = 0.97,
    this.hoverScale = 1.01,
    this.pressOffset = const Offset(0, 0.008),
  });

  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;
  final double pressedScale;
  final double hoverScale;
  final Offset pressOffset;

  @override
  State<DuckPressable> createState() => _DuckPressableState();
}

class _DuckPressableState extends State<DuckPressable> {
  bool _hovering = false;
  bool _pressed = false;

  void _setHovering(bool value) {
    if (_hovering == value) {
      return;
    }
    setState(() {
      _hovering = value;
    });
  }

  void _setPressed(bool value) {
    if (_pressed == value) {
      return;
    }
    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onTap != null;
    final double scale = !enabled
        ? 1
        : _pressed
        ? widget.pressedScale
        : _hovering
        ? widget.hoverScale
        : 1;

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: enabled ? (_) => _setHovering(true) : null,
      onExit: enabled
          ? (_) {
              _setHovering(false);
              _setPressed(false);
            }
          : null,
      child: AnimatedScale(
        scale: scale,
        duration: AppMotion.quick,
        curve: AppMotion.emphasized,
        child: AnimatedSlide(
          offset: enabled && _pressed ? widget.pressOffset : Offset.zero,
          duration: AppMotion.quick,
          curve: AppMotion.standard,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: widget.onTap,
              onTapDown: enabled ? (_) => _setPressed(true) : null,
              onTapUp: enabled ? (_) => _setPressed(false) : null,
              onTapCancel: enabled ? () => _setPressed(false) : null,
              borderRadius: widget.borderRadius,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
