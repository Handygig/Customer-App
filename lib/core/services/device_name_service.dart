import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceNameService {
  final DeviceInfoPlugin _deviceInfo;

  DeviceNameService({DeviceInfoPlugin? deviceInfo})
    : _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  Future<String> getDeviceName() async {
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        final manufacturer = info.manufacturer.trim();
        final model = info.model.trim();
        return [
          manufacturer,
          model,
        ].where((part) => part.isNotEmpty).join(' ').trim();
      }

      if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        return info.utsname.machine.isNotEmpty
            ? info.utsname.machine
            : info.name;
      }
    } catch (_) {
      // Fall back to the platform name below.
    }

    return Platform.operatingSystem;
  }
}
