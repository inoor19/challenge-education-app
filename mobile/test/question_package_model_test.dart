import 'package:challenge_edu_app/core/models/api_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('question package parses multiple chapters and lessons', () {
    final package = QuestionPackage.fromJson({
      'id': 1,
      'title': 'حزمة متعددة',
      'chapters': [
        {
          'id': 10,
          'subject_id': 3,
          'name': 'الفصل الأول',
          'sort_order': 1,
        },
        {
          'id': 11,
          'subject_id': 3,
          'name': 'الفصل الثاني',
          'sort_order': 2,
        },
      ],
      'lessons': [
        {
          'id': 20,
          'chapter_id': 10,
          'name': 'الدرس الأول',
          'sort_order': 1,
        },
        {
          'id': 21,
          'chapter_id': 11,
          'name': 'الدرس الثاني',
          'sort_order': 1,
        },
      ],
      'is_free': true,
      'purchase_type': 'non_consumable',
      'is_active': true,
      'questions_count': 8,
    });

    expect(package.chapters.map((chapter) => chapter.name),
        ['الفصل الأول', 'الفصل الثاني']);
    expect(package.lessons.map((lesson) => lesson.name),
        ['الدرس الأول', 'الدرس الثاني']);
  });

  test('question package falls back to legacy chapter and lesson fields', () {
    final package = QuestionPackage.fromJson({
      'id': 1,
      'title': 'حزمة قديمة',
      'chapter': {
        'id': 10,
        'subject_id': 3,
        'name': 'الفصل القديم',
        'sort_order': 1,
      },
      'lesson': {
        'id': 20,
        'chapter_id': 10,
        'name': 'الدرس القديم',
        'sort_order': 1,
      },
      'is_free': true,
      'purchase_type': 'non_consumable',
      'is_active': true,
      'questions_count': 4,
    });

    expect(package.chapters.single.name, 'الفصل القديم');
    expect(package.lessons.single.name, 'الدرس القديم');
  });
}
