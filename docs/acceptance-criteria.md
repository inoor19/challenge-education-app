# معايير القبول — ساحة التنافس

> آخر تحديث: مايو 2026 — تم التحقق الفعلي من التنفيذ وتشغيل التهجيرات والبذر والاختبار عبر API.

---

## 1. البنية والإعداد

| المعيار | الحالة | ملاحظة |
|---|---|---|
| مستودع Monorepo: `backend/` + `mobile/` + `docs/` | ✅ | |
| `backend/composer.json` يتضمن laravel/framework, laravel/sanctum, filament/filament, maatwebsite/excel | ✅ | تم التحقق |
| `backend/artisan` موجود | ✅ | تم إنشاؤه عبر composer create-project |
| `backend/.env.example` موجود | ✅ | |
| `mobile/pubspec.yaml` صالح | ✅ | flutter pub get نجح |
| `mobile/lib/main.dart` موجود | ✅ | |
| جميع ملفات docs/*.md موجودة | ✅ | 5 ملفات |

---

## 2. التسلسل الهرمي للمحتوى التعليمي

| المعيار | الحالة |
|---|---|
| الصف الدراسي ← المادة ← الفصل ← الدرس ← السؤال | ✅ |
| استخدام "الفصل" وليس "الوحدة" في كل المكونات | ✅ |
| العلاقات في النماذج (Eloquent) صحيحة | ✅ |
| التهجيرات تنشئ كل الجداول | ✅ (11 تهجير تعمل) |
| البذر يُنشئ بيانات نموذجية | ✅ |

---

## 3. لوحة الإدارة (Filament v3)

| المعيار | الحالة |
|---|---|
| AdminPanelProvider مسجل | ✅ |
| GradeResource — الصف الدراسي | ✅ |
| SubjectResource — المادة | ✅ |
| ChapterResource — الفصل | ✅ |
| LessonResource — الدرس | ✅ |
| QuestionResource — السؤال | ✅ |
| QuestionPackageResource — حزم الأسئلة | ✅ |
| UserResource — المستخدمون | ✅ |
| صفحة استيراد Excel | ✅ |
| تسميات عربية في التنقل | ✅ |
| دعم RTL | ✅ (Laravel RTL + Filament) |

---

## 4. استيراد Excel

| المعيار | الحالة |
|---|---|
| أعمدة عربية: الصف الدراسي، المادة، الفصل، الدرس، ... | ✅ |
| إنشاء الصف الدراسي تلقائياً إن لم يكن موجوداً | ✅ |
| إنشاء المادة تلقائياً | ✅ |
| إنشاء الفصل تلقائياً | ✅ |
| إنشاء الدرس تلقائياً | ✅ |
| تحويل سهل/صعب إلى easy/hard | ✅ |
| تحويل أنواع الأسئلة (اختيار من متعدد، صح أو خطأ، نصي) | ✅ |
| تقرير النتائج (created, skipped, errors) | ✅ |

---

## 5. API

| المسار | الطريقة | الحالة |
|---|---|---|
| /api/login | POST | ✅ تم الاختبار |
| /api/logout | POST | ✅ |
| /api/me | GET | ✅ |
| /api/grades | GET | ✅ تم الاختبار |
| /api/grades/{id}/subjects | GET | ✅ تم الاختبار |
| /api/subjects/{id}/chapters | GET | ✅ تم الاختبار |
| /api/lessons?chapter_ids[] | GET | ✅ تم الاختبار |
| /api/questions?lesson_ids[] | GET | ✅ تم الاختبار |
| /api/challenges | POST | ✅ تم الاختبار |
| /api/challenges/{id} | GET | ✅ تم الاختبار |
| /api/challenges/{id}/groups | POST | ✅ تم الاختبار |
| /api/challenges/{id}/roll-dice | POST | ✅ تم الاختبار |
| /api/challenges/{id}/questions/{q}/mark-correct | POST | ✅ تم الاختبار |
| /api/challenges/{id}/questions/{q}/mark-wrong | POST | ✅ تم الاختبار |
| /api/challenges/{id}/groups/{g}/manual-score | POST | ✅ |
| /api/challenges/{id}/complete | POST | ✅ |

---

## 6. منطق النقاط (Scoring)

| المعيار | الحالة | ملاحظة |
|---|---|---|
| قيمة النرد من 1 إلى 3 | ✅ | قابلة للتهيئة من إعدادات التطبيق |
| سؤال سهل: نقاط = قيمة النرد | ✅ اختُبر: dice=2, easy → 2 |
| سؤال صعب: نقاط = قيمة النرد × 2 | ✅ اختُبر: dice=2, hard → 4 |
| النقاط تُضاف تلقائياً عند الإجابة الصحيحة | ✅ |
| لا نقاط عند الخطأ | ✅ |
| تعديل النقاط يدوياً (إضافة/طرح) | ✅ |
| تسجيل كل تغيير في score_events | ✅ |

---

## 7. جلسة التحدي

| المعيار | الحالة |
|---|---|
| إنشاء جلسة مع grade_id, subject_id, chapter_ids, lesson_ids | ✅ |
| timer_seconds (افتراضي 60)، timer_enabled | ✅ |
| الأسئلة تُسحب من الدروس المحددة فقط | ✅ |
| ترتيب تسلسلي للأسئلة (sequence_number) | ✅ |
| تحديد الأسئلة المستخدمة (is_used) | ✅ |

---

## 8. تطبيق Flutter

| المعيار | الحالة | ملاحظة |
|---|---|---|
| Splash Screen | ✅ | |
| Login Screen | ✅ | |
| Select Grade Screen (Home) | ✅ | |
| Select Subject Screen | ✅ | |
| Select Chapters Screen (تعدد) | ✅ | |
| Select Lessons Screen (تعدد) | ✅ | |
| Setup Groups Screen | ✅ | |
| Challenge Arena Screen | ✅ | تدعم الهاتف والتابلت |
| Question Dialog | ✅ | اختيار المجموعة، الإجابات |
| Results Screen | ✅ | داخل challenge_arena_screen.dart |
| RTL عربي عالمي | ✅ | |
| API base URL قابل للتهيئة | ✅ | `lib/core/config/app_config.dart` |
| دعم التابلت | ✅ | PhoneLayout + TabletLayout |

---

## 9. الخطوات المتبقية (يدوية)

| المهمة | ملاحظة |
|---|---|
| تهيئة MySQL للإنتاج | تحديث .env: DB_CONNECTION=mysql |
| إضافة خطوط Cairo | تحميل ملفات `Cairo-Regular.ttf` و `Cairo-Bold.ttf` إلى `mobile/assets/fonts/` ثم إعادة إضافة fonts في pubspec.yaml |
| نشر للإنتاج | `php artisan config:cache && php artisan route:cache` |
| إعداد Nginx/Apache | توجيه `public/` |
| بناء Flutter APK | `flutter build apk --release` |
| اختبار الاستيراد عبر ملف Excel حقيقي | استخدام القالب في `docs/excel-template-spec.md` |
