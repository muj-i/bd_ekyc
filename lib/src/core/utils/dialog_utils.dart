import 'dart:ui';

import 'package:bd_ekyc/src/core/config/package_colors.dart';
import 'package:bd_ekyc/src/core/utils/enums.dart';
import 'package:bd_ekyc/src/core/utils/navigator.dart';
import 'package:flutter/material.dart';

Future<T?> dialogView<T>(
  BuildContext context, {
  EdgeInsetsGeometry? titlePadding,
  EdgeInsetsGeometry? contentPadding,
  EdgeInsetsGeometry? actionsPadding,
  EdgeInsets? insetPadding,
  List<Widget>? actions,
  required Widget titleWidget,
  required Widget contentWidget,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: PackageColors.blur,
    pageBuilder: (context, _, __) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          insetPadding: insetPadding,
          titlePadding: titlePadding,
          contentPadding: contentPadding,
          actionsPadding: actionsPadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: titleWidget,
          content: contentWidget,
          actions: actions,
        ),
      );
    },
  );
}

Future<void> showAlertDialog(
  BuildContext context, {
  String? title,
  String? btnText,
  required String msg,
  void Function()? onButtonPressed,
  required AlertType alertType,
}) {
  return dialogView(
    context,
    titleWidget: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          switch (alertType) {
            AlertType.success => const Icon(
              Icons.check_circle,
              color: PackageColors.lightGreen,
              size: 56,
            ),
            AlertType.warning => const Icon(
              Icons.warning_amber_rounded,
              color: PackageColors.deepYellow,
              size: 56,
            ),
            AlertType.error => const Icon(
              Icons.error_outline_rounded,
              color: PackageColors.red,
              size: 56,
            ),
          },
          const SizedBox(height: 16),
          switch (alertType) {
            AlertType.success => Text(title ?? 'Success'),
            AlertType.warning => Text(title ?? 'Warning'),
            AlertType.error => Text(title ?? 'Error'),
          },
        ],
      ),
    ),
    contentWidget: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(textAlign: TextAlign.center, msg),
        const SizedBox(height: 16),
        SizedBox(
          width: 120,
          child: OutlinedButton(
            onPressed:
                onButtonPressed ??
                () {
                  pop(context);
                },
            child: Text(btnText ?? 'OK'),
          ),
        ),
      ],
    ),
  );
}
