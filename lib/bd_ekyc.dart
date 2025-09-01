library;

import 'package:bd_ekyc/src/module/presentation/screens/kyc_entry.dart';
import 'package:flutter/material.dart';

export 'package:bd_ekyc/bd_ekyc.dart';

class BdEkyc extends StatelessWidget {
  const BdEkyc({super.key, required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(theme: theme, home: KycEntryScreen());
  }
}
