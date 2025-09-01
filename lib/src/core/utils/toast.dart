import 'package:bd_ekyc/src/core/config/package_colors.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

void showToast(
  BuildContext context, {
  required String message,
  Color? color,
  IconData? icon,
  bool showIcon = true,
  int sec = 3,
}) {
  toastification.show(
    context: context,
    title: Text(message),
    autoCloseDuration: Duration(seconds: sec),
    primaryColor: color,
    icon: icon != null ? Icon(icon) : null,
    showIcon: showIcon,
    alignment: Alignment.bottomCenter,
    borderSide: BorderSide(
      color: color ?? PackageColors.grey.withValues(alpha: .3),
      width: 1,
    ),
  );
}

void showSuccessToast(BuildContext context, {required String message}) {
  showToast(context, message: message);
}

void showErrorToast(BuildContext context, {required String message}) {
  showToast(
    context,
    message: message,
    color: PackageColors.lightRed,
    icon: Icons.error_outline_outlined,
    sec: 3,
  );
}

void showWarningToast(
  BuildContext context, {
  required String message,
  int sec = 5,
}) {
  showToast(
    context,
    message: message,
    color: PackageColors.deepYellow,
    icon: Icons.error_outline_outlined,
    sec: sec,
  );
}
