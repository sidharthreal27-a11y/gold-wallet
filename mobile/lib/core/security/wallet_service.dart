// wallet_service.dart
//
// SECURITY CONTRACT:
// - This is the ONLY module allowed to hold a decrypted private key in memory.
// - Private keys / mnemonics are NEVER sent to any backend, log, or analytics event.
// - Backend only ever receives PUBLIC addresses and signed transaction blobs
//   (already signed on-device), never raw keys.
//
// Derivation path used: m/44'/60'/0'/0/{index}  (standard EVM path, shared by
// Ethereum, BNB Chain, and Polygon since they all use secp256k1 + EVM addressing).

import 'dart:typed_data';
import 'package:bip39/bip39.dart' as bip39;
import 'package:bip32/bip32.dart' as bip32;
import 'package:web3dart/web3dart.dart';
import 'package:web3dart/credentials.dart';
import 'secure_storage_service.dart';

class DerivedAccount {
  final int index;
  final String address;
  DerivedAccount({required this.index, required this.address});
}

class WalletService {
  WalletService(this._secureStorage);

  final SecureStorageService _secureStorage;

  static const String _evmPathPrefix = "m/44'/60'/0'/0";

  /// Generates a new BIP39 mnemonic (defaults to 128 bits => 12 words;
  /// pass strength: 256 for a 24-word phrase).
  String generateMnemonic({int strength = 128}) {
    return bip39.generateMnemonic(strength: strength);
  }

  bool validateMnemonic(String mnemonic) {
    return bip39.validateMnemonic(mnemonic.trim());
  }

  /// Derives account [index] from a mnemonic. Returns only the public
  /// address — never the private key — so callers can display/verify
  /// addresses without holding key material.
  DerivedAccount deriveAccount(String mnemonic, {int index = 0}) {
    final seed = bip39.mnemonicToSeed(mnemonic);
    final root = bip32.BIP32.fromSeed(seed);
    final child = root.derivePath("$_evmPathPrefix/$index");
    final credentials = EthPrivateKey.fromInts(child.privateKey!);
    final address = credentials.address.hexEip55;
    return DerivedAccount(index: index, address: address);
  }

  /// Creates a brand-new wallet: generates mnemonic, encrypts and stores it
  /// locally (gated by biometrics/PIN), and returns the first account.
  /// The plaintext mnemonic is returned ONCE so the UI can show the backup
  /// screen; the caller must never persist it outside SecureStorageService.
  Future<({String mnemonic, DerivedAccount account})> createWallet({
    int strength = 128,
  }) async {
    final mnemonic = generateMnemonic(strength: strength);
    final account = deriveAccount(mnemonic, index: 0);
    await _secureStorage.saveMnemonic(walletId: account.address, mnemonic: mnemonic);
    await _secureStorage.saveAccountIndexList(
      walletId: account.address,
      indices: [0],
    );
    return (mnemonic: mnemonic, account: account);
  }

  /// Imports an existing wallet from a user-provided mnemonic.
  Future<DerivedAccount> importWallet(String mnemonic) async {
    final trimmed = mnemonic.trim();
    if (!validateMnemonic(trimmed)) {
      throw ArgumentError('Invalid recovery phrase.');
    }
    final account = deriveAccount(trimmed, index: 0);
    await _secureStorage.saveMnemonic(walletId: account.address, mnemonic: trimmed);
    await _secureStorage.saveAccountIndexList(walletId: account.address, indices: [0]);
    return account;
  }

  /// Adds another account (address) under the same seed — "multiple wallets"
  /// in the UI is really multiple derived accounts under one seed, which is
  /// the standard non-custodial pattern (same approach as MetaMask/Trust Wallet).
  Future<DerivedAccount> addAccount({required String walletId}) async {
    final mnemonic = await _secureStorage.loadMnemonic(walletId: walletId);
    final indices = await _secureStorage.loadAccountIndexList(walletId: walletId);
    final nextIndex = (indices.isEmpty ? -1 : indices.reduce((a, b) => a > b ? a : b)) + 1;
    final account = deriveAccount(mnemonic, index: nextIndex);
    await _secureStorage.saveAccountIndexList(
      walletId: walletId,
      indices: [...indices, nextIndex],
    );
    return account;
  }

  /// Signs a transaction on-device and returns raw signed bytes for broadcast.
  /// Caller supplies the Web3Client (RPC transport) so this class has no
  /// network dependency of its own — it only ever touches key material.
  Future<Uint8List> signTransaction({
    required Web3Client rpcClient,
    required String walletId,
    required int accountIndex,
    required Transaction transaction,
    required int chainId,
  }) async {
    final mnemonic = await _secureStorage.loadMnemonic(walletId: walletId);
    final seed = bip39.mnemonicToSeed(mnemonic);
    final root = bip32.BIP32.fromSeed(seed);
    final child = root.derivePath("$_evmPathPrefix/$accountIndex");
    final credentials = EthPrivateKey.fromInts(child.privateKey!);
    return rpcClient.signTransaction(credentials, transaction, chainId: chainId);
  }

  /// Wipes all local key material for a wallet (used on "remove wallet" /
  /// factory reset). Irreversible unless the user has their backup phrase.
  Future<void> deleteWallet(String walletId) async {
    await _secureStorage.deleteMnemonic(walletId: walletId);
  }
}
