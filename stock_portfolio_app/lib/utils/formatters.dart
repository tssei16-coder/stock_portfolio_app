import 'package:intl/intl.dart';

/// 日本円フォーマット（例: ¥1,234,567）
final _currencyFormatter = NumberFormat('#,###', 'ja_JP');
final _currencyFormatterFull = NumberFormat('¥#,###', 'ja_JP');

String formatCurrency(double amount) {
  return '¥${_currencyFormatter.format(amount.round())}';
}

String formatCurrencyFull(double amount) {
  return _currencyFormatterFull.format(amount.round());
}

/// パーセンテージフォーマット（例: +3.21%）
String formatPercent(double value, {int decimals = 2}) {
  final sign = value >= 0 ? '+' : '';
  return '$sign${value.toStringAsFixed(decimals)}%';
}

/// パーセンテージ（符号なし）
String formatPercentAbs(double value, {int decimals = 2}) {
  return '${value.toStringAsFixed(decimals)}%';
}

/// 株価フォーマット（整数）
String formatStockPrice(double price) {
  return '¥${_currencyFormatter.format(price.round())}';
}

/// 株数フォーマット
String formatShares(int shares) {
  return '$shares株';
}

/// 日付フォーマット（株価更新日時用）
String formatDateTime(DateTime? dateTime) {
  if (dateTime == null) return '--';
  return DateFormat('MM/dd HH:mm').format(dateTime);
}

String formatDate(DateTime? dateTime) {
  if (dateTime == null) return '--';
  return DateFormat('yyyy/MM/dd').format(dateTime);
}
