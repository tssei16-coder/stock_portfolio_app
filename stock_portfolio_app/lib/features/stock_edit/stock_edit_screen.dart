import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/stock.dart';
import '../../providers/stocks_provider.dart';
import '../../utils/app_theme.dart';

class StockEditScreen extends ConsumerStatefulWidget {
  const StockEditScreen({super.key, this.stockCode});
  final String? stockCode; // null の場合は新規追加

  @override
  ConsumerState<StockEditScreen> createState() => _StockEditScreenState();
}

class _StockEditScreenState extends ConsumerState<StockEditScreen> {
  final _formKey = GlobalKey<FormState>();

  // フォームコントローラー
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _dividendCtrl = TextEditingController();
  final _sharesCtrl = TextEditingController();
  final _purchasePriceCtrl = TextEditingController();
  final _targetRatioCtrl = TextEditingController();
  final _displayOrderCtrl = TextEditingController();

  bool _isLoading = false;
  bool _isEditing = false;
  Stock? _existingStock;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.stockCode != null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isEditing && _existingStock == null) {
      _loadExistingStock();
    }
  }

  void _loadExistingStock() {
    final summaryAsync = ref.read(portfolioSummaryProvider);
    summaryAsync.whenData((summary) {
      final match = summary.stocks.where(
        (s) => s.stock.code == widget.stockCode,
      );
      if (match.isNotEmpty) {
        final stock = match.first.stock;
        setState(() {
          _existingStock = stock;
          _codeCtrl.text = stock.code;
          _nameCtrl.text = stock.name;
          _priceCtrl.text = stock.price.toStringAsFixed(0);
          _dividendCtrl.text = stock.dividend.toStringAsFixed(0);
          _sharesCtrl.text = stock.shares.toString();
          _purchasePriceCtrl.text = stock.purchasePrice.toStringAsFixed(0);
          _targetRatioCtrl.text = stock.targetRatio.toStringAsFixed(1);
          _displayOrderCtrl.text = stock.displayOrder.toString();
        });
      }
    });
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _dividendCtrl.dispose();
    _sharesCtrl.dispose();
    _purchasePriceCtrl.dispose();
    _targetRatioCtrl.dispose();
    _displayOrderCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final stock = Stock(
        id: _codeCtrl.text.trim(),
        code: _codeCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        price: double.tryParse(_priceCtrl.text) ?? 0,
        dividend: double.tryParse(_dividendCtrl.text) ?? 0,
        shares: int.tryParse(_sharesCtrl.text) ?? 0,
        purchasePrice: double.tryParse(_purchasePriceCtrl.text) ?? 0,
        targetRatio: double.tryParse(_targetRatioCtrl.text) ?? 0,
        displayOrder: int.tryParse(_displayOrderCtrl.text) ?? 99,
      );

      final actions = ref.read(stockActionsProvider);
      if (_isEditing) {
        await actions.update(stock);
      } else {
        await actions.add(stock);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? '${stock.name}を更新しました' : '${stock.name}を追加しました'),
            backgroundColor: AppColors.positive,
          ),
        );
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存に失敗しました: $e'),
            backgroundColor: AppColors.negative,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '銘柄を編集' : '銘柄を追加'),
        leading: IconButton(
          onPressed: () => context.go('/dashboard'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.teal,
                ),
              ),
            )
          else
            TextButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text('保存'),
              style: TextButton.styleFrom(foregroundColor: AppColors.teal),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ========== 基本情報 ==========
                _buildSectionHeader('基本情報', Icons.info_outline_rounded),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildField(
                        controller: _codeCtrl,
                        label: '証券コード *',
                        hint: '例: 7203',
                        enabled: !_isEditing, // 編集時はコード変更不可
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return '必須項目です';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 4,
                      child: _buildField(
                        controller: _nameCtrl,
                        label: '会社名 *',
                        hint: '例: トヨタ自動車',
                        validator: (v) =>
                            (v == null || v.isEmpty) ? '必須項目です' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ========== 株価・配当 ==========
                _buildSectionHeader('株価・配当情報', Icons.candlestick_chart_rounded),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.teal.withOpacity(0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.update_rounded, color: AppColors.teal, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '株価はPythonスクリプトが毎日15:30以降に自動更新します。初期値として入力してください。',
                          style: TextStyle(color: AppColors.teal, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        controller: _priceCtrl,
                        label: '現在株価（円）',
                        hint: '例: 3500',
                        keyboardType: TextInputType.number,
                        prefix: '¥',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildField(
                        controller: _dividendCtrl,
                        label: '年間配当金（円/株）',
                        hint: '例: 120',
                        keyboardType: TextInputType.number,
                        prefix: '¥',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ========== 保有情報 ==========
                _buildSectionHeader('保有情報', Icons.inventory_2_outlined),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        controller: _sharesCtrl,
                        label: '保有株数（株）*',
                        hint: '例: 100',
                        keyboardType: TextInputType.number,
                        suffix: '株',
                        validator: (v) =>
                            (v == null || v.isEmpty) ? '必須項目です' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildField(
                        controller: _purchasePriceCtrl,
                        label: '平均買付単価（円）',
                        hint: '例: 3200',
                        keyboardType: TextInputType.number,
                        prefix: '¥',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ========== 比率設定 ==========
                _buildSectionHeader('リバランス設定', Icons.balance_rounded),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildField(
                        controller: _targetRatioCtrl,
                        label: '理想比率（%）*',
                        hint: '例: 15.0',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        suffix: '%',
                        validator: (v) {
                          if (v == null || v.isEmpty) return '必須項目です';
                          final d = double.tryParse(v);
                          if (d == null || d < 0 || d > 100) {
                            return '0〜100の数値を入力してください';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _buildField(
                        controller: _displayOrderCtrl,
                        label: '表示順',
                        hint: '例: 1',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // 保存ボタン
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _save,
                    icon: const Icon(Icons.save_rounded),
                    label: Text(_isEditing ? '更新する' : '追加する'),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.teal, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    String? prefix,
    String? suffix,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled,
      style: TextStyle(
        color: enabled ? AppColors.textPrimary : AppColors.textMuted,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefix != null ? '$prefix ' : null,
        prefixStyle: const TextStyle(color: AppColors.teal),
        suffixText: suffix,
        suffixStyle: const TextStyle(color: AppColors.textSecondary),
      ),
      validator: validator,
    );
  }
}
