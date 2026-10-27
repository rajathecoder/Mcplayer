import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart' show DeviceInfoPlugin;
import 'package:permission_handler/permission_handler.dart';

enum LibraryPermissionStatus { granted, denied, permanentlyDenied }

class PermissionManager {
  Future<int> _androidSdkInt() async {
    if (!Platform.isAndroid) return 0;
    final info = await DeviceInfoPlugin().androidInfo;
    return info.version.sdkInt;
  }

  Future<LibraryPermissionStatus> requestLibraryAccess() async {
    if (Platform.isIOS) {
      final status = await Permission.mediaLibrary.request();
      return _map(status);
    }

    final sdkInt = await _androidSdkInt();
    final permission = sdkInt >= 33 ? Permission.audio : Permission.storage;
    final status = await permission.request();

    if (sdkInt >= 33) {
      await Permission.notification.request();
    }

    return _map(status);
  }

  Future<LibraryPermissionStatus> checkLibraryAccess() async {
    if (Platform.isIOS) {
      return _map(await Permission.mediaLibrary.status);
    }
    final sdkInt = await _androidSdkInt();
    final permission = sdkInt >= 33 ? Permission.audio : Permission.storage;
    return _map(await permission.status);
  }

  LibraryPermissionStatus _map(PermissionStatus status) {
    if (status.isGranted || status.isLimited) return LibraryPermissionStatus.granted;
    if (status.isPermanentlyDenied) return LibraryPermissionStatus.permanentlyDenied;
    return LibraryPermissionStatus.denied;
  }

  Future<void> openSettings() => openAppSettings();
}
