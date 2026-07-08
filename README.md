# CryptoVault — Non-Custodial Multi-Chain Wallet

## Architecture at a glance

```
mobile/   Flutter app — ALL key material lives here and only here.
backend/  Node.js/Express API — metadata, notifications, rewards, admin.
          Never sees a private key or mnemonic, ever.
```

**The one rule everything else follows:** the backend can be fully compromised
and an attacker still cannot move a single user's funds, because it never
holds signing capability. It stores public addresses, cached balances,
transaction *history* (mirrored from-chain, read-only), notification
preferences, and reward-point ledger entries.

## Mobile (Flutter)

- `lib/core/security/` — `WalletService` (BIP39/BIP44 key derivation, signing),
  `SecureStorageService` (Keychain/Keystore-backed encrypted storage, gated by
  `BiometricService`), `DeviceIntegrityService` (root/jailbreak warning).
- `lib/core/blockchain/adapters/` — `ChainAdapter` interface implemented per
  chain family: `EvmChainAdapter` (ETH/BNB/Polygon, done), `SolanaChainAdapter`
  (ed25519, stubbed with real call shapes), and a documented pattern for
  Bitcoin-family (BTC/LTC/DOGE, UTXO+PSBT) and XRP (account/sequence model).
- `lib/features/scanpay/` — camera QR scan (`mobile_scanner`) + gallery image
  upload, both routed through `PaymentUriParser` which handles BIP21
  (`bitcoin:`, `litecoin:`, `dogecoin:`) and EIP-681 (`ethereum:addr@chainId`)
  payment URIs, plus bare-address fallback with chain inference.
- `lib/core/theme/app_theme.dart` — dark gold/crypto theme.

## Backend (Node/Express/Postgres/Redis)

- `models/` — `User`, `WalletAddress` (public address + label only),
  `TransactionRecord` (read cache of on-chain data), `Notification`,
  `RewardRule` + `RewardLedgerEntry` (append-only, rule-driven point grants),
  `Referral`, `PriceAlert`, `RefreshToken`.
- `routes/transactions.routes.js` → `/broadcast` accepts an **already-signed**
  raw transaction and relays it to the chain RPC. It cannot build or sign one.
- `routes/rpcProxy.routes.js` — allow-listed **read-only** RPC methods only
  (`eth_getBalance`, `eth_call`, etc.) so you can keep provider API keys
  (Infura/Alchemy) server-side instead of embedding them in the shipped APK.
- `routes/admin.routes.js` — user status management (suspend/reactivate) and
  reward-rule configuration. No endpoint can view keys (none exist) or
  directly edit a user's point balance outside the rule engine in
  `services/rewards.service.js`.

## Security checklist before shipping

- [ ] Move `INFURA_PROJECT_ID` / `ALCHEMY_POLYGON_KEY` out of any client build
      config and confirm the app only calls your `/api/v1/rpc` proxy in
      release builds.
- [ ] Replace the placeholder `encryptTotpSecret`/`decryptTotpSecret` in
      `auth.controller.js` with real AES-256-GCM using a KMS-managed key.
- [ ] Swap the in-memory root/jailbreak checks in
      `device_integrity_service.dart` for a maintained package
      (`freerasp` or `flutter_jailbreak_detection`) before release.
- [ ] Add certificate pinning for RPC/API hosts in the mobile HTTP client.
- [ ] Rate-limit and monitor `/transactions/broadcast` for abuse (it's a
      public relay even though it can't forge signatures).
- [ ] Get an independent security audit before handling real user funds —
      this scaffold gets the architecture right but a wallet handling real
      money needs a paid audit, not just a code review.
- [ ] Implement the Bitcoin-family and XRP adapters with a vetted library
      (`bitcoin_base`, `xrpl` equivalents) rather than writing PSBT/XRPL
      signing from scratch.

## Local setup

```bash
# Backend
cd backend
cp .env.example .env   # fill in RPC keys, JWT secrets, DB/Redis URLs
npm install
npm run migrate
npm run dev

# Mobile
cd mobile
flutter pub get
flutter run --dart-define=INFURA_PROJECT_ID=xxx --dart-define=ALCHEMY_POLYGON_KEY=xxx
```
