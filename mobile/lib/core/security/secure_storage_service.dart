// secure_storage_service.dart
//
// Wraps flutter_secure_storage, which persists to:
//  - iOS: Keychain (with kSecAttrAccessibleWhenUnlockedThisDeviceOnly)
//  - Android: Keystore-backed EncryptedSharedPreferences
//
// Nothing here ever leaves the device. There is intentionally no method
// that uploads, syncs, or transmits a mnemonic/private key anywhere.

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'biometric_service.dart';

class SecureStorageService {
  SecureStorageService({
    FlutterSecureStorage? storage,
    BiometricService? biometricService,
  })  : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            ),
        _biometrics = biometricService ?? BiometricService();

  final FlutterSecureStorage _storage;
  final BiometricService _biometrics;

  String _mnemonicKey(String walletId) => 'mnemonic_$walletId';
  String _indexKey(String walletId) => 'account_indices_$walletId';
  String _pinHashKey() => 'pin_hash';

  Future<void> saveMnemonic({required String walletId, required String mnemonic}) async {
    await _storage.write(key: _mnemonicKey(walletId), value: mnemonic);
  }

  /// Requires a successful biometric/PIN check before returning key material.
  Future<String> loadMnemonic({required String walletId}) async {
    final authenticated = await _biometrics.authenticate(
      reason: 'Confirm your identity to access your wallet',
    );
    if (!authenticated) {
      throw StateError('Authentication required to access wallet keys.');
    }
    final value = await _storage.read(key: _mnemonicKey(walletId));
    if (value == null) {
      throw StateError('No wallet found for id $walletId');
    }
    return value;
  }

  Future<void> deleteMnemonic({required String walletId}) async {
    await _storage.delete(key: _mnemonicKey(walletId));
    await _storage.delete(key: _indexKey(walletId));
  }

  Future<void> saveAccountIndexList({
    required String walletId,
    required List<int> indices,
  }) async {
    await _storage.write(key: _indexKey(walletId), value: jsonEncode(indices));
  }

  Future<List<int>> loadAccountIndexList({required String walletId}) async {
    final raw = await _storage.read(key: _indexKey(walletId));
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<int>();
  }

  /// Stores a salted hash of the user's app PIN (never the PIN itself).
  Future<void> savePinHash(String saltedHash) async {
    await _storage.write(key: _pinHashKey(), value: saltedHash);
  }

  Future<String?> loadPinHash() async {
    return _storage.read(key: _pinHashKey());
  }

  Future<void> wipeAll() async {
    await _storage.deleteAll();
  }
}
