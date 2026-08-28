import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/models/api_models.dart';

class IapService {
  InAppPurchase get _iap => InAppPurchase.instance;

  Stream<List<PurchaseDetails>> get purchaseUpdates {
    if (kIsWeb) {
      return const Stream.empty();
    }
    try {
      return _iap.purchaseStream;
    } catch (_) {
      return const Stream.empty();
    }
  }

  String get store {
    if (kIsWeb) return 'android';
    try {
      if (Platform.isIOS) return 'ios';
    } catch (_) {}
    return 'android';
  }

  Future<bool> isAvailable() async {
    if (kIsWeb) return false;
    try {
      return await _iap.isAvailable();
    } catch (_) {
      return false;
    }
  }

  Future<ProductDetails> loadProduct(String productId) async {
    if (kIsWeb) {
      throw const UserFacingException(
        'الشراء عبر المتجر متاح من خلال تطبيق الجوال والتابلت (أندرويد أو iOS).',
      );
    }
    final response = await _iap.queryProductDetails({productId});
    if (response.error != null) {
      throw const UserFacingException(
        'تعذر التواصل مع المتجر حالياً. حاول مجدداً لاحقاً.',
      );
    }
    if (response.productDetails.isEmpty) {
      throw const UserFacingException('هذا المنتج غير متاح في المتجر حالياً.');
    }
    return response.productDetails.first;
  }

  Future<void> buyPackage(QuestionPackage package) async {
    if (kIsWeb) {
      throw const UserFacingException(
        'الشراء عبر المتجر متاح من خلال تطبيق الجوال والتابلت (أندرويد أو iOS).',
      );
    }
    final productId = package.productIdForStore(store);
    if (productId == null || productId.isEmpty) {
      throw const UserFacingException(
        'هذه الحزمة غير جاهزة للشراء حالياً.',
      );
    }

    final available = await isAvailable();
    if (!available) {
      throw const UserFacingException('المتجر غير متاح على هذا الجهاز.');
    }

    final product = await loadProduct(productId);
    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() async {
    if (kIsWeb) {
      return;
    }
    try {
      await _iap.restorePurchases();
    } catch (_) {}
  }

  Future<void> completePurchase(PurchaseDetails purchase) async {
    if (kIsWeb) return;
    try {
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    } catch (_) {}
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
