import 'package:flutter/material.dart';

Future<T?> pushAndRemoveUntil<T extends Object?>(
  BuildContext context,
  Widget screen, {
  Object? extra,
}) {
  return Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (context) => screen,
      settings: RouteSettings(arguments: extra),
    ),
    (route) => false,
  );
}

Future<T?> push<T extends Object?>(
  BuildContext context,
  Widget screen, {
  Object? extra,
}) {
  return Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => screen,
      settings: RouteSettings(arguments: extra),
    ),
  );
}

Future<T?> pushReplacement<T extends Object?>(
  BuildContext context,
  Widget screen, {
  Object? extra,
}) {
  return Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => screen,
      settings: RouteSettings(arguments: extra),
    ),
  );
}

void pop<T extends Object?>(BuildContext context, [Object? result]) {
  Navigator.pop(context, result);
}

bool canPop(BuildContext context) {
  return Navigator.canPop(context);
}
