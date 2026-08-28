import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:challenge_edu_app/core/api/api_client.dart';
import 'package:challenge_edu_app/core/models/api_models.dart';
import 'package:challenge_edu_app/core/theme/app_theme.dart';
import 'package:challenge_edu_app/features/packages/providers/package_provider.dart';
import 'package:challenge_edu_app/features/packages/screens/packages_screen.dart';
import 'package:challenge_edu_app/features/packages/services/iap_service.dart';

void main() {
  group('Commercial Question Packages Full Flow Test', () {
    late _MockApiClient mockApiClient;
    late _MockIapService mockIapService;

    setUp(() {
      mockApiClient = _MockApiClient();
      mockIapService = _MockIapService();
    });

    tearDown(() {
      mockIapService.dispose();
    });

    testWidgets('Full End-to-End Flow: Browse -> Inspect Details -> Buy -> Verify -> Unlock -> Restore',
        (tester) async {
      tester.view.physicalSize = const Size(420, 840);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            packageProvider.overrideWith(
              (ref) => PackageNotifier(mockApiClient, mockIapService),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            locale: const Locale('ar'),
            home: const Directionality(
              textDirection: TextDirection.rtl,
              child: PackagesScreen(),
            ),
          ),
        ),
      );

      // 1. Initial Load & Presentation
      await tester.pumpAndSettle();

      // Verify that the commercial package is displayed as locked
      expect(find.text('بنك أسئلة الرياضيات الشامل'), findsOneWidget);
      expect(find.text('مقفلة'), findsOneWidget);
      expect(find.text('استعراض التفاصيل'), findsOneWidget);

      // 2. Inspect Details in Bottom Sheet
      await tester.tap(find.text('استعراض التفاصيل'));
      await tester.pumpAndSettle();

      // Verify chapters, lessons, price and buy button in details sheet
      expect(find.text('الجبر الخطي، الهندسة الفضائية'), findsOneWidget);
      expect(find.text('المصفوفات، المتجهات'), findsOneWidget);
      expect(find.text('29.99 ر.س'), findsOneWidget);
      expect(find.text('شراء الحزمة'), findsOneWidget);

      // 3. Initiate Purchase
      await tester.ensureVisible(find.text('شراء الحزمة'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('شراء الحزمة'));
      await tester.pump();

      // Verify that buyPackage was called with the target package
      expect(mockIapService.boughtPackageId, equals(201));

      // 4. Simulate In-App Purchase Verification Stream from Store
      final purchaseDetails = _FakePurchaseDetails(
        productID: 'com.edu.math.bundle.android',
        purchaseID: 'tx_test_9988',
        status: PurchaseStatus.purchased,
      );

      mockIapService.emitPurchase([purchaseDetails]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Verify success notification and updated ownership status
      expect(find.text('تم تفعيل الحزمة بنجاح.'), findsOneWidget);
      expect(find.text('مشتراة'), findsWidgets);

      // Clear previous SnackBar and dismiss bottom sheet
      ScaffoldMessenger.of(tester.element(find.byType(PackagesScreen))).hideCurrentSnackBar();
      Navigator.of(tester.element(find.text('29.99 ر.س'))).pop();
      await tester.pumpAndSettle();

      // 5. Restore Purchases Flow
      await tester.tap(find.byIcon(Icons.restore_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(mockIapService.restoreCalled, isTrue);
      expect(find.text('تم طلب استعادة المشتريات.'), findsOneWidget);
    });
  });
}

class _MockApiClient extends ApiClient {
  List<Map<String, dynamic>> packagesData = [
    {
      'id': 201,
      'title': 'بنك أسئلة الرياضيات الشامل',
      'description': 'باقة متميزة تحتوي على نماذج أسئلة وزارية وتفاعلية',
      'grade': {
        'id': 1,
        'name': 'الثاني الثانوي',
        'sort_order': 1,
        'is_active': true,
      },
      'subject': {
        'id': 10,
        'grade_id': 1,
        'name': 'رياضيات',
      },
      'chapters': [
        {'id': 1, 'subject_id': 10, 'name': 'الجبر الخطي', 'sort_order': 1},
        {'id': 2, 'subject_id': 10, 'name': 'الهندسة الفضائية', 'sort_order': 2},
      ],
      'lessons': [
        {'id': 1, 'chapter_id': 1, 'name': 'المصفوفات', 'sort_order': 1},
        {'id': 2, 'chapter_id': 2, 'name': 'المتجهات', 'sort_order': 1},
      ],
      'is_free': false,
      'price': '29.99',
      'platform_product_id': 'com.edu.math.bundle',
      'android_product_id': 'com.edu.math.bundle.android',
      'ios_product_id': 'com.edu.math.bundle.ios',
      'purchase_type': 'non_consumable',
      'is_active': true,
      'questions_count': 60,
      'is_owned': false,
    },
  ];

  @override
  Future<List<dynamic>> getPackages() async => packagesData;

  @override
  Future<Map<String, dynamic>> verifyPurchase(Map<String, dynamic> data) async {
    packagesData[0]['is_owned'] = true;
    return {
      'purchase': {
        'id': 1,
        'status': 'verified',
      },
      'owned_packages': [
        Map<String, dynamic>.from(packagesData[0]),
      ],
    };
  }

  @override
  Future<Map<String, dynamic>> restorePurchases(List<Map<String, dynamic>> items) async {
    return {
      'message': 'تم استعادة المشتريات بنجاح.',
      'owned_packages': [
        Map<String, dynamic>.from(packagesData[0]),
      ],
    };
  }
}

class _MockIapService implements IapService {
  final StreamController<List<PurchaseDetails>> _controller =
      StreamController<List<PurchaseDetails>>.broadcast();

  int? boughtPackageId;
  bool restoreCalled = false;

  @override
  String get store => 'android';

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<ProductDetails> loadProduct(String productId) async {
    throw UnimplementedError();
  }

  @override
  Stream<List<PurchaseDetails>> get purchaseUpdates => _controller.stream;

  @override
  Future<void> buyPackage(QuestionPackage package) async {
    boughtPackageId = package.id;
  }

  @override
  Future<void> restorePurchases() async {
    restoreCalled = true;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {}

  @override
  Map<String, dynamic> payloadForPurchase({
    required QuestionPackage package,
    required PurchaseDetails purchase,
  }) {
    return {
      'question_package_id': package.id,
      'store': 'android',
      'product_id': purchase.productID,
      'transaction_id': purchase.purchaseID ?? 'tx_123',
      'purchase_token': 'test_token',
    };
  }

  void emitPurchase(List<PurchaseDetails> purchases) {
    _controller.add(purchases);
  }

  void dispose() {
    _controller.close();
  }
}

class _FakePurchaseDetails extends PurchaseDetails {
  _FakePurchaseDetails({
    required super.productID,
    required super.purchaseID,
    required super.status,
  }) : super(
          verificationData: PurchaseVerificationData(
            localVerificationData: purchaseID ?? '',
            serverVerificationData: 'test_token_123',
            source: 'store',
          ),
          transactionDate: DateTime.now().millisecondsSinceEpoch.toString(),
        );
}
