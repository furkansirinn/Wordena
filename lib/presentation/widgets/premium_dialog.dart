import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../core/theme.dart';
import '../../data/in_app_purchase_service.dart';

class PremiumDialog extends StatefulWidget {
  const PremiumDialog({super.key});

  @override
  State<PremiumDialog> createState() => _PremiumDialogState();
}

class _PremiumDialogState extends State<PremiumDialog> {
  final _iapService = InAppPurchaseService();
  bool _isLoading = false;
  List<ProductDetails> _products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final products = await _iapService.getProducts();
    if (!mounted) return;
    setState(() => _products = products);
  }

  Future<void> _buy(String productId) async {
    setState(() => _isLoading = true);
    try {
      await _iapService.buy(productId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Satın alma başarısız'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthly = _products.firstWhere(
      (p) => p.id == InAppPurchaseService.MONTHLY_SUBSCRIPTION,
      orElse: () => _fakeProduct('₺29,99'),
    );

    final yearly = _products.firstWhere(
      (p) => p.id == InAppPurchaseService.YEARLY_SUBSCRIPTION,
      orElse: () => _fakeProduct('₺199,99'),
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              const SizedBox(height: 20),
              _benefits(),
              const SizedBox(height: 20),
              _plan(
                title: 'Aylık Premium',
                product: monthly,
                color: Colors.green,
                highlight: false,
                badge: 'Esnek',
                onTap: () => _buy(InAppPurchaseService.MONTHLY_SUBSCRIPTION),
              ),
              const SizedBox(height: 12),
              _plan(
                title: 'Yıllık Premium',
                product: yearly,
                color: Colors.amber,
                highlight: true,
                badge: '%42 daha ucuz',
                onTap: () => _buy(InAppPurchaseService.YEARLY_SUBSCRIPTION),
              ),
              const SizedBox(height: 16),
              _info(),
              const SizedBox(height: 12),
              _restore(),
              const SizedBox(height: 8),
              _close(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- UI PARTS ----------------

  Widget _header() => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade600],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.star, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Premium’a Yükselt',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Sınırsız öğrenme deneyimi',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _benefits() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Premium Avantajları',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            _Benefit('Sınırsız soru'),
            _Benefit('Reklamsız deneyim'),
            _Benefit('30 kategori'),
            _Benefit('İleri istatistikler'),
          ],
        ),
      );

  Widget _plan({
    required String title,
    required ProductDetails product,
    required MaterialColor color,
    required bool highlight,
    required String badge,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: highlight
              ? [color.shade100, color.shade50]
              : [Colors.grey.shade100, Colors.grey.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight ? color.shade300 : Colors.grey.shade300,
          width: highlight ? 2 : 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: color.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              Text(product.price,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color.shade700)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(badge,
                style: TextStyle(
                    fontSize: 11,
                    color: color.shade700,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isLoading ? null : onTap,
              style: FilledButton.styleFrom(backgroundColor: color),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Satın Al'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _info() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'İstediğin zaman iptal edebilirsin',
          style: TextStyle(fontSize: 12),
        ),
      );

  Widget _restore() => TextButton(
        onPressed: _iapService.restorePurchases,
        child: const Text('Önceki satın almaları geri yükle'),
      );

  Widget _close() => TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Sonra'),
      );

  ProductDetails _fakeProduct(String price) => ProductDetails(
        id: '',
        title: '',
        description: '',
        price: price,
        rawPrice: 0,
        currencyCode: 'TRY',
      );
}

class _Benefit extends StatelessWidget {
  final String text;
  const _Benefit(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            const Icon(Icons.check, size: 16, color: Colors.green),
            const SizedBox(width: 8),
            Text(text),
          ],
        ),
      );
}
