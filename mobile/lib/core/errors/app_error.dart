import 'package:dio/dio.dart';

class UserFacingException implements Exception {
  final String message;

  const UserFacingException(this.message);
}

class AppError {
  static const String genericMessage =
      'حدث خطأ غير متوقع. يرجى المحاولة مجدداً.';

  static String message(
    Object error, {
    String fallback = genericMessage,
  }) {
    if (error is UserFacingException) {
      return error.message;
    }

    if (error is DioException) {
      return _dioMessage(error, fallback);
    }

    return fallback;
  }

  static String _dioMessage(DioException error, String fallback) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'استغرق الاتصال وقتاً أطول من المتوقع. حاول مجدداً.';
      case DioExceptionType.connectionError:
        return 'تعذر الاتصال بالخادم. تحقق من اتصال الإنترنت.';
      case DioExceptionType.badCertificate:
        return 'تعذر إنشاء اتصال آمن بالخادم. حاول مجدداً لاحقاً.';
      case DioExceptionType.cancel:
        return 'تم إلغاء العملية.';
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
      default:
        break;
    }

    final statusCode = error.response?.statusCode;
    if (statusCode == null) {
      return fallback;
    }

    if (statusCode >= 500) {
      return 'الخدمة غير متاحة حالياً. يرجى المحاولة لاحقاً.';
    }

    if (statusCode == 401 || statusCode == 419) {
      return 'انتهت جلستك. يرجى تسجيل الدخول مجدداً.';
    }

    final responseMessage = _safeResponseMessage(error.response?.data);
    if (responseMessage != null) {
      return responseMessage;
    }

    return switch (statusCode) {
      403 => 'لا تملك صلاحية لإتمام هذه العملية.',
      404 => 'لم نتمكن من العثور على البيانات المطلوبة.',
      422 => 'تعذر إتمام العملية بسبب بيانات غير صحيحة.',
      429 => 'تم إرسال طلبات كثيرة. انتظر قليلاً ثم حاول مجدداً.',
      _ => fallback,
    };
  }

  static String? _safeResponseMessage(dynamic data) {
    if (data is! Map) return null;

    final errors = data['errors'];
    if (errors is Map) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          final message = _safeArabicMessage(value.first);
          if (message != null) return message;
        }

        final message = _safeArabicMessage(value);
        if (message != null) return message;
      }
    }

    return _safeArabicMessage(data['message']);
  }

  static String? _safeArabicMessage(dynamic value) {
    if (value is! String) return null;

    final message = value.trim();
    if (message.isEmpty || !_containsArabic(message)) return null;

    const technicalTerms = [
      'Exception',
      'DioException',
      'Stack trace',
      'SQLSTATE',
      'vendor/',
      'vendor\\',
      '.php',
      '.dart',
    ];
    if (technicalTerms.any(message.contains)) return null;
    if (RegExp(r'\b[a-z][a-z0-9]*(?:_[a-z0-9]+)+\b', caseSensitive: false)
        .hasMatch(message)) {
      return null;
    }

    return message;
  }

  static bool _containsArabic(String value) =>
      RegExp(r'[\u0600-\u06FF]').hasMatch(value);
}
