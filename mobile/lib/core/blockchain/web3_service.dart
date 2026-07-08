// web3_service.dart
//
// Read-only + broadcast operations against EVM chains. This class never
// touches private keys — it either reads public chain state or broadcasts
// an already-signed transaction produced by WalletService.

import 'dart:async';
import 'dart:typed_data';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import '../security/wallet_service.dart';
import 'chain_config.dart';

class TxReceiptStatus {
  final String txHash;
  final bool isPending;
  final bool isSuccess;
  final int confirmations;
  const TxReceiptStatus({
    required this.txHash,
    required this.isPending,
    required this.isSuccess,
    required this.confirmations,
  });
}

class Web3Service {
  Web3Service(this._chain)
      : client = Web3Client(_chain.rpcUrl, http.Client());

  final ChainConfig _chain;
  final Web3Client client;

  Future<EtherAmount> getNativeBalance(String address) async {
    final balance = await client.getBalance(EthereumAddress.fromHex(address));
    return balance;
  }

  /// Reads ERC-20 balance (e.g. USDT) for [address] using the standard
  /// `balanceOf(address)` view function.
  Future<BigInt> getTokenBalance({
    required String tokenContract,
    required String ownerAddress,
    int decimals = 6, // USDT is 6 decimals on most chains
  }) async {
    final contract = DeployedContract(
      ContractAbi.fromJson(_erc20AbiMinimal, 'ERC20'),
      EthereumAddress.fromHex(tokenContract),
    );
    final balanceOf = contract.function('balanceOf');
    final result = await client.call(
      contract: contract,
      function: balanceOf,
      params: [EthereumAddress.fromHex(ownerAddress)],
    );
    return result.first as BigInt;
  }

  /// Estimates gas for a native-coin transfer. For ERC-20 transfers, build
  /// the transaction with `data` set to the encoded `transfer(to, amount)`
  /// call first, then pass it here — the estimate call is the same shape.
  Future<({EtherAmount gasPrice, BigInt gasLimit, EtherAmount estimatedFee})>
      estimateGas({
    required String fromAddress,
    required String toAddress,
    required EtherAmount amount,
    Uint8List? data,
  }) async {
    final gasPrice = await client.getGasPrice();
    final gasLimit = await client.estimateGas(
      sender: EthereumAddress.fromHex(fromAddress),
      to: EthereumAddress.fromHex(toAddress),
      value: amount,
      data: data,
    );
    final feeWei = gasPrice.getInWei * gasLimit;
    return (
      gasPrice: gasPrice,
      gasLimit: gasLimit,
      estimatedFee: EtherAmount.fromBigInt(EtherUnit.wei, feeWei),
    );
  }

  /// Builds an unsigned transaction, hands it to [walletService] for
  /// on-device signing, then broadcasts the signed bytes. Returns the tx hash.
  Future<String> sendNativeTransfer({
    required WalletService walletService,
    required String walletId,
    required int accountIndex,
    required String fromAddress,
    required String toAddress,
    required EtherAmount amount,
  }) async {
    final gasEstimate = await estimateGas(
      fromAddress: fromAddress,
      toAddress: toAddress,
      amount: amount,
    );
    final nonce = await client.getTransactionCount(
      EthereumAddress.fromHex(fromAddress),
      atBlock: const BlockNum.pending(),
    );

    final tx = Transaction(
      to: EthereumAddress.fromHex(toAddress),
      value: amount,
      gasPrice: gasEstimate.gasPrice,
      maxGas: gasEstimate.gasLimit.toInt(),
      nonce: nonce,
    );

    final signed = await walletService.signTransaction(
      rpcClient: client,
      walletId: walletId,
      accountIndex: accountIndex,
      transaction: tx,
      chainId: _chain.chainId.id,
    );

    return client.sendRawTransaction(signed);
  }

  /// Polls for confirmations until [requiredConfirmations] is reached or
  /// [timeout] elapses. UI should show this as a progress indicator.
  Stream<TxReceiptStatus> trackConfirmations(
    String txHash, {
    int requiredConfirmations = 12,
    Duration pollInterval = const Duration(seconds: 4),
    Duration timeout = const Duration(minutes: 10),
  }) async* {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final receipt = await client.getTransactionReceipt(txHash);
      if (receipt == null) {
        yield TxReceiptStatus(
          txHash: txHash,
          isPending: true,
          isSuccess: false,
          confirmations: 0,
        );
      } else {
        final latestBlock = await client.getBlockNumber();
        final confirmations =
            (latestBlock - (receipt.blockNumber.blockNum)).clamp(0, 1 << 30);
        yield TxReceiptStatus(
          txHash: txHash,
          isPending: confirmations < requiredConfirmations,
          isSuccess: receipt.status ?? false,
          confirmations: confirmations,
        );
        if (confirmations >= requiredConfirmations) return;
      }
      await Future.delayed(pollInterval);
    }
  }

  void dispose() => client.dispose();
}

const _erc20AbiMinimal = '''
[
  {"constant":true,"inputs":[{"name":"_owner","type":"address"}],"name":"balanceOf","outputs":[{"name":"balance","type":"uint256"}],"type":"function"},
  {"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transfer","outputs":[{"name":"","type":"bool"}],"type":"function"}
]
''';
