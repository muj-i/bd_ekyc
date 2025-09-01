library;

import 'package:bd_ekyc/src/module/presentation/screens/kyc_entry.dart';
import 'package:bd_ekyc/src/module/presentation/state/nid_ocr_state_manager.dart';
import 'package:flutter/material.dart';

export 'package:bd_ekyc/bd_ekyc.dart';

class BdEkyc extends StatelessWidget {
  const BdEkyc({super.key});

  @override
  Widget build(BuildContext context) {
    return NidOcrStateManager(child: KycEntryScreen());
  }
}
