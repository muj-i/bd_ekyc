library;

import 'package:bd_ekyc/exports.dart';

export 'package:bd_ekyc/bd_ekyc.dart';
export 'package:bd_ekyc/src/module/presentation/widgets/edge_to_edge_config.dart';


class BdEkyc extends StatelessWidget {
  const BdEkyc({super.key});

  @override
  Widget build(BuildContext context) {
    return KycEntryScreen();
  }
}
