import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

Future showSheet(
  BuildContext context, {
  required Widget child,
  Color? backgroundColor,
  bool dismissible = true,
}) async {
  return await showMaterialModalBottomSheet(
    context: context,
    backgroundColor: backgroundColor,
    enableDrag: dismissible,
    isDismissible: dismissible,
    builder: (context) {
      return Padding(
        // 👇 this ensures the sheet goes above the keyboard
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: child,
      );
    },
  );
}
