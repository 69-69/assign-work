import 'package:assign_erp/core/util/debug_printify.dart';
import 'package:flutter/services.dart';

class DeviceIdentifier {
  static const platform = MethodChannel('device_identifier');

  Future<String?> getMacAddress() async {
    try {
      final String? macAddress = await platform.invokeMethod('getMacAddress');
      return macAddress;
    } on PlatformException catch (e) {
      prettyPrint("Failed to get MAC address", "${e.message}");
      return null;
    }
  }

  /* IOS::
  Future<String> getIosId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
    return iosInfo.identifierForVendor; // Unique ID for iOS
  }

  Android::
  Future<String> getAndroidId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    return androidInfo.androidId; // Unique ID for Android
  }

  Future<String> getUniqueId() async {
    final file = File('path_to_store_unique_id.txt');
    if (await file.exists()) {
      return await file.readAsString();
    } else {
      String uniqueId = Uuid().v4();
      await file.writeAsString(uniqueId);
      return uniqueId;
    }
  }*/
}
