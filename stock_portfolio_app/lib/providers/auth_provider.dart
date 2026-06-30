import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/stock_repository.dart';

/// Firebase Auth インスタンス
final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

/// 認証状態ストリーム
final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(firebaseAuthProvider).authStateChanges(),
);

/// StockRepository プロバイダー
final stockRepositoryProvider = Provider<StockRepository>(
  (ref) => StockRepository(),
);

/// ログイン処理プロバイダー
final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, User?>(() => AuthNotifier());

class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    return FirebaseAuth.instance.currentUser;
  }

  /// メールアドレス・パスワードでサインイン
  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      return credential.user;
    });
  }

  /// サインアウト
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    state = const AsyncData(null);
  }

  /// アカウント作成（初回登録用）
  Future<void> createAccount(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      return credential.user;
    });
  }
}
