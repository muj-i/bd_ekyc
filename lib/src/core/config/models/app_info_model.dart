class AppInfoModel {
  String name;
  String version;
  String bundleId;

  AppInfoModel({
    required this.name,
    required this.version,
    required this.bundleId,
  });

  @override
  String toString() {
    return 'AppInfoModel{name: $name, version: $version, bundleId: $bundleId}';
  }
}
