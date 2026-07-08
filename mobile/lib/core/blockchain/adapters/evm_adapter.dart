// evm_adapter.dart
import 'dart:async';
import 'package:bip39/bip39.dart' as bip39;
import 'package:bip32/bip32.dart' as bip32;
import 'package:web3dart/web3dart.dart';
import 'chain_adapter.dart';
import '../chain_config.dart';
import '../web3_service.dart';
import '../../security/wallet_service.dart';

class EvmChainAdapter implements ChainAdapter {
  EvmChainAdapter(this._chain) : _web3 = Web3Service(_chain);

  final ChainConfig _chain;
  final Web3Service _web3;

  @override
  String get chainKey => _chain.name.toLowerCase().replaceAll(' ', '_');

  @override
  String get symbol => _chain.symbol;

  @override
  int get decimals => _chain.decimals;

  @override
  Future<String> deriveAddress({required String mnemonic, required int accountIndex}) async {
    final seed = bip39.mnemonicToSeed(mnemonic);
    final root = bip32.BIP32.fromSeed(seed);
    final child = root.derivePath("m/44'/60'/0'/0/$accountIndex");
    final credentials = EthPrivateKey.fromInts(child.privateKey!);
    return credentials.address.hexEip55;
  }

  @override
  Future<BigInt> getNativeBalance(String address) async {
    final balance = await _web3.getNativeBalance(address);
    return balance.getInWei;
  }

  @override
  Future<String> sendNative({
    required String mnemonic,
    required int accountIndex,
    required String toAddress,
    required BigInt amount,
  }) async {
    // In practice the mnemonic never flows through this adapter directly —
    // the UI layer resolves { walletId, accountIndex } and WalletService
    // pulls the mnemonic from SecureStorageService internally after a
    // biometric check. Signature kept here to satisfy the shared interface;
    // see Web3Service.sendNativeTransfer for the real signing call path.
    throw UnimplementedError(
      'Use Web3Service.sendNativeTransfer via the wallet id, not raw mnemonic, '
      'to keep key material inside WalletService/SecureStorageService.',
    );
  }

  @override
  Future<Map<String, dynamic>> estimateFee({
    required String fromAddress,
    required String toAddress,
    required BigInt amount,
  }) async {
    final est = await _web3.estimateGas(
      fromAddress: fromAddress,
      toAddress: toAddress,
      amount: EtherAmount.fromBigInt(EtherUnit.wei, amount),
    );
    return {
      'gasPriceWei': est.gasPrice.getInWei.toString(),
      'gasLimit': est.gasLimit.toString(),
      'estimatedFeeWei': est.estimatedFee.getInWei.toString(),
      'estimatedFeeEther': est.estimatedFee.getValueInUnit(EtherUnit.ether).toString(),
    };
  }

  @override
  Stream<Map<String, dynamic>> trackTransaction(String txHash) {
    return _web3.trackConfirmations(txHash).map((status) => {
          'txHash': status.txHash,
          'isPending': status.isPending,
          'isSuccess': status.isSuccess,
          'confirmations': status.confirmations,
        });
  }
}
