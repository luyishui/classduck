import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
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
      transitionDuration: AppMotion.regular,
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(dialogContext).maybePop(),
          child: Center(
            child: GestureDetector(onTap: () {}, child: child),
          ),
        );
      },
      transitionBuilder:
          (transitionContext, animation, secondaryAnimation, widget) {
            final Animation<double> curved = CurvedAnimation(
              parent: animation,
              curve: AppMotion.decelerate,
              reverseCurve: Curves.easeInCubic,
            );

            return AnimatedBuilder(
              animation: curved,
              builder: (BuildContext context, Widget? child) {
                final double blur = blurSigma * curved.value;
                return BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                  child: FadeTransition(
                    opacity: curved,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.03),
                        end: Offset.zero,
                      ).animate(curved),
                      child: ScaleTransition(
                        scale: Tween<double>(
                          begin: 0.96,
                          end: 1,
                        ).animate(curved),
                        child: child,
                      ),
                    ),
                  ),
                );
              },
              child: widget,
            );
          },
    );
  }
}

class DuckModalFrame extends StatelessWidget {
  const DuckModalFrame({super.key, required this.title, required this.child});

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
          color: AppTokens.surface.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(AppTokens.radius24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x2B000000),
              blurRadius: 42,
              offset: Offset(0, 18),
            ),
          ],
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
