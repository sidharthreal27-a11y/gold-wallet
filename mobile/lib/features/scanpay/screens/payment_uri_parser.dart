// payment_uri_parser.dart
//
// Handles the two real-world QR payment formats:
//  - BIP21 (Bitcoin/Litecoin/Dogecoin):  bitcoin:ADDRESS?amount=0.001&label=...
//  - EIP-681 (Ethereum/EVM):             ethereum:0xADDR@1?value=1e16
// Falls back to "raw address" if the QR just contains a bare address (common
// for merchant-printed static QR codes), inferring likely chain by format.

class ParsedPaymentRequest {
  final String address;
  final String? scheme; // 'bitcoin', 'ethereum', 'litecoin', 'dogecoin', 'solana', 'ripple', null=unknown
  final int? chainId; // for EVM eip-681 @chainId suffix
  final double? amount;
  final String? label;
  final String? memo; // used by XRP destination tags, etc.

  const ParsedPaymentRequest({
    required this.address,
    this.scheme,
    this.chainId,
    this.amount,
    this.label,
    this.memo,
  });
}

class PaymentUriParser {
  static ParsedPaymentRequest? tryParse(String raw) {
    final trimmed = raw.trim();

    // URI-scheme form: scheme:address[@chainId]?query
    final uriMatch = RegExp(r'^([a-zA-Z]+):([^?@]+)(?:@(\d+))?(?:\?(.*))?$').firstMatch(trimmed);
    if (uriMatch != null) {
      final scheme = uriMatch.group(1)!.toLowerCase();
      final address = uriMatch.group(2)!;
      final chainId = uriMatch.group(3) != null ? int.tryParse(uriMatch.group(3)!) : null;
      final query = uriMatch.group(4);
      final params = query != null ? Uri.splitQueryString(query) : <String, String>{};

      double? amount;
      if (params.containsKey('amount')) {
        amount = double.tryParse(params['amount']!);
      } else if (params.containsKey('value')) {
        // EIP-681 value is often in wei as an integer or e-notation string.
        final raw = params['value']!;
        final asNum = double.tryParse(raw);
        if (asNum != null) amount = asNum / 1e18;
      }

      if (_looksLikeAddress(address, scheme)) {
        return ParsedPaymentRequest(
          address: address,
          scheme: scheme,
          chainId: chainId,
          amount: amount,
          label: params['label'],
          memo: params['dt'] ?? params['memo'],
        );
      }
      return null;
    }

    // Bare address fallback — infer chain from shape.
    if (_looksLikeAddress(trimmed, null)) {
      return ParsedPaymentRequest(address: trimmed, scheme: _inferScheme(trimmed));
    }

    return null;
  }

  static bool _looksLikeAddress(String value, String? scheme) {
    if (scheme == 'ethereum' || scheme == null) {
      if (RegExp(r'^0x[a-fA-F0-9]{40}$').hasMatch(value)) return true;
    }
    if (RegExp(r'^[13][a-km-zA-HJ-NP-Z1-9]{25,34}$').hasMatch(value)) return true; // BTC legacy/P2SH
    if (RegExp(r'^bc1[a-z0-9]{25,90}$').hasMatch(value)) return true; // BTC bech32
    if (RegExp(r'^[LM][a-km-zA-HJ-NP-Z1-9]{26,33}$').hasMatch(value)) return true; // LTC
    if (RegExp(r'^D[a-km-zA-HJ-NP-Z1-9]{25,34}$').hasMatch(value)) return true; // DOGE
    if (RegExp(r'^r[1-9A-HJ-NP-Za-km-z]{25,35}$').hasMatch(value)) return true; // XRP
    if (RegExp(r'^[1-9A-HJ-NP-Za-km-z]{32,44}$').hasMatch(value)) return true; // Solana base58
    return false;
  }

  static String? _inferScheme(String address) {
    if (RegExp(r'^0x[a-fA-F0-9]{40}$').hasMatch(address)) return 'ethereum';
    if (address.startsWith('bc1') || RegExp(r'^[13]').hasMatch(address)) return 'bitcoin';
    if (RegExp(r'^[LM]').hasMatch(address)) return 'litecoin';
    if (address.startsWith('D')) return 'dogecoin';
    if (address.startsWith('r')) return 'ripple';
    return 'solana';
  }
}
