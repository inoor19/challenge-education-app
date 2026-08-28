import 'dart:async';

import 'package:challenge_edu_app/core/api/api_client.dart';
import 'package:challenge_edu_app/core/models/api_models.dart';
import 'package:challenge_edu_app/core/theme/app_theme.dart';
import 'package:challenge_edu_app/features/packages/providers/package_provider.dart';
import 'package:challenge_edu_app/features/packages/screens/packages_screen.dart';
import 'package:challenge_edu_app/features/packages/services/iap_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

void main() {
  testWidgets('package details display all chapter and lesson names',
      (tester) async {
    tester.view.physicalSize = const Size(400, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          packageProvider.overrideWith(
            (ref) => PackageNotifier(_PackageApiClient(), _IapService()),
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

    await tester.pumpAndSettle();
    await tester.tap(find.text('استعراض التفاصيل'));
    await tester.pumpAndSettle();

    expect(find.text('الجمع والطرح، الهندسة'), findsOneWidget);
    expect(find.text('جمع الأعداد، الأشكال الهندسية'), findsOneWidget);
  });
}

class _PackageApiClient extends ApiClient {
  @override
  Future<List<dynamic>> getPackages() async => [
        {
          'id': 101,
          'title': 'حزمة رياضيات متعددة',
          'grade': {
            'id': 1,
            'name': 'الأول الابتدائي',
            'sort_order': 1,
            'is_active': true,
          },
          'subject': {
            'id': 10,
            'grade_id': 1,
            'name': 'رياضيات',
          },
          'chapter': {
            'id': 20,
            'subject_id': 10,
            'name': 'الجمع والطرح',
            'sort_order': 1,
          },
          'lesson': {
            'id': 30,
            'chapter_id': 20,
            'name': 'جمع الأعداد',
            'sort_order': 1,
          },
          'chapters': [
            {
              'id': 20,
              'subject_id': 10,
              'name': 'الجمع والطرح',
              'sort_order': 1,
            },
            {
              'id': 21,
              'subject_id': 10,
              'name': 'الهندسة',
              'sort_order': 2,
            },
          ],
          'lessons': [
            {
              'id': 30,
              'chapter_id': 20,
              'name': 'جمع الأعداد',
              'sort_order': 1,
            },
            {
              'id': 31,
              'chapter_id': 21,
              'name': 'الأشكال الهندسية',
              'sort_order': 1,
            },
          ],
          'is_free': true,
          'purchase_type': 'non_consumable',
          'is_active': true,
          'questions_count': 12,
          'is_owned': true,
        },
      ];
}

class _IapService extends IapService {
  final StreamController<List<PurchaseDetails>> _controller =
      StreamController<List<PurchaseDetails>>.broadcast();

  @override
  Stream<List<PurchaseDetails>> get purchaseUpdates => _controller.stream;

  @override
  Future<void> buyPackage(QuestionPackage package) async {}

  @override
  Future<void> restorePurchases() async {}
}
