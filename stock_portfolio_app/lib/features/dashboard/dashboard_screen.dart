import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/portfolio_summary.dart';
import '../../providers/auth_provider.dart';
import '../../providers/stocks_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/responsive.dart';
import 'portfolio_pie_chart.dart';
import 'stock_table_desktop.dart';
import 'stock_card_mobile.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(portfolioSummaryProvider);
    final desktop = isDesktop(context);

    return Scaffold(
      appBar: _buildAppBar(context, ref, desktop),
      floatingActionButton: _buildFAB(context),
      body: summaryAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.teal),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.negative, size: 48),
              const SizedBox(height: 12),
              Text(
                'データの読み込みに失敗しました\n$e',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        data: (summary) => ResponsiveBuilder(
          mobile: _buildMobileLayout(context, ref, summary),
          desktop: _buildDesktopLayout(context, ref, summary),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, WidgetRef ref, bool desktop) {
    return AppBar(
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                colors: [AppColors.teal, Color(0xFF0066CC)],
              ),
            ),
            child: const Icon(
              Icons.candlestick_chart_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Text('マイ株管理'),
        ],
      ),
      actions: [
        if (desktop)
          TextButton.icon(
            onPressed: () => context.go('/rebalance'),
            icon: const Icon(Icons.balance_rounded, size: 18),
            label: const Text('リバランス計算'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.teal,
            ),
          ),
        IconButton(
          onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
          icon: const Icon(Icons.logout_rounded),
          tooltip: 'ログアウト',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => context.go('/stock/add'),
      backgroundColor: AppColors.teal,
      foregroundColor: AppColors.background,
      icon: const Icon(Icons.add_rounded),
      label: const Text(
        '銘柄を追加',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  // ========== デスクトップレイアウト ==========
  Widget _buildDesktopLayout(
      BuildContext context, WidgetRef ref, PortfolioSummary summary) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // サマリーカード行
          _buildSummaryCards(summary, isRow: true),
          const SizedBox(height: 24),
          // 円グラフ + テーブルの2カラムレイアウト
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 円グラフ（40%）
              SizedBox(
                width: 380,
                child: PortfolioPieChart(summary: summary),
              ),
              const SizedBox(width: 20),
              // テーブル（残り）
              Expanded(
                child: Column(
                  children: [
                    StockTableDesktop(
                      summary: summary,
                      onEdit: (code) => context.go('/stock/edit/$code'),
                      onDelete: (code) =>
                          _confirmDelete(context, ref, code),
                    ),
                    const SizedBox(height: 24),
                    // リバランスボタン
                    _buildRebalanceButton(context),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========== モバイルレイアウト ==========
  Widget _buildMobileLayout(
      BuildContext context, WidgetRef ref, PortfolioSummary summary) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // サマリーカード（横スクロール）
                _buildSummaryCardsMobile(summary),
                const SizedBox(height: 16),
                // コンパクト円グラフ
                PortfolioPieChart(
                  summary: summary,
                  compact: true,
                ),
                const SizedBox(height: 16),
                // リバランスボタン
                _buildRebalanceButton(context),
                const SizedBox(height: 16),
                // 銘柄数ヘッダー
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '保有銘柄 (${summary.stocks.length})',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '株価更新: 大引け後自動更新',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        // 銘柄カード一覧
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final swr = summary.stocks[i];
                return StockCardMobile(
                  stockWithRatio: swr,
                  index: i,
                  totalValue: summary.totalValue,
                  onEdit: () => context.go('/stock/edit/${swr.stock.code}'),
                  onDelete: () =>
                      _confirmDelete(context, ref, swr.stock.code),
                );
              },
              childCount: summary.stocks.length,
            ),
          ),
        ),
        const SliverPadding(
          padding: EdgeInsets.only(bottom: 80), // FABの余白
        ),
      ],
    );
  }

  // ========== サマリーカード ==========
  Widget _buildSummaryCards(PortfolioSummary summary, {bool isRow = false}) {
    final cards = [
      _SummaryCardData(
        label: '総評価額',
        value: formatCurrency(summary.totalValue),
        icon: Icons.account_balance_wallet_rounded,
        color: AppColors.teal,
        sub: '損益: ${formatPercent(summary.totalProfitLossRate)}',
        subColor: summary.totalProfitLoss >= 0
            ? AppColors.positive
            : AppColors.negative,
      ),
      _SummaryCardData(
        label: '年間配当合計',
        value: formatCurrency(summary.totalDividend),
        icon: Icons.payments_rounded,
        color: AppColors.warning,
        sub: '銘柄数: ${summary.stocks.length}',
        subColor: AppColors.textSecondary,
      ),
      _SummaryCardData(
        label: '要リバランス',
        value: '${summary.underweightStocks.length}銘柄',
        icon: Icons.balance_rounded,
        color: summary.underweightStocks.isEmpty
            ? AppColors.positive
            : AppColors.negative,
        sub: summary.underweightStocks.isEmpty ? '理想比率達成中' : '買い増しが必要',
        subColor: summary.underweightStocks.isEmpty
            ? AppColors.positive
            : AppColors.negative,
      ),
    ];

    if (isRow) {
      return Row(
        children: cards
            .map((c) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _SummaryCard(data: c),
                  ),
                ))
            .toList(),
      );
    }
    return Row(
      children: cards
          .map((c) => Expanded(child: _SummaryCard(data: c, compact: true)))
          .toList(),
    );
  }

  Widget _buildSummaryCardsMobile(PortfolioSummary summary) {
    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildMiniCard('総評価額', formatCurrency(summary.totalValue),
              AppColors.teal, Icons.account_balance_wallet_rounded),
          const SizedBox(width: 10),
          _buildMiniCard('年間配当', formatCurrency(summary.totalDividend),
              AppColors.warning, Icons.payments_rounded),
          const SizedBox(width: 10),
          _buildMiniCard(
            '要リバランス',
            '${summary.underweightStocks.length}銘柄',
            summary.underweightStocks.isEmpty
                ? AppColors.positive
                : AppColors.negative,
            Icons.balance_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCard(
      String label, String value, Color color, IconData icon) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRebalanceButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [AppColors.teal, Color(0xFF0066CC)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => context.go('/rebalance'),
          borderRadius: BorderRadius.circular(14),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.balance_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text(
                  'リバランス計算を実行',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded,
                    color: Colors.white70, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, String code) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('銘柄を削除',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          '証券コード「$code」を削除しますか？\nこの操作は元に戻せません。',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.negative,
              foregroundColor: Colors.white,
            ),
            child: const Text('削除する'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(stockActionsProvider).delete(code);
    }
  }
}

// ========== データクラス ==========
class _SummaryCardData {
  const _SummaryCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.sub,
    required this.subColor,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String sub;
  final Color subColor;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data, this.compact = false});
  final _SummaryCardData data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 14 : 20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: data.color.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: data.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(data.icon, color: data.color, size: 18),
              ),
              const Spacer(),
            ],
          ),
          SizedBox(height: compact ? 10 : 14),
          Text(
            data.label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.value,
            style: TextStyle(
              color: data.color,
              fontSize: compact ? 18 : 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.sub,
            style: TextStyle(
              color: data.subColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
