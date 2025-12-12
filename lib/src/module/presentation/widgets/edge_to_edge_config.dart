import 'package:bd_ekyc/exports.dart';

class EdgeToEdgeConfig extends StatelessWidget {
  const EdgeToEdgeConfig({
    super.key,
    required this.builder,
    this.isbottomSafeArea,
  });
  final Widget Function(bool isEdgeToEdge, String? os) builder;
  final bool? isbottomSafeArea;
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: isEdgeToEdgeSupportedDevice(),
      builder: (context, snapshot) {
        bool isEdgeToEdge = snapshot.data?.$1 ?? false;
        String? os = snapshot.data?.$2;
        return SafeArea(
          bottom: isbottomSafeArea ?? isEdgeToEdge,
          top: false,
          left: false,
          right: false,
          child: builder(isEdgeToEdge, os),
        );
      },
    );
  }

  Future<(bool, String?)> isEdgeToEdgeSupportedDevice() async {
    final info = await deviceInfo();
    if (info.os.toLowerCase() != "android") return (false, info.os);

    // Extract major version number from version string like "15.1" -> 15
    final versionParts = info.osVersion.split('.');
    final majorVersion = int.tryParse(versionParts.first) ?? 0;

    return (majorVersion >= 15, info.os);
  }
}
