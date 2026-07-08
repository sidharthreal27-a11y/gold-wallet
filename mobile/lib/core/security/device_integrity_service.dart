// device_integrity_service.dart
//
// Lightweight device-integrity checks. This is a deterrent layer, not a
// guarantee — determined attackers can bypass client-side checks. Treat it
// as one layer of defense-in-depth, alongside server-side anomaly detection
// (see backend/src/middleware/riskSignals.js) and never as a substitute for
// proper key custody (which stays entirely on-device regardless).
//
// For production, prefer a maintained package such as `flutter_jailbreak_detection`
// or `freerasp` (root/jailbreak/hook/debugger/emulator detection) rather than
// hand-rolled checks. Stubbed here to keep the dependency list explicit.

import 'dart:io';

class DeviceIntegrityService {
  /// Returns a list of human-readable warnings. Empty list = no issues found.
  /// UI should show a non-blocking warning banner for a rooted/jailbroken
  /// device rather than a hard block, since false positives are common and
  /// non-custodial wallets shouldn't lock legitimate power users out.
  Future<List<String>> checkIntegrity() async {
    final warnings = <String>[];

    if (Platform.isAndroid) {
      if (await _androidLooksRooted()) {
        warnings.add('This device appears to be rooted. Storing your recovery '
            'phrase here carries additional risk.');
      }
    } else if (Platform.isIOS) {
      if (await _iosLooksJailbroken()) {
        warnings.add('This device appears to be jailbroken. Storing your '
            'recovery phrase here carries additional risk.');
      }
    }

    return warnings;
  }

  Future<bool> _androidLooksRooted() async {
    const suspiciousPaths = [
      '/system/app/Superuser.apk',
      '/sbin/su',
      '/system/bin/su',
      '/system/xbin/su',
      '/data/local/xbin/su',
      '/data/local/bin/su',
      '/system/sd/xbin/su',
      '/system/bin/failsafe/su',
      '/data/local/su',
      '/su/bin/su',
    ];
    for (final path in suspiciousPaths) {
      if (await File(path).exists()) return true;
    }
    return false;
  }

  Future<bool> _iosLooksJailbroken() async {
    const suspiciousPaths = [
      '/Applications/Cydia.app',
      '/Library/MobileSubstrate/MobileSubstrate.dylib',
      '/bin/bash',
      '/usr/sbin/sshd',
      '/etc/apt',
      '/private/var/lib/apt/',
    ];
    for (final path in suspiciousPaths) {
      if (await File(path).exists()) return true;
    }
    return false;
  }
}
