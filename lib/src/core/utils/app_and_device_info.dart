import 'package:bd_ekyc/exports.dart';


Future<AppInfoModel> appInfo() async {
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  return AppInfoModel(
    name: packageInfo.appName,
    version: packageInfo.version,
    bundleId: packageInfo.packageName,
  );
}

Future<DeviceInfoModel> deviceInfo() async {
  var deviceInfo = DeviceInfoPlugin();
  late String deviceName;
  late String deviceId;
  late String deviceOs;
  late String deviceOsVersion;
  late String deviceModel;
  late bool isPhysicalDevice;
  late String deviceUDID;

  if (!kIsWeb && Platform.isIOS) {
    deviceUDID = await FlutterUdid.udid;
    var iosDeviceInfo = await deviceInfo.iosInfo;
    deviceName = iosDeviceInfo.utsname.machine;
    deviceId = iosDeviceInfo.identifierForVendor!;
    deviceOsVersion = iosDeviceInfo.systemVersion;
    deviceModel = iosDeviceInfo.modelName;
    deviceOs = 'ios';
    isPhysicalDevice = iosDeviceInfo.isPhysicalDevice;
  } else if (!kIsWeb && Platform.isAndroid) {
    var androidDeviceInfo = await deviceInfo.androidInfo;
    deviceUDID = await FlutterUdid.udid;
    deviceId = androidDeviceInfo.id;
    deviceName = androidDeviceInfo.device;
    deviceOsVersion = androidDeviceInfo.version.release;
    deviceModel = androidDeviceInfo.model;
    deviceOs = 'android';
    isPhysicalDevice = androidDeviceInfo.isPhysicalDevice;
  }
  return DeviceInfoModel(
    name: deviceName,
    id: deviceId,
    osVersion: deviceOsVersion,
    model: deviceModel,
    os: deviceOs,
    udid: deviceUDID,
    modelAndName: '$deviceModel-$deviceName',
    isPhysicalDevice: isPhysicalDevice,
  );
}
