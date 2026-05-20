import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/api/api_client.dart';
import '../../../core/models/api_models.dart';
import '../../../core/providers/api_provider.dart';
import '../services/iap_service.dart';

class PackageState {
  final List<QuestionPackage> packages;
  final bool isLoading;
  final bool isPurchasing;
  final String? error;
  final String? successMessage;

  const PackageState({
    this.packages = const [],
    this.isLoading = false,
    this.isPurchasing = false,
    this.error,
    this.successMessage,
  });

  PackageState copyWith({
    List<QuestionPackage>? packages,
    bool? isLoading,
    bool? isPurchasing,
    String? error,
    String? successMessage,
    bool clearMessages = false,
  }) =>
      PackageState(
        packages: packages ?? this.packages,
        isLoading: isLoading ?? this.isLoading,
        isPurchasing: isPurchasing ?? this.isPurchasing,
        error: clearMessages ? null : error,
        successMessage: clearMessages ? null : successMessage,
      );
}

class PackageNotifier extends StateNotifier<PackageState> {
  final ApiClient _api;
  final IapService _iap;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  final Map<String, QuestionPackage> _packagesByProductId = {};

  PackageNotifier(this._api, this._iap) : super(const PackageState()) {
    _purchaseSub = _iap.purchaseUpdates.listen(_handlePurchaseUpdates);
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    super.dispose();
  }

  Future<void> loadPackages() async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final data = await _api.getPackages();
      final packages = data.map((j) => QuestionPackage.fromJson(j)).toList();
      _indexProducts(packages);
      state = state.copyWith(packages: packages, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'تعذر تحميل الحزم. تحقق من الاتصال.',
      );
    }
  }

  Future<void> buy(QuestionPackage package) async {
    if (package.isOwned || package.isFree) return;
    state = state.copyWith(isPurchasing: true, clearMessages: true);
    try {
      await _iap.buyPackage(package);
    } catch (e) {
      state = state.copyWith(isPurchasing: false, error: e.toString());
    }
  }

  Future<void> restore() async {
    state = state.copyWith(isPurchasing: true, clearMessages: true);
    try {
      await _iap.restorePurchases();
      final restored = await _api.restorePurchases([]);
      final owned = (restored['owned_packages'] as List? ?? [])
          .map((j) => QuestionPackage.fromJson(j))
          .toList();
      _mergeOwned(owned);
      state = state.copyWith(
        isPurchasing: false,
        successMessage: 'تم طلب استعادة المشتريات.',
      );
    } catch (e) {
      state = state.copyWith(isPurchasing: false, error: e.toString());
    }
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      final package = _packagesByProductId[purchase.productID];
      if (package == null) continue;

      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        try {
          final result = await _api.verifyPurchase(
            _iap.payloadForPurchase(package: package, purchase: purchase),
          );
          final owned = (result['owned_packages'] as List? ?? [])
              .map((j) => QuestionPackage.fromJson(j))
              .toList();
          _mergeOwned(owned);
          state = state.copyWith(
            isPurchasing: false,
            successMessage: 'تم تفعيل الحزمة بنجاح.',
          );
        } catch (e) {
          state = state.copyWith(
            isPurchasing: false,
            error: 'تعذر التحقق من الشراء على الخادم.',
          );
        }
      } else if (purchase.status == PurchaseStatus.error) {
        state = state.copyWith(
          isPurchasing: false,
          error: purchase.error?.message ?? 'فشلت عملية الشراء.',
        );
      } else if (purchase.status == PurchaseStatus.canceled) {
        state = state.copyWith(isPurchasing: false);
      }

      await _iap.completePurchase(purchase);
    }
  }

  void _indexProducts(List<QuestionPackage> packages) {
    _packagesByProductId.clear();
    for (final package in packages) {
      for (final store in ['android', 'ios']) {
        final productId = package.productIdForStore(store);
        if (productId != null && productId.isNotEmpty) {
          _packagesByProductId[productId] = package;
        }
      }
    }
  }

  void _mergeOwned(List<QuestionPackage> ownedPackages) {
    final ownedIds = ownedPackages.map((p) => p.id).toSet();
    final packages = state.packages
        .map((package) => ownedIds.contains(package.id)
            ? QuestionPackage(
                id: package.id,
                title: package.title,
                description: package.description,
                grade: package.grade,
                subject: package.subject,
                chapter: package.chapter,
                lesson: package.lesson,
                isFree: package.isFree,
                price: package.price,
                platformProductId: package.platformProductId,
                androidProductId: package.androidProductId,
                iosProductId: package.iosProductId,
                purchaseType: package.purchaseType,
                isActive: package.isActive,
                questionsCount: package.questionsCount,
                isOwned: true,
              )
            : package)
        .toList();
    _indexProducts(packages);
    state = state.copyWith(packages: packages);
  }
}

final iapServiceProvider = Provider<IapService>((ref) => IapService());

final packageProvider =
    StateNotifierProvider<PackageNotifier, PackageState>((ref) {
  return PackageNotifier(
    ref.watch(apiClientProvider),
    ref.watch(iapServiceProvider),
  );
});
