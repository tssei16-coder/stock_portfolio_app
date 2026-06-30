import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isCreatingAccount = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authNotifier = ref.read(authNotifierProvider.notifier);
    if (_isCreatingAccount) {
      await authNotifier.createAccount(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } else {
      await authNotifier.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }

    final authState = ref.read(authNotifierProvider);
    if (mounted && authState.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _getErrorMessage(authState.error.toString()),
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          backgroundColor: AppColors.negative,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (mounted && authState.valueOrNull != null) {
      context.go('/dashboard');
    }
  }

  String _getErrorMessage(String error) {
    if (error.contains('user-not-found')) return 'メールアドレスが見つかりません';
    if (error.contains('wrong-password')) return 'パスワードが違います';
    if (error.contains('invalid-email')) return 'メールアドレスの形式が正しくありません';
    if (error.contains('email-already-in-use')) return 'このメールアドレスは既に使用されています';
    if (error.contains('weak-password')) return 'パスワードは6文字以上にしてください';
    if (error.contains('network-request-failed')) return 'ネットワークエラーが発生しました';
    return 'エラーが発生しました。もう一度お試しください';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: Stack(
        children: [
          // 背景グラデーション
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.5, -0.8),
                radius: 1.2,
                colors: [
                  Color(0xFF1A2A4A),
                  AppColors.background,
                ],
              ),
            ),
          ),
          // グロー効果
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.teal.withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // メインコンテンツ
          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ロゴ・タイトル
                      _buildLogo(),
                      const SizedBox(height: 48),
                      // ログインカード
                      _buildLoginCard(isLoading),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.teal, Color(0xFF0066CC)],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.teal.withOpacity(0.4),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(
            Icons.candlestick_chart_rounded,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'マイ株管理',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 30,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'ポートフォリオ管理・リバランスアプリ',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard(bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isCreatingAccount ? 'アカウント作成' : 'ログイン',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 28),

            // メールアドレス
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'メールアドレス',
                prefixIcon: Icon(Icons.email_outlined, color: AppColors.textSecondary),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'メールアドレスを入力してください';
                if (!value.contains('@')) return 'メールアドレスの形式が正しくありません';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // パスワード
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'パスワード',
                prefixIcon: const Icon(Icons.lock_outlined, color: AppColors.textSecondary),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'パスワードを入力してください';
                if (value.length < 6) return 'パスワードは6文字以上にしてください';
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 28),

            // ログインボタン
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.background,
                        ),
                      )
                    : Text(
                        _isCreatingAccount ? 'アカウントを作成' : 'ログイン',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // アカウント作成 / ログイン切り替え
            Center(
              child: TextButton(
                onPressed: () =>
                    setState(() => _isCreatingAccount = !_isCreatingAccount),
                child: Text(
                  _isCreatingAccount
                      ? '既にアカウントをお持ちの方はこちら'
                      : '初めてのご利用はこちら（アカウント作成）',
                  style: const TextStyle(
                    color: AppColors.teal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
