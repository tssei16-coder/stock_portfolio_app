import 'package:freezed_annotation/freezed_annotation.dart';
import 'stock.dart';

part 'portfolio_summary.freezed.dart';

@freezed
class PortfolioSummary with _$PortfolioSummary {
  const PortfolioSummary._();

  const factory PortfolioSummary({
    @Default([]) List<StockWithRatio> stocks,
    @Default(0.0) double totalValue,    // 総評価額
    @Default(0.0) double totalDividend, // 年間配当合計
    @Default(0.0) double totalCost,     // 総取得コスト
  }) = _PortfolioSummary;

  /// 総損益額
  double get totalProfitLoss => totalValue - totalCost;

  /// 総損益率
  double get totalProfitLossRate {
    if (totalCost <= 0) return 0.0;
    return totalProfitLoss / totalCost * 100;
  }

  /// 差引%がマイナス（買い増しが必要）な銘柄のみ
  List<StockWithRatio> get underweightStocks =>
      stocks.where((s) => s.gap < -0.01).toList()
        ..sort((a, b) => a.gap.compareTo(b.gap));

  factory PortfolioSummary.empty() => const PortfolioSummary();
}

/// 比率計算済みのStock
@freezed
class StockWithRatio with _$StockWithRatio {
  const StockWithRatio._();

  const factory StockWithRatio({
    required Stock stock,
    @Default(0.0) double currentRatio,  // 現在保有比率（%）
    @Default(0.0) double targetRatio,   // 理想比率（%）
  }) = _StockWithRatio;

  /// 差引%（理想 - 現在）
  double get gap => targetRatio - currentRatio;

  /// 不足している評価額（円）
  double gapValue(double totalValue) => gap / 100 * totalValue;

  /// 買い増しに必要な株数（切り上げ）
  int requiredShares(double totalValue) {
    if (stock.price <= 0) return 0;
    final neededValue = gapValue(totalValue);
    if (neededValue <= 0) return 0;
    return (neededValue / stock.price).ceil();
  }

  /// 買い増しに必要な金額（円）
  double requiredAmount(double totalValue) {
    final shares = requiredShares(totalValue);
    return shares * stock.price;
  }
}
