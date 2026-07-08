// solana_adapter.dart
//
// Solana uses ed25519 keys (SLIP-0010 derivation, path m/44'/501'/{index}'/0'),
// not secp256k1 like EVM chains — a genuinely different curve, which is why
// this is a separate adapter rather than a config flag on EvmChainAdapter.
//
// Recommended packages: `solana` (dart) for RPC + tx building,
// `ed25519_hd_key` for SLIP-0010 derivation from the same BIP39 mnemonic.

import 'dart:async';
import 'dart:typed_data';
import 'chain_adapter.dart';

class SolanaChainAdapter implements ChainAdapter {
  SolanaChainAdapter({required this.rpcUrl});
  final String rpcUrl;

  @override
  String get chainKey => 'solana';

  @override
  String get symbol => 'SOL';

  @override
  int get decimals => 9; // lamports

  @override
  Future<String> deriveAddress({required String mnemonic, required int accountIndex}) async {
    // Pseudocode-accurate shape:
    //   final seed = bip39.mnemonicToSeed(mnemonic);
    //   final derived = ED25519_HD_KEY.derivePath("m/44'/501'/$accountIndex'/0'", seed);
    //   final keyPair = await ed25519.newKeyPairFromSeed(derived.key);
    //   return base58encode(keyPair.publicKey.bytes);
    throw UnimplementedError('Wire up ed25519_hd_key + solana package here.');
  }

  @override
  Future<BigInt> getNativeBalance(String address) async {
    // POST { "jsonrpc":"2.0","id":1,"method":"getBalance","params":["$address"] }
    // to rpcUrl, return result.value (lamports) as BigInt.
    throw UnimplementedError();
  }

  @override
  Future<String> sendNative({
    required String mnemonic,
    required int accountIndex,
    required String toAddress,
    required BigInt amount,
  }) async {
    throw UnimplementedError(
      'Build a SystemProgram.transfer instruction, sign with the derived '
      'ed25519 keypair on-device, then call sendTransaction over rpcUrl.',
    );
  }

  @override
  Future<Map<String, dynamic>> estimateFee({
    required String fromAddress,
    required String toAddress,
    required BigInt amount,
  }) async {
    // Solana fees are ~5000 lamports/signature, near-fixed; fetch via
    // getFeeForMessage for precision.
    return {'estimatedFeeLamports': '5000'};
  }

  @override
  Stream<Map<String, dynamic>> trackTransaction(String txHash) async* {
    // Poll getSignatureStatuses until confirmed/finalized.
    throw UnimplementedError();
  }
}
