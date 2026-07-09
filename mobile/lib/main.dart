// main.dart
//
// App entry point. Wires up:
//  - ProviderScope (Riverpod) for all app state
//  - GoRouter for onboarding -> wallet-shell navigation
//  - AppTheme (dark gold theme) from core/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'router/app_router.dart';

void main() {
  runApp(const ProviderScope(child: GoldWalletApp()));
}

class GoldWalletApp extends ConsumerWidget {
  const GoldWalletApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'Gold Wallet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
