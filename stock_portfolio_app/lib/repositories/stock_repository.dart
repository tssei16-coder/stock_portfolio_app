import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/stock.dart';

/// Firestoreへのアクセスを担うリポジトリ
class StockRepository {
  StockRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('ログインが必要です');
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _stocksRef =>
      _firestore.collection('users').doc(_uid).collection('stocks');

  /// 銘柄一覧をリアルタイムで購読
  Stream<List<Stock>> watchStocks() {
    return _stocksRef
        .orderBy('displayOrder')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Stock.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  /// 銘柄を追加
  Future<void> addStock(Stock stock) async {
    final now = Timestamp.now();
    await _stocksRef.doc(stock.code).set({
      ...stock.toJson(),
      'id': stock.code,
      'createdAt': now,
      'updatedAt': now,
      'priceUpdatedAt': now,
    });

    // 銘柄追加後にバックグラウンドでRenderの更新APIを叩く（非同期で投げっぱなし）
    try {
      final url = Uri.parse('https://stock-portfolio-app-8l81.onrender.com/api/update_all');
      http.get(url).timeout(const Duration(seconds: 5)).catchError((_) => http.Response('', 500));
      debugPrint('[StockRepository] Triggered Render update_all API after addStock.');
    } catch (e) {
      debugPrint('[StockRepository] Failed to trigger update_all API: $e');
    }
  }

  /// 銘柄を更新（株価以外のフィールド）
  Future<void> updateStock(Stock stock) async {
    await _stocksRef.doc(stock.code).update({
      ...stock.toJson(),
      'updatedAt': Timestamp.now(),
    });
  }

  /// 銘柄を削除
  Future<void> deleteStock(String code) async {
    await _stocksRef.doc(code).delete();
  }

  /// 単一銘柄の株価だけを更新（Pythonスクリプトも同じパスを使う）
  Future<void> updatePrice(String code, double price) async {
    await _stocksRef.doc(code).update({
      'price': price,
      'priceUpdatedAt': Timestamp.now(),
    });
  }

  /// 月次予算を取得
  Future<double> getMonthlyBudget() async {
    final doc =
        await _firestore.collection('users').doc(_uid).get();
    return (doc.data()?['monthlyBudget'] as num?)?.toDouble() ?? 0.0;
  }

  /// 月次予算を保存
  Future<void> saveMonthlyBudget(double budget) async {
    await _firestore
        .collection('users')
        .doc(_uid)
        .set({'monthlyBudget': budget}, SetOptions(merge: true));
  }
}
