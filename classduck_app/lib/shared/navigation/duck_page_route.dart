import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

class DuckPageRoute<T> extends PageRouteBuilder<T> {
  DuckPageRoute({
    required WidgetBuilder builder,
    super.settings,
  }) : super(
         pageBuilder: (
           BuildContext context,
           Animation<double> animation,
           Animation<double> secondaryAnimation,
         ) {
           return builder(context);
         },
         transitionDuration: AppMotion.regular,
         reverseTransitionDuration: const Duration(milliseconds: 220),
         transitionsBuilder: (
           BuildContext context,
           Animation<double> animation,
           Animation<double> secondaryAnimation,
           Widget child,
         ) {
           final Animation<double> curved = CurvedAnimation(
             parent: animation,
             curve: AppMotion.decelerate,
             reverseCurve: Curves.easeInCubic,
           );

           return FadeTransition(
             opacity: curved,
             child: SlideTransition(
               position: Tween<Offset>(
                 begin: const Offset(0, 0.04),
                 end: Offset.zero,
               ).animate(curved),
               child: ScaleTransition(
                 scale: Tween<double>(begin: 0.985, end: 1).animate(curved),
                 child: child,
               ),
             ),
           );
         },
       );
}
