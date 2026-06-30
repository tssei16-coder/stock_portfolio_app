import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../features/auth/login_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/rebalance/rebalance_screen.dart';
import '../features/stock_edit/stock_edit_screen.dart';

/// ルーター設定（GoRouter）
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isOnLogin = state.matchedLocation == '/login';

      if (!isLoggedIn && !isOnLogin) return '/login';
      if (isLoggedIn && isOnLogin) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/rebalance',
        name: 'rebalance',
        builder: (context, state) => const RebalanceScreen(),
      ),
      GoRoute(
        path: '/stock/add',
        name: 'stockAdd',
        builder: (context, state) => const StockEditScreen(),
      ),
      GoRoute(
        path: '/stock/edit/:code',
        name: 'stockEdit',
        builder: (context, state) {
          final code = state.pathParameters['code']!;
          return StockEditScreen(stockCode: code);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('ページが見つかりません: ${state.error}'),
      ),
    ),
  );
});
