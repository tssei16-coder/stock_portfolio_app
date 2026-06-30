import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/portfolio_summary.dart';
import '../../providers/stocks_provider.dart';
import '../../repositories/stock_repository.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import '../../providers/auth_provider.dart';

class RebalanceScreen extends ConsumerStatefulWidget {
  const RebalanceScreen({super.key});

  @override
  ConsumerState<RebalanceScreen> createState() => _RebalanceScreenState();
}

class _RebalanceScreenState extends ConsumerState<RebalanceScreen> {
  final _budgetController = TextEditingController();
  double _budget = 0;
  bool _budgetEntered = false;

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(portfolioSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('リバランス計算'),
        leading: IconButton(
          onPressed: () => context.go('/dashboard'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: summaryAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.teal)),
        error: (e, _) => Center(child: Text('エラー: $e')),
        data: (summary) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 説明カード
                _buildInfoCard(),
                const SizedBox(height: 20),
                // 予算入力
                _buildBudgetInput(summary),
                const SizedBox(height: 20),
                // リバランス結果
                if (_budgetEntered && _budget > 0)
                  _buildRebalanceResults(summary),
                // 全銘柄の比率状況
                const SizedBox(height: 20),
                _buildAllStocksStatus(summary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.teal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.teal.withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.teal, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              '「差引%」がマイナスの銘柄に対し、理想比率に近づけるための\n買い増し株数と金額を自動計算します。',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetInput(PortfolioSummary summary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '今回の投資予算',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '追加投資できる金額を入力してください',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _budgetController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    prefixText: '¥ ',
                    prefixStyle: TextStyle(
                      color: AppColors.teal,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                    hintText: '500,000',
                    hintStyle: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  final raw = _budgetController.text
                      .replaceAll(',', '')
                      .replaceAll('¥', '')
                      .trim();
                  final parsed = double.tryParse(raw);
                  if (parsed != null && parsed > 0) {
                    setState(() {
                      _budget = parsed;
                      _budgetEntered = true;
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('正しい金額を入力してください'),
                        backgroundColor: AppColors.negative,
                      ),
                    );
                  }
                },
                child: const Text('計算する'),
              ),
            ],
          ),
          // プリセットボタン
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [50000, 100000, 300000, 500000].map((amount) {
              return OutlinedButton(
                onPressed: () {
                  _budgetController.text = amount.toString();
                  setState(() {
                    _budget = amount.toDouble();
                    _budgetEntered = true;
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.border),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  textStyle: const TextStyle(fontSize: 12),
                ),
                child: Text(formatCurrency(amount.toDouble())),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRebalanceResults(PortfolioSummary summary) {
    final underweight = summary.underweightStocks;
    if (underweight.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.positive.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.positive.withOpacity(0.3)),
        ),
        child: const Column(
          children: [
            Icon(Icons.check_circle_rounded,
                color: AppColors.positive, size: 48),
            SizedBox(height: 12),
            Text(
              '理想比率を達成中！',
              style: TextStyle(
                color: AppColors.positive,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '現在のポートフォリオは理想比率に近い状態です。',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    // 予算配分：差引%の絶対値に比例して配分
    final totalGap =
        underweight.fold<double>(0, (s, e) => s + e.gap.abs());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📊 買い増し推奨リスト',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '予算 ${formatCurrency(_budget)} をギャップ比率で配分した場合',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 12),
        ...underweight.asMap().entries.map((e) {
          final swr = e.value;
          final stock = swr.stock;
          final allocated = totalGap > 0
              ? _budget * swr.gap.abs() / totalGap
              : _budget / underweight.length;
          final shares = stock.price > 0
              ? (allocated / stock.price).floor()
              : 0;
          final actualCost = shares * stock.price;

          return _buildRebalanceCard(
            swr: swr,
            index: e.key,
            allocatedBudget: allocated,
            recommendedShares: shares,
            actualCost: actualCost,
          );
        }),
        // 合計サマリー
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '予算合計',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              Text(
                formatCurrency(_budget),
                style: const TextStyle(
                  color: AppColors.teal,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRebalanceCard({
    required StockWithRatio swr,
    required int index,
    required double allocatedBudget,
    required int recommendedShares,
    required double actualCost,
  }) {
    final stock = swr.stock;
    final color = AppColors.chartColors[
        (swr.stock.displayOrder) % AppColors.chartColors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.negative.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.negative,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                stock.code,
                style: const TextStyle(
                  color: AppColors.teal,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  stock.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // 差引%
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.negative.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '差引 ${formatPercent(swr.gap, decimals: 2)}',
                  style: const TextStyle(
                    color: AppColors.negative,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 計算結果グリッド
          Row(
            children: [
              _ResultCell(
                label: '現在株価',
                value: formatStockPrice(stock.price),
                color: AppColors.textPrimary,
              ),
              _ResultCell(
                label: '推奨買い増し株数',
                value: '$recommendedShares 株',
                color: AppColors.teal,
                isHighlight: true,
              ),
              _ResultCell(
                label: '必要金額（概算）',
                value: formatCurrency(actualCost),
                color: AppColors.warning,
                isHighlight: true,
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 買い増し後の予想比率
          if (stock.price > 0 && recommendedShares > 0) ...[
            const Divider(color: AppColors.border),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '買い増し後の評価額: ${formatCurrency(stock.currentValue + actualCost)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '目標: ${formatPercentAbs(swr.targetRatio, decimals: 1)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAllStocksStatus(PortfolioSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '全銘柄の比率状況',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: summary.stocks.asMap().entries.map((e) {
              final swr = e.value;
              final stock = swr.stock;
              final gap = swr.gap;
              final color = AppColors.chartColors[
                  e.key % AppColors.chartColors.length];
              final gapColor = gap < -0.1
                  ? AppColors.negative
                  : gap > 0.1
                      ? AppColors.positive
                      : AppColors.textSecondary;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 60,
                          child: Text(
                            stock.code,
                            style: TextStyle(
                              color: color,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            stock.name,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '現在: ${formatPercentAbs(swr.currentRatio, decimals: 1)}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '理想: ${formatPercentAbs(swr.targetRatio, decimals: 1)}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 70,
                          child: Text(
                            formatPercent(gap, decimals: 2),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: gapColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (e.key < summary.stocks.length - 1)
                    const Divider(
                      height: 1,
                      color: AppColors.border,
                      indent: 16,
                      endIndent: 16,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _ResultCell extends StatelessWidget {
  const _ResultCell({
    required this.label,
    required this.value,
    required this.color,
    this.isHighlight = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool isHighlight;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isHighlight ? color.withOpacity(0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                isHighlight ? color.withOpacity(0.3) : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isHighlight ? color.withOpacity(0.8) : AppColors.textMuted,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
