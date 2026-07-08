// chain_config.dart
//
// RPC URLs should be injected via --dart-define at build time, not hardcoded,
// and should point at your own Infura/Alchemy/QuickNode project keys. Never
// embed a paid/rate-limited API key directly in source that ships in the APK —
// decompilation exposes it. Use a lightweight backend proxy (see
// backend/src/routes/rpcProxy.js) if you need to keep provider keys private,
// or use a public-key-safe provider plan meant for client embedding.

enum ChainId {
  ethereum(1),
  bnbChain(56),
  polygon(137),
  // Testnets for development
  sepolia(11155111),
  bnbTestnet(97),
  polygonAmoy(80002);

  final int id;
  const ChainId(this.id);
}

class ChainConfig {
  final ChainId chainId;
  final String name;
  final String symbol;
  final String rpcUrl;
  final String wssUrl;
  final String blockExplorerUrl;
  final int decimals;
  final String iconAsset;

  const ChainConfig({
    required this.chainId,
    required this.name,
    required this.symbol,
    required this.rpcUrl,
    required this.wssUrl,
    required this.blockExplorerUrl,
    this.decimals = 18,
    required this.iconAsset,
  });

  static const _infuraKey = String.fromEnvironment('INFURA_PROJECT_ID');
  static const _alchemyKeyPolygon = String.fromEnvironment('ALCHEMY_POLYGON_KEY');
  static const _bnbRpc = String.fromEnvironment(
    'BNB_RPC_URL',
    defaultValue: 'https://bsc-dataseed.binance.org',
  );

  static final Map<ChainId, ChainConfig> mainnets = {
    ChainId.ethereum: ChainConfig(
      chainId: ChainId.ethereum,
      name: 'Ethereum',
      symbol: 'ETH',
      rpcUrl: 'https://mainnet.infura.io/v3/$_infuraKey',
      wssUrl: 'wss://mainnet.infura.io/ws/v3/$_infuraKey',
      blockExplorerUrl: 'https://etherscan.io',
      iconAsset: 'assets/icons/eth.svg',
    ),
    ChainId.bnbChain: ChainConfig(
      chainId: ChainId.bnbChain,
      name: 'BNB Chain',
      symbol: 'BNB',
      rpcUrl: _bnbRpc,
      wssUrl: 'wss://bsc-ws-node.nariox.org:443',
      blockExplorerUrl: 'https://bscscan.com',
      iconAsset: 'assets/icons/bnb.svg',
    ),
    ChainId.polygon: ChainConfig(
      chainId: ChainId.polygon,
      name: 'Polygon',
      symbol: 'MATIC',
      rpcUrl: 'https://polygon-mainnet.g.alchemy.com/v2/$_alchemyKeyPolygon',
      wssUrl: 'wss://polygon-mainnet.g.alchemy.com/v2/$_alchemyKeyPolygon',
      blockExplorerUrl: 'https://polygonscan.com',
      iconAsset: 'assets/icons/polygon.svg',
    ),
  };

  /// ERC-20 style token contracts tracked per chain (USDT etc). Balances for
  /// these are read via the ERC-20 `balanceOf` call, not native balance.
  static final Map<ChainId, Map<String, String>> stablecoinContracts = {
    ChainId.ethereum: {'USDT': '0xdAC17F958D2ee523a2206206994597C13D831ec7'},
    ChainId.bnbChain: {'USDT': '0x55d398326f99059fF775485246999027B3197955'},
    ChainId.polygon: {'USDT': '0xc2132D05D31c914a87C6611C10748AEb04B58e8F'},
  };
}
