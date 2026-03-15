import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

class DuckModal {
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    Color barrierColor = const Color(0x8A000000),
    double blurSigma = 6,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierLabel: 'duck-modal',
      barrierDismissible: true,
      barrierColor: barrierColor,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onDoubleTap: () => Navigator.of(context).maybePop(),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: Center(
              child: GestureDetector(
                onTap: () {},
                child: child,
              ),
            ),
          ),
        );
      },
      transitionBuilder:
          (transitionContext, animation, secondaryAnimation, widget) {
        return FadeTransition(
          opacity: animation,
          child: widget,
        );
      },
    );
  }
}

class DuckModalFrame extends StatelessWidget {
  const DuckModalFrame({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(AppTokens.space16),
        decoration: BoxDecoration(
          color: AppTokens.surface,
          borderRadius: BorderRadius.circular(AppTokens.radius24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: AppTokens.space8),
            child,
          ],
        ),
      ),
    );
  }
}
