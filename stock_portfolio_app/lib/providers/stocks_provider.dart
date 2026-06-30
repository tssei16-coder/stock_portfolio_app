import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/stock.dart';
import '../models/portfolio_summary.dart';
import '../repositories/stock_repository.dart';
import 'auth_provider.dart';

/// 銘柄一覧ストリームプロバイダー（Firestoreリアルタイム購読）
final stocksStreamProvider = StreamProvider<List<Stock>>((ref) {
  final repo = ref.watch(stockRepositoryProvider);
  return repo.watchStocks();
});

/// ポートフォリオ集計プロバイダー
final portfolioSummaryProvider = Provider<AsyncValue<PortfolioSummary>>((ref) {
  final stocksAsync = ref.watch(stocksStreamProvider);

  return stocksAsync.whenData((stocks) {
    if (stocks.isEmpty) return PortfolioSummary.empty();

    // 総評価額を計算
    final totalValue =
        stocks.fold<double>(0, (sum, s) => sum + s.currentValue);
    final totalDividend =
        stocks.fold<double>(0, (sum, s) => sum + s.totalDividend);
    final totalCost = stocks.fold<double>(
        0, (sum, s) => sum + s.purchasePrice * s.shares);

    // 各銘柄の現在比率を計算
    final stocksWithRatio = stocks.map((stock) {
      final currentRatio =
          totalValue > 0 ? stock.currentValue / totalValue * 100 : 0.0;
      return StockWithRatio(
        stock: stock,
        currentRatio: currentRatio,
        targetRatio: stock.targetRatio,
      );
    }).toList();

    return PortfolioSummary(
      stocks: stocksWithRatio,
      totalValue: totalValue,
      totalDividend: totalDividend,
      totalCost: totalCost,
    );
  });
});

/// 銘柄操作プロバイダー（追加・更新・削除）
final stockActionsProvider = Provider<StockActions>((ref) {
  final repo = ref.watch(stockRepositoryProvider);
  return StockActions(repo);
});

class StockActions {
  StockActions(this._repo);
  final StockRepository _repo;

  Future<void> add(Stock stock) => _repo.addStock(stock);
  Future<void> update(Stock stock) => _repo.updateStock(stock);
  Future<void> delete(String code) => _repo.deleteStock(code);
}
