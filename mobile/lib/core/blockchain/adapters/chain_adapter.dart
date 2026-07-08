// chain_adapter.dart
//
// Every supported chain (EVM family, Bitcoin family, Solana, XRP...) implements
// this interface. This is what lets one Dashboard/Send/Receive screen work
// across all of them without branching on chain type everywhere.
//
// Reference implementations:
//  - EvmChainAdapter    -> lib/core/blockchain/adapters/evm_adapter.dart (done, uses web3dart)
//  - SolanaChainAdapter -> lib/core/blockchain/adapters/solana_adapter.dart (done, uses solana pkg)
//  - BitcoinChainAdapter (BTC/LTC/DOGE) -> plug in `bitcoin_base` or `bitcoin` dart pkg,
//    same interface: derive via BIP84/BIP44 P2WPKH or P2PKH, build+sign PSBT, broadcast via
//    a public Bitcoin RPC/Electrum server or a service like Blockstream's esplora API.
//  - XrpChainAdapter -> plug in `xrp_dart` or call XRPL JSON-RPC directly; account model
//    (sequence numbers, no UTXOs) rather than nonce-based like EVM.

abstract class ChainAdapter {
  String get chainKey; // 'ethereum', 'bitcoin', 'solana', 'xrp', ...
  String get symbol;
  int get decimals;

  /// Derives a public address for [accountIndex] from the seed. Must NEVER
  /// return or log key material — only the address.
  Future<String> deriveAddress({required String mnemonic, required int accountIndex});

  Future<BigInt> getNativeBalance(String address);

  Future<String> sendNative({
    required String mnemonic,
    required int accountIndex,
    required String toAddress,
    required BigInt amount,
  });

  Future<Map<String, dynamic>> estimateFee({
    required String fromAddress,
    required String toAddress,
    required BigInt amount,
  });

  Stream<Map<String, dynamic>> trackTransaction(String txHash);
}
