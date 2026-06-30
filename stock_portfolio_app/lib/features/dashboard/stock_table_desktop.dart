import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/portfolio_summary.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';

/// デスクトップ用データテーブル
class StockTableDesktop extends StatelessWidget {
  const StockTableDesktop({
    super.key,
    required this.summary,
    required this.onEdit,
    required this.onDelete,
  });

  final PortfolioSummary summary;
  final void Function(String code) onEdit;
  final void Function(String code) onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // テーブルヘッダー
          _buildHeader(),
          const Divider(height: 1, color: AppColors.border),
          // テーブル行
          if (summary.stocks.isEmpty)
            _buildEmptyRow()
          else
            ...summary.stocks.asMap().entries.map((e) {
              return Column(
                children: [
                  _buildDataRow(e.value, e.key),
                  if (e.key < summary.stocks.length - 1)
                    const Divider(
                      height: 1,
                      color: AppColors.border,
                      indent: 16,
                      endIndent: 16,
                    ),
                ],
              );
            }),
          // 合計行
          if (summary.stocks.isNotEmpty) ...[
            const Divider(height: 1, color: AppColors.border),
            _buildTotalRow(),
          ],
        ],
      ),
    );
  }

  static const _colWidths = [
    80.0,  // コード
    150.0, // 会社名
    100.0, // 株価
    100.0, // 配当金
    80.0,  // 現在%
    80.0,  // 理想%
    80.0,  // 差引%
    80.0,  // アクション
  ];

  Widget _buildHeader() {
    const headers = [
      '証券コード',
      '会社名',
      '株価',
      '配当金(年)',
      '現在%',
      '理想%',
      '差引%',
      '',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: List.generate(headers.length, (i) {
          return SizedBox(
            width: _colWidths[i],
            child: Text(
              headers[i],
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDataRow(StockWithRatio swr, int index) {
    final stock = swr.stock;
    final gap = swr.gap;
    final gapColor = gap < -0.1
        ? AppColors.negative
        : gap > 0.1
            ? AppColors.positive
            : AppColors.textSecondary;
    final chartColor = AppColors.chartColors[index % AppColors.chartColors.length];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onEdit(stock.code),
        borderRadius: BorderRadius.circular(0),
        hoverColor: AppColors.surface.withOpacity(0.5),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // 証券コード
              SizedBox(
                width: _colWidths[0],
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: chartColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      stock.code,
                      style: const TextStyle(
                        color: AppColors.teal,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              // 会社名
              SizedBox(
                width: _colWidths[1],
                child: Text(
                  stock.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // 株価
              SizedBox(
                width: _colWidths[2],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatStockPrice(stock.price),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${formatShares(stock.shares)}保有',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // 配当金
              SizedBox(
                width: _colWidths[3],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${formatCurrency(stock.dividend)}/株',
                      style: const TextStyle(
                        color: AppColors.warning,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '計${formatCurrency(stock.totalDividend)}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // 現在%
              SizedBox(
                width: _colWidths[4],
                child: _RatioBadge(
                  value: swr.currentRatio,
                  color: chartColor,
                ),
              ),
              // 理想%
              SizedBox(
                width: _colWidths[5],
                child: _RatioBadge(
                  value: swr.targetRatio,
                  color: AppColors.textSecondary,
                ),
              ),
              // 差引%
              SizedBox(
                width: _colWidths[6],
                child: Row(
                  children: [
                    if (gap < -0.1)
                      const Icon(
                        Icons.arrow_downward_rounded,
                        color: AppColors.negative,
                        size: 14,
                      )
                    else if (gap > 0.1)
                      const Icon(
                        Icons.arrow_upward_rounded,
                        color: AppColors.positive,
                        size: 14,
                      ),
                    const SizedBox(width: 2),
                    Text(
                      formatPercent(gap),
                      style: TextStyle(
                        color: gapColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              // アクション
              SizedBox(
                width: _colWidths[7],
                child: Row(
                  children: [
                    _ActionIconButton(
                      icon: Icons.edit_outlined,
                      color: AppColors.textSecondary,
                      tooltip: '編集',
                      onTap: () => onEdit(stock.code),
                    ),
                    const SizedBox(width: 4),
                    _ActionIconButton(
                      icon: Icons.delete_outline_rounded,
                      color: AppColors.negative.withOpacity(0.7),
                      tooltip: '削除',
                      onTap: () => onDelete(stock.code),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // コード
          SizedBox(
            width: _colWidths[0],
            child: const Text(
              '合計',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: _colWidths[1]),
          // 総評価額
          SizedBox(
            width: _colWidths[2],
            child: Text(
              formatCurrency(summary.totalValue),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // 総配当
          SizedBox(
            width: _colWidths[3],
            child: Text(
              formatCurrency(summary.totalDividend),
              style: const TextStyle(
                color: AppColors.warning,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // 現在% 合計
          SizedBox(
            width: _colWidths[4],
            child: Text(
              '${summary.stocks.fold<double>(0, (s, e) => s + e.currentRatio).toStringAsFixed(1)}%',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // 理想% 合計
          SizedBox(
            width: _colWidths[5],
            child: Text(
              '${summary.stocks.fold<double>(0, (s, e) => s + e.targetRatio).toStringAsFixed(1)}%',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRow() {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: Center(
        child: Text(
          '銘柄を追加してください',
          style: TextStyle(color: AppColors.textMuted),
        ),
      ),
    );
  }
}

class _RatioBadge extends StatelessWidget {
  const _RatioBadge({required this.value, required this.color});
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      formatPercentAbs(value, decimals: 1),
      style: TextStyle(
        color: color,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}
