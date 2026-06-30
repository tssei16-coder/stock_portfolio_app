import 'package:flutter/material.dart';
import '../../models/portfolio_summary.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';

/// モバイル・タブレット用 銘柄カード
class StockCardMobile extends StatelessWidget {
  const StockCardMobile({
    super.key,
    required this.stockWithRatio,
    required this.index,
    required this.totalValue,
    required this.onEdit,
    required this.onDelete,
  });

  final StockWithRatio stockWithRatio;
  final int index;
  final double totalValue;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final stock = stockWithRatio.stock;
    final gap = stockWithRatio.gap;
    final chartColor =
        AppColors.chartColors[index % AppColors.chartColors.length];
    final gapColor = gap < -0.1
        ? AppColors.negative
        : gap > 0.1
            ? AppColors.positive
            : AppColors.textSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: gap < -0.5
              ? AppColors.negative.withOpacity(0.4)
              : AppColors.border,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ヘッダー行
                Row(
                  children: [
                    // カラードット
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: chartColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: chartColor.withOpacity(0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // コード
                    Text(
                      stock.code,
                      style: TextStyle(
                        color: chartColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 会社名
                    Expanded(
                      child: Text(
                        stock.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // 差引%バッジ
                    _GapBadge(gap: gap, color: gapColor),
                    // アクションメニュー
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      color: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      onSelected: (value) {
                        if (value == 'edit') onEdit();
                        if (value == 'delete') onDelete();
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined,
                                  color: AppColors.textSecondary, size: 18),
                              SizedBox(width: 8),
                              Text('編集', style: TextStyle(color: AppColors.textPrimary)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded,
                                  color: AppColors.negative, size: 18),
                              SizedBox(width: 8),
                              Text('削除', style: TextStyle(color: AppColors.negative)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // データ行
                Row(
                  children: [
                    // 株価・保有株数
                    Expanded(
                      child: _DataCell(
                        label: '株価',
                        value: formatStockPrice(stock.price),
                        sub: '${formatShares(stock.shares)}保有',
                      ),
                    ),
                    // 配当金
                    Expanded(
                      child: _DataCell(
                        label: '配当金(年)',
                        value: '${formatCurrency(stock.dividend)}/株',
                        sub: '計${formatCurrency(stock.totalDividend)}',
                        valueColor: AppColors.warning,
                      ),
                    ),
                    // 評価額
                    Expanded(
                      child: _DataCell(
                        label: '評価額',
                        value: formatCurrency(stock.currentValue),
                        sub: formatPercent(stock.profitLossRate),
                        valueColor: stock.profitLoss >= 0
                            ? AppColors.positive
                            : AppColors.negative,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 比率プログレスバー
                _RatioProgressBar(
                  currentRatio: stockWithRatio.currentRatio,
                  targetRatio: stockWithRatio.targetRatio,
                  chartColor: chartColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GapBadge extends StatelessWidget {
  const _GapBadge({required this.gap, required this.color});
  final double gap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            gap < -0.1
                ? Icons.arrow_downward_rounded
                : gap > 0.1
                    ? Icons.arrow_upward_rounded
                    : Icons.remove_rounded,
            color: color,
            size: 12,
          ),
          const SizedBox(width: 2),
          Text(
            formatPercent(gap, decimals: 1),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DataCell extends StatelessWidget {
  const _DataCell({
    required this.label,
    required this.value,
    required this.sub,
    this.valueColor = AppColors.textPrimary,
  });

  final String label;
  final String value;
  final String sub;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            color: valueColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          sub,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _RatioProgressBar extends StatelessWidget {
  const _RatioProgressBar({
    required this.currentRatio,
    required this.targetRatio,
    required this.chartColor,
  });

  final double currentRatio;
  final double targetRatio;
  final Color chartColor;

  @override
  Widget build(BuildContext context) {
    final maxRatio = targetRatio > currentRatio ? targetRatio : currentRatio;
    final safeMax = maxRatio > 0 ? maxRatio : 1.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '現在 ${formatPercentAbs(currentRatio, decimals: 1)}',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
            Text(
              '理想 ${formatPercentAbs(targetRatio, decimals: 1)}',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // 現在比率バー
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            children: [
              // 背景
              Container(
                height: 8,
                width: double.infinity,
                color: AppColors.surface,
              ),
              // 理想比率マーク（縦線）
              FractionallySizedBox(
                widthFactor: (targetRatio / safeMax).clamp(0.0, 1.0),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              // 現在比率バー
              FractionallySizedBox(
                widthFactor: (currentRatio / safeMax).clamp(0.0, 1.0),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: chartColor,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: chartColor.withOpacity(0.4),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
