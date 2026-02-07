import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:hive/hive.dart';

class InAppPurchaseService {
  static final InAppPurchaseService _instance =
      InAppPurchaseService._internal();
  factory InAppPurchaseService() => _instance;
  InAppPurchaseService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  late Box _settingsBox;

  static const String MONTHLY_SUBSCRIPTION = 'premium_monthly';
  static const String YEARLY_SUBSCRIPTION = 'premium_yearly';

  StreamSubscription<List<PurchaseDetails>>? _subscription;

  Future<void> initialize() async {
    _settingsBox = Hive.box('settingsBox');

    final available = await _iap.isAvailable();
    if (!available) {
      print('❌ IAP not available');
      return;
    }

    _subscription = _iap.purchaseStream.listen(
      _listenToPurchases,
      onError: (e) => print('❌ Purchase stream error: $e'),
    );

    await restorePurchases();
    print('✅ IAP initialized');
  }

  // Ürünleri getir
  Future<List<ProductDetails>> getProducts() async {
    final response = await _iap.queryProductDetails({
      MONTHLY_SUBSCRIPTION,
      YEARLY_SUBSCRIPTION,
    });

    if (response.error != null) {
      print('❌ Product error: ${response.error}');
      return [];
    }

    return response.productDetails;
  }

  // Satın alma
  Future<void> buy(String productId) async {
    final products = await getProducts();
    final product =
        products.firstWhere((p) => p.id == productId, orElse: () {
      throw Exception('Product not found: $productId');
    });

    final param = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> buyMonthly() => buy(MONTHLY_SUBSCRIPTION);
  Future<void> buyYearly() => buy(YEARLY_SUBSCRIPTION);

  // Satın alma dinleyici
  void _listenToPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        await _grantPremium(purchase);
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  Future<void> _grantPremium(PurchaseDetails purchase) async {
    await _settingsBox.put('isPremium', true);
    await _settingsBox.put('premiumProductId', purchase.productID);
    print('✅ Premium active: ${purchase.productID}');
  }

  // Restore
  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  // Premium kontrol
  bool isPremium() {
    return _settingsBox.get('isPremium', defaultValue: false);
  }

  String? premiumType() {
    return _settingsBox.get('premiumProductId');
  }

  void dispose() {
    _subscription?.cancel();
  }
}
