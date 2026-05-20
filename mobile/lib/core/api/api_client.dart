import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

class ApiClient {
  static const _tokenKey = 'auth_token';

  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: _tokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          handler.next(error);
        },
      ),
    );
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<bool> hasToken() async {
    final token = await _storage.read(key: _tokenKey);
    return token != null;
  }

  // ─── Auth ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String email, String password) async {
    final resp = await _dio.post('/login', data: {
      'email': email,
      'password': password,
      'device_name': 'flutter-app',
    });
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    final resp = await _dio.post('/register', data: {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': password,
      'device_name': 'flutter-app',
    });
    return resp.data as Map<String, dynamic>;
  }

  Future<void> logout() async {
    await _dio.post('/logout');
    await clearToken();
  }

  Future<Map<String, dynamic>> me() async {
    final resp = await _dio.get('/me');
    return resp.data as Map<String, dynamic>;
  }

  // ─── Educational hierarchy ───────────────────────────────────────────────

  Future<List<dynamic>> getGrades() async {
    final resp = await _dio.get('/grades');
    return resp.data as List<dynamic>;
  }

  Future<List<dynamic>> getSubjects(int gradeId) async {
    final resp = await _dio.get('/grades/$gradeId/subjects');
    return resp.data as List<dynamic>;
  }

  Future<List<dynamic>> getSubjectParts(
    int subjectId, {
    bool includeEmpty = false,
  }) async {
    final resp = await _dio.get('/subjects/$subjectId/parts',
        queryParameters: {if (includeEmpty) 'include_empty': true});
    return resp.data as List<dynamic>;
  }

  Future<List<dynamic>> getChapters(
    int subjectId, {
    int? subjectPartId,
  }) async {
    final resp = await _dio.get('/chapters', queryParameters: {
      'subject_id': subjectId,
      if (subjectPartId != null) 'subject_part_id': subjectPartId,
    });
    return resp.data as List<dynamic>;
  }

  Future<List<dynamic>> getLessons(List<int> chapterIds) async {
    final resp = await _dio.get('/lessons', queryParameters: {
      'chapter_ids[]': chapterIds,
    });
    return resp.data as List<dynamic>;
  }

  Future<List<dynamic>> getQuestions(List<int> lessonIds) async {
    final resp = await _dio.get('/questions', queryParameters: {
      'lesson_ids[]': lessonIds,
    });
    return resp.data as List<dynamic>;
  }

  // ─── Challenge ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createChallenge(
      Map<String, dynamic> data) async {
    final resp = await _dio.post('/challenges', data: data);
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getChallenge(int id) async {
    final resp = await _dio.get('/challenges/$id');
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> addGroup(
      int challengeId, String name, int sortOrder) async {
    final resp = await _dio.post('/challenges/$challengeId/groups', data: {
      'name': name,
      'sort_order': sortOrder,
    });
    return resp.data as Map<String, dynamic>;
  }

  Future<int> rollDice(int challengeId) async {
    final resp = await _dio.post('/challenges/$challengeId/roll-dice');
    return (resp.data as Map<String, dynamic>)['dice_value'] as int;
  }

  Future<Map<String, dynamic>> markCorrect(
    int challengeId,
    int challengeQuestionId,
    int groupId,
    int diceValue,
  ) async {
    final resp = await _dio.post(
      '/challenges/$challengeId/questions/$challengeQuestionId/mark-correct',
      data: {'group_id': groupId, 'dice_value': diceValue},
    );
    return resp.data as Map<String, dynamic>;
  }

  Future<void> markWrong(
    int challengeId,
    int challengeQuestionId,
    int groupId,
    int diceValue,
  ) async {
    await _dio.post(
      '/challenges/$challengeId/questions/$challengeQuestionId/mark-wrong',
      data: {'group_id': groupId, 'dice_value': diceValue},
    );
  }

  Future<Map<String, dynamic>> manualScore(
    int challengeId,
    int groupId,
    String type,
    int? points,
    int? score,
    String? note,
  ) async {
    final resp = await _dio.post(
      '/challenges/$challengeId/groups/$groupId/manual-score',
      data: {
        'type': type,
        if (points != null) 'points': points,
        if (score != null) 'score': score,
        if (note != null) 'note': note,
      },
    );
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> completeChallenge(int challengeId) async {
    final resp = await _dio.post('/challenges/$challengeId/complete');
    return resp.data as Map<String, dynamic>;
  }

  // ─── Commercial packages and purchases ───────────────────────────────────

  Future<List<dynamic>> getPackages() async {
    final resp = await _dio.get('/packages');
    return resp.data as List<dynamic>;
  }

  Future<List<dynamic>> getOwnedPackages() async {
    final resp = await _dio.get('/packages/owned');
    return resp.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> verifyPurchase(
    Map<String, dynamic> payload,
  ) async {
    final resp = await _dio.post('/purchases/verify', data: payload);
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> restorePurchases(
    List<Map<String, dynamic>> purchases,
  ) async {
    final resp = await _dio.post('/purchases/restore', data: {
      'purchases': purchases,
    });
    return resp.data as Map<String, dynamic>;
  }

  // ─── Teacher content management ───────────────────────────────────────────

  Future<List<dynamic>> getTeacherGrades() async {
    final resp = await _dio.get('/teacher/grades');
    return resp.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createTeacherGrade(
      Map<String, dynamic> data) async {
    final resp = await _dio.post('/teacher/grades', data: data);
    return resp.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getTeacherSubjects({int? gradeId}) async {
    final resp = await _dio.get('/teacher/subjects',
        queryParameters: {if (gradeId != null) 'grade_id': gradeId});
    return resp.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createTeacherSubject(
      Map<String, dynamic> data) async {
    final resp = await _dio.post('/teacher/subjects', data: data);
    return resp.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getTeacherChapters({
    int? subjectId,
    int? subjectPartId,
  }) async {
    final resp = await _dio.get('/teacher/chapters', queryParameters: {
      if (subjectId != null) 'subject_id': subjectId,
      if (subjectPartId != null) 'subject_part_id': subjectPartId,
    });
    return resp.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createTeacherChapter(
      Map<String, dynamic> data) async {
    final resp = await _dio.post('/teacher/chapters', data: data);
    return resp.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getTeacherLessons({int? chapterId}) async {
    final resp = await _dio.get('/teacher/lessons',
        queryParameters: {if (chapterId != null) 'chapter_id': chapterId});
    return resp.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createTeacherLesson(
      Map<String, dynamic> data) async {
    final resp = await _dio.post('/teacher/lessons', data: data);
    return resp.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getTeacherQuestions({int? lessonId}) async {
    final resp = await _dio.get('/teacher/questions',
        queryParameters: {if (lessonId != null) 'lesson_id': lessonId});
    return resp.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createTeacherQuestion(
      Map<String, dynamic> data) async {
    final resp = await _dio.post('/teacher/questions', data: data);
    return resp.data as Map<String, dynamic>;
  }
}
