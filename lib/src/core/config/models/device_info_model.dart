class DeviceInfoModel {
  String id;
  String name;
  String osVersion;
  String model;
  String os;
  String udid;
  String modelAndName;
  bool isPhysicalDevice;

  DeviceInfoModel({
    required this.id,
    required this.name,
    required this.osVersion,
    required this.model,
    required this.os,
    required this.udid,
    required this.modelAndName,
    required this.isPhysicalDevice,
  });

  @override
  String toString() {
    return 'DeviceInfoModel{id: $id, name: $name, osVersion: $osVersion, model: $model, os: $os, udid: $udid, modelAndName: $modelAndName, isPhysicalDevice: $isPhysicalDevice}';
  }
}
