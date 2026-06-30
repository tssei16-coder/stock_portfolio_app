import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/portfolio_summary.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';

class PortfolioPieChart extends StatefulWidget {
  const PortfolioPieChart({
    super.key,
    required this.summary,
    this.compact = false,
  });

  final PortfolioSummary summary;
  final bool compact; // スマホ用コンパクトモード

  @override
  State<PortfolioPieChart> createState() => _PortfolioPieChartState();
}

class _PortfolioPieChartState extends State<PortfolioPieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final stocks = widget.summary.stocks;
    if (stocks.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      padding: EdgeInsets.all(widget.compact ? 16 : 24),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.compact) ...[
            const Text(
              'ポートフォリオ構成',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '総評価額: ${formatCurrency(widget.summary.totalValue)}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
          ],
          widget.compact ? _buildCompactLayout(stocks) : _buildFullLayout(stocks),
        ],
      ),
    );
  }

  Widget _buildFullLayout(List<StockWithRatio> stocks) {
    return Column(
      children: [
        SizedBox(
          height: 260,
          child: _buildPieChart(stocks),
        ),
        const SizedBox(height: 24),
        _buildLegend(stocks),
      ],
    );
  }

  Widget _buildCompactLayout(List<StockWithRatio> stocks) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: SizedBox(
            height: 180,
            child: _buildPieChart(stocks),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 5,
          child: _buildLegend(stocks, compact: true),
        ),
      ],
    );
  }

  Widget _buildPieChart(List<StockWithRatio> stocks) {
    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (event, response) {
            setState(() {
              if (!event.isInterestedForInteractions ||
                  response == null ||
                  response.touchedSection == null) {
                _touchedIndex = -1;
                return;
              }
              _touchedIndex =
                  response.touchedSection!.touchedSectionIndex;
            });
          },
        ),
        sections: _buildSections(stocks),
        centerSpaceRadius: 56,
        sectionsSpace: 2,
        startDegreeOffset: -90,
      ),
    );
  }

  List<PieChartSectionData> _buildSections(List<StockWithRatio> stocks) {
    return List.generate(stocks.length, (i) {
      final stock = stocks[i];
      final isTouched = i == _touchedIndex;
      final color = AppColors.chartColors[i % AppColors.chartColors.length];

      return PieChartSectionData(
        color: color,
        value: stock.currentRatio,
        radius: isTouched ? 88 : 76,
        title: isTouched
            ? '${stock.stock.name}\n${formatPercentAbs(stock.currentRatio, decimals: 1)}'
            : stock.currentRatio >= 5
                ? formatPercentAbs(stock.currentRatio, decimals: 1)
                : '',
        titleStyle: TextStyle(
          color: Colors.white,
          fontSize: isTouched ? 11 : 10,
          fontWeight: FontWeight.w600,
          shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
        ),
        badgeWidget: isTouched
            ? null
            : null,
      );
    });
  }

  Widget _buildLegend(List<StockWithRatio> stocks, {bool compact = false}) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: List.generate(stocks.length, (i) {
        final stock = stocks[i];
        final color = AppColors.chartColors[i % AppColors.chartColors.length];
        final isTouched = i == _touchedIndex;

        return GestureDetector(
          onTap: () => setState(() {
            _touchedIndex = isTouched ? -1 : i;
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isTouched
                  ? color.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isTouched ? color : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  compact
                      ? stock.stock.code
                      : '${stock.stock.code} ${stock.stock.name}',
                  style: TextStyle(
                    color: isTouched
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: compact ? 11 : 12,
                    fontWeight: isTouched
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(width: 6),
                  Text(
                    formatPercentAbs(stock.currentRatio, decimals: 1),
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.pie_chart_outline_rounded,
            color: AppColors.textMuted,
            size: 56,
          ),
          SizedBox(height: 12),
          Text(
            '銘柄を追加するとグラフが表示されます',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
