import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'stock.freezed.dart';
part 'stock.g.dart';

/// Firestoreのタイムスタンプをdatetimeに変換するコンバーター
class TimestampConverter implements JsonConverter<DateTime?, dynamic> {
  const TimestampConverter();

  @override
  DateTime? fromJson(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is String) return DateTime.tryParse(timestamp);
    return null;
  }

  @override
  dynamic toJson(DateTime? date) {
    if (date == null) return null;
    return Timestamp.fromDate(date);
  }
}

@freezed
class Stock with _$Stock {
  const Stock._();

  const factory Stock({
    required String id,             // Firestore ドキュメントID (= 証券コード)
    required String code,           // 証券コード (例: "7203")
    required String name,           // 会社名 (例: "トヨタ自動車")
    @Default(0.0) double price,     // 現在株価（yfinanceが更新）
    @Default(0.0) double dividend,  // 年間配当金（円/株）
    @Default(0) int shares,         // 保有株数
    @Default(0.0) double purchasePrice, // 平均買付単価（円）
    @Default(0.0) double targetRatio,   // 理想比率（%）
    @Default(0) int displayOrder,       // 表示順
    @TimestampConverter() DateTime? priceUpdatedAt, // 株価更新日時
    @TimestampConverter() DateTime? createdAt,
    @TimestampConverter() DateTime? updatedAt,
  }) = _Stock;

  factory Stock.fromJson(Map<String, dynamic> json) => _$StockFromJson(json);

  /// 現在評価額（株価 × 保有株数）
  double get currentValue => price * shares;

  /// 損益額（評価額 - 取得価格合計）
  double get profitLoss => currentValue - (purchasePrice * shares);

  /// 損益率（%）
  double get profitLossRate {
    if (purchasePrice <= 0) return 0.0;
    return (price - purchasePrice) / purchasePrice * 100;
  }

  /// 年間配当合計（円）
  double get totalDividend => dividend * shares;

  /// 配当利回り（%）
  double get dividendYield {
    if (price <= 0) return 0.0;
    return dividend / price * 100;
  }

  factory Stock.empty() => const Stock(id: '', code: '', name: '');
}
