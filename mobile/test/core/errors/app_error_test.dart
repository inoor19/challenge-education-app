import 'package:challenge_edu_app/core/errors/app_error.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppError', () {
    test('returns friendly connection and timeout messages', () {
      expect(
        AppError.message(_dio(type: DioExceptionType.connectionError)),
        'تعذر الاتصال بالخادم. تحقق من اتصال الإنترنت.',
      );
      expect(
        AppError.message(_dio(type: DioExceptionType.receiveTimeout)),
        'استغرق الاتصال وقتاً أطول من المتوقع. حاول مجدداً.',
      );
    });

    test('maps common response status codes', () {
      expect(
        AppError.message(_dio(statusCode: 401)),
        'انتهت جلستك. يرجى تسجيل الدخول مجدداً.',
      );
      expect(
        AppError.message(_dio(statusCode: 403)),
        'لا تملك صلاحية لإتمام هذه العملية.',
      );
      expect(
        AppError.message(_dio(statusCode: 404)),
        'لم نتمكن من العثور على البيانات المطلوبة.',
      );
      expect(
        AppError.message(_dio(statusCode: 429)),
        'تم إرسال طلبات كثيرة. انتظر قليلاً ثم حاول مجدداً.',
      );
    });

    test('uses safe Arabic validation and API messages', () {
      expect(
        AppError.message(
          _dio(
            statusCode: 422,
            data: {
              'message': 'بيانات غير صحيحة.',
              'errors': {
                'subject_part_id': ['جزء المادة مطلوب.'],
              },
            },
          ),
        ),
        'جزء المادة مطلوب.',
      );
      expect(
        AppError.message(
          _dio(
            statusCode: 403,
            data: {'message': 'يمكنك تعديل المحتوى الذي أنشأته فقط.'},
          ),
        ),
        'يمكنك تعديل المحتوى الذي أنشأته فقط.',
      );
    });

    test('never exposes server or exception details', () {
      expect(
        AppError.message(
          _dio(
            statusCode: 500,
            data: {'message': 'SQLSTATE database connection failed'},
          ),
        ),
        'الخدمة غير متاحة حالياً. يرجى المحاولة لاحقاً.',
      );
      expect(
        AppError.message(
          Exception('DioException: SocketException developer details'),
          fallback: 'تعذر حفظ التعديل.',
        ),
        'تعذر حفظ التعديل.',
      );
      expect(
        AppError.message(
          _dio(
            statusCode: 422,
            data: {'message': 'حقل subject_part_id غير صحيح.'},
          ),
          fallback: 'تعذر حفظ التعديل.',
        ),
        'تعذر إتمام العملية بسبب بيانات غير صحيحة.',
      );
    });

    test('uses explicitly safe local messages', () {
      expect(
        AppError.message(
          const UserFacingException('المتجر غير متاح على هذا الجهاز.'),
        ),
        'المتجر غير متاح على هذا الجهاز.',
      );
    });
  });
}

DioException _dio({
  DioExceptionType type = DioExceptionType.badResponse,
  int? statusCode,
  dynamic data,
}) {
  final request = RequestOptions(path: '/test');
  return DioException(
    requestOptions: request,
    type: type,
    response: statusCode == null
        ? null
        : Response<dynamic>(
            requestOptions: request,
            statusCode: statusCode,
            data: data,
          ),
  );
}
