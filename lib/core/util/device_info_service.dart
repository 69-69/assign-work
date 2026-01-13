import 'dart:io';

import 'package:assign_erp/core/util/debug_printify.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/features/trouble_shooting/data/data_sources/local/device_info_cache.dart';
import 'package:device_info_plus/device_info_plus.dart';

/*import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
PackageInfo packageInfo = await PackageInfo.fromPlatform();*/

class DeviceInfoService {
  static final _unKnown = 'unknown';
  static final cacheService = DeviceInfoCache();
  static final DeviceInfoService _instance = DeviceInfoService._internal();

  // Private constructor to ensure Singleton pattern
  DeviceInfoService._internal();

  // Getter for the singleton instance
  factory DeviceInfoService() => _instance;

  // Cached device info
  static String _deviceId = '';
  static Map<String, dynamic> _deviceInfoCache = {};

  static final fallbackId = DateTime.now().toMilliseconds.toString();

  // Platform-specific logic for retrieving device info
  static Future<({String deviceId, Map<String, dynamic> deviceInfo})>
  _getDeviceInfoForPlatform() async {
    final deviceInfo = DeviceInfoPlugin();
    String newId = '';
    Map<String, String> infoMap = {};

    try {
      if (Platform.isAndroid) {
        final android = await deviceInfo.androidInfo;
        newId = _getDeviceIdFromPlatform(did: android.id);
        infoMap = _androidInfo(android, newId);
      } else if (Platform.isIOS) {
        final ios = await deviceInfo.iosInfo;
        newId = _getDeviceIdFromPlatform(did: ios.identifierForVendor);
        infoMap = _iosInfo(ios, newId);
      } else if (Platform.isMacOS) {
        final mac = await deviceInfo.macOsInfo;
        newId = _getDeviceIdFromPlatform(did: mac.systemGUID);
        infoMap = _macInfo(mac, newId);
      } else if (Platform.isWindows) {
        final windows = await deviceInfo.windowsInfo;
        newId = _getDeviceIdFromPlatform(did: windows.deviceId);
        infoMap = _winInfo(windows, newId);
      } else if (Platform.isLinux) {
        final linux = await deviceInfo.linuxInfo;
        newId = _getDeviceIdFromPlatform(did: linux.machineId);
        infoMap = _linuxInfo(linux, newId);
      } else {
        newId = fallbackId; // Fallback for unknown platform
        infoMap = {'error': 'Unsupported Platform'};
      }
    } catch (e) {
      // Fallback on any exception
      newId = fallbackId;
      prettyPrint('Failed to retrieve platform device info', '$e');
      infoMap = {'error': 'Failed to retrieve device info'};
    }
    // Cache the device info if no error occurred
    if (!infoMap.containsKey('error')) {
      cacheService.setDeviceInfo(infoMap);
    }

    // Cache the fetched device info
    _deviceInfoCache = infoMap;
    _deviceId = newId;

    return (deviceId: newId, deviceInfo: infoMap);
  }

  static String _getDeviceIdFromPlatform({String? did}) =>
      did!.isNullOrEmpty ? fallbackId : did;

  static Future<Map<String, dynamic>> getDeviceInfo() async {
    // Return cached info if already fetched
    if (_deviceInfoCache.isNotEmpty) {
      return _deviceInfoCache;
    }

    final cachedId = cacheService.getDeviceInfo();
    if (cachedId != null) return cachedId.toMap();

    final deviceInfo = await _getDeviceInfoForPlatform();
    Map<String, dynamic> infoMap = deviceInfo.deviceInfo;

    return infoMap;
  }

  // Helper method to get a persistent device ID, if needed
  static Future getDeviceId() async {
    if (_deviceId.isNotEmpty) return _deviceId;

    final cachedId = cacheService.getDeviceInfo();
    if (cachedId != null) return cachedId.deviceId;

    final deviceInfo = await _getDeviceInfoForPlatform();
    String newId = deviceInfo.deviceId;

    return newId;
  }

  // Helper method for storing platform-specific information
  static Map<String, String> _platformInfo({
    required String m,
    required String v,
    required String s,
    required String i,
  }) => {'model': m, 'osVersion': v, 'storage': s, 'deviceId': i};

  static Map<String, String> _linuxInfo(
    LinuxDeviceInfo linux,
    String deviceId,
  ) {
    return _platformInfo(
      m: linux.name,
      v: linux.version ?? _unKnown,
      s: 'unknown',
      i: deviceId,
    );
  }

  static Map<String, String> _winInfo(
    WindowsDeviceInfo windows,
    String deviceId,
  ) {
    return _platformInfo(
      m: windows.productName,
      v: windows.csdVersion,
      s: windows.systemMemoryInMegabytes.toString(),
      i: deviceId,
    );
  }

  static Map<String, String> _macInfo(MacOsDeviceInfo mac, String deviceId) =>
      _platformInfo(
        m: mac.model,
        v: mac.osRelease,
        s: mac.memorySize.toString(),
        i: deviceId,
      );

  static Map<String, String> _iosInfo(IosDeviceInfo ios, String deviceId) =>
      _platformInfo(
        m: ios.model,
        v: ios.systemVersion,
        s: ios.freeDiskSize.toString(),
        i: deviceId,
      );

  static Map<String, String> _androidInfo(
    AndroidDeviceInfo android,
    String deviceId,
  ) => _platformInfo(
    m: android.model,
    v: android.version.release,
    s: android.freeDiskSize.toString(),
    i: deviceId,
  );

  /// Clears the cached device ID.
  static Future<void> resetCache() async =>
      await cacheService.clearDeviceInfo();
}

/// Retrieves a persistent device ID across sessions/platforms.
/// - Returns cached ID if available.
/// - Otherwise generates one based on the platform info. [getUserDeviceId]
/*Future<String> getUserDeviceId() async {
  final cacheService = DeviceInfoCacheService();
  final cachedId = cacheService.getDeviceId();

  if (cachedId != null) return cachedId.deviceId;

  final deviceInfo = DeviceInfoPlugin();
  String newId = '';
  final fallbackId = DateTime.now().millisecondsSinceEpoch.toString();

  try {
    if (Platform.isAndroid) {
      final android = await deviceInfo.androidInfo;
      final anId = android.id;
      newId = anId.isEmpty ? fallbackId : anId;
    } else if (Platform.isIOS) {
      final ios = await deviceInfo.iosInfo;
      newId = ios.identifierForVendor ?? fallbackId;
    } else if (Platform.isMacOS) {
      final mac = await deviceInfo.macOsInfo;
      newId = mac.systemGUID ?? fallbackId;
    } else if (Platform.isWindows) {
      final windows = await deviceInfo.windowsInfo;
      final winId = windows.deviceId;
      newId = winId.isEmpty ? fallbackId : winId;
    } else if (Platform.isLinux) {
      final linux = await deviceInfo.linuxInfo;
      newId = linux.machineId ?? fallbackId;
    } else {
      newId = fallbackId; // Fallback for unknown platform
    }
  } catch (e) {
    // Fallback on any exception
    debugPrint('Failed to retrieve platform device info: $e');
    newId = fallbackId;
  }
  await cacheService.cacheDeviceId({});

  return newId;
}*/
