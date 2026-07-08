// dashboard_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AssetRow {
  final String symbol;
  final String name;
  final String chainName;
  final String balance;
  final String fiatValue;
  final String iconAsset;
  const AssetRow({
    required this.symbol,
    required this.name,
    required this.chainName,
    required this.balance,
    required this.fiatValue,
    required this.iconAsset,
  });
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.totalBalanceUsd,
    required this.assets,
  });

  final String totalBalanceUsd;
  final List<AssetRow> assets;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gold Wallet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _PortfolioCard(totalBalanceUsd: totalBalanceUsd),
            const SizedBox(height: 24),
            _ActionRow(),
            const SizedBox(height: 28),
            Text('Assets', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...assets.map((a) => _AssetTile(asset: a)),
          ],
        ),
      ),
    );
  }
}

class _PortfolioCard extends StatelessWidget {
  const _PortfolioCard({required this.totalBalanceUsd});
  final String totalBalanceUsd;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1F1D24), Color(0xFF141318)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x33D4AF37)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Portfolio Value',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          ShaderMask(
            shaderCallback: (bounds) => AppTheme.goldGradient.createShader(bounds),
            child: Text(
              '\$$totalBalanceUsd',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.arrow_upward_rounded, 'Send'),
      (Icons.arrow_downward_rounded, 'Receive'),
      (Icons.swap_horiz_rounded, 'Swap'),
      (Icons.history_rounded, 'History'),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions.map((a) {
        return Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0x22D4AF37)),
              ),
              child: Icon(a.$1, color: AppColors.gold),
            ),
            const SizedBox(height: 6),
            Text(a.$2, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        );
      }).toList(),
    );
  }
}

class _AssetTile extends StatelessWidget {
  const _AssetTile({required this.asset});
  final AssetRow asset;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x14D4AF37)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.surfaceElevated,
            child: Text(asset.symbol.substring(0, 1)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(asset.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(asset.chainName,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(asset.balance, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('\$${asset.fiatValue}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}
