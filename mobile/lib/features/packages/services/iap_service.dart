import 'dart:io';

import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/models/api_models.dart';

class IapService {
  final InAppPurchase _iap = InAppPurchase.instance;

  Stream<List<PurchaseDetails>> get purchaseUpdates => _iap.purchaseStream;

  String get store {
    if (Platform.isIOS) return 'ios';
    return 'android';
  }

  Future<bool> isAvailable() => _iap.isAvailable();

  Future<ProductDetails> loadProduct(String productId) async {
    final response = await _iap.queryProductDetails({productId});
    if (response.error != null) {
      throw Exception(response.error!.message);
    }
    if (response.productDetails.isEmpty) {
      throw Exception('هذا المنتج غير متاح في المتجر حالياً.');
    }
    return response.productDetails.first;
  }

  Future<void> buyPackage(QuestionPackage package) async {
    final productId = package.productIdForStore(store);
    if (productId == null || productId.isEmpty) {
      throw Exception('لم يتم ضبط معرّف المنتج لهذه الحزمة.');
    }

    final available = await isAvailable();
    if (!available) {
      throw Exception('المتجر غير متاح على هذا الجهاز.');
    }

    final product = await loadProduct(productId);
    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() => _iap.restorePurchases();

  Future<void> completePurchase(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }

  Map<String, dynamic> payloadForPurchase({
    required QuestionPackage package,
    required PurchaseDetails purchase,
  }) {
    return {
      'question_package_id': package.id,
      'store': store,
      'product_id': purchase.productID,
      'transaction_id': purchase.purchaseID ??
          purchase.verificationData.localVerificationData,
      'purchase_token': store == 'android'
          ? purchase.verificationData.serverVerificationData
          : null,
      'signed_transaction': store == 'ios'
          ? purchase.verificationData.serverVerificationData
          : null,
      'raw_payload': {
        'source': purchase.verificationData.source,
        'status': purchase.status.name,
      },
    };
  }
}
