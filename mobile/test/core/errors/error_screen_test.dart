import 'package:challenge_edu_app/core/api/api_client.dart';
import 'package:challenge_edu_app/core/models/api_models.dart';
import 'package:challenge_edu_app/core/providers/api_provider.dart';
import 'package:challenge_edu_app/features/setup/providers/setup_provider.dart';
import 'package:challenge_edu_app/features/setup/screens/select_subject_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('data screens do not expose exception details', (tester) async {
    final setup = SetupNotifier()
      ..selectGrade(
        const Grade(id: 1, name: 'الأول', sortOrder: 1, isActive: true),
      );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(_FailingApiClient()),
          setupProvider.overrideWith((ref) => setup),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: SelectSubjectScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('تعذر تحميل المواد. حاول مجدداً.'), findsOneWidget);
    expect(find.textContaining('Exception'), findsNothing);
    expect(find.textContaining('developer details'), findsNothing);
  });
}

class _FailingApiClient extends ApiClient {
  @override
  Future<List<dynamic>> getSubjects(int gradeId) {
    throw Exception('developer details');
  }
}
