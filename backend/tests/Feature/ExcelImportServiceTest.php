<?php

namespace Tests\Feature;

use App\Exports\QuestionsTemplateExport;
use App\Imports\QuestionsImport;
use App\Models\Chapter;
use App\Models\Grade;
use App\Models\Lesson;
use App\Models\Question;
use App\Models\Subject;
use App\Models\SubjectPart;
use App\Services\ExcelImportService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Storage;
use Maatwebsite\Excel\Facades\Excel;
use Tests\TestCase;

class ExcelImportServiceTest extends TestCase
{
    use RefreshDatabase;

    public function test_import_requires_subject_part_column(): void
    {
        $this->expectException(\InvalidArgumentException::class);
        $this->expectExceptionMessage('الجزء');

        app(ExcelImportService::class)->import(collect([
            [
                'الصف الدراسي' => 'الصف الثاني',
                'المادة' => 'علوم',
                'الفصل' => 'الفصل الأول',
                'الدرس' => 'الدرس الأول',
                'نص السؤال' => 'ما وحدة الكتلة؟',
                'نوع السؤال' => 'نصي',
                'الإجابة الصحيحة' => 'كيلوغرام',
                'مستوى السؤال' => 'سهل',
            ],
        ]));
    }

    public function test_import_links_chapter_to_second_subject_part(): void
    {
        $result = app(ExcelImportService::class)->import(collect([
            [
                'الصف الدراسي' => 'الصف الثاني',
                'المادة' => 'علوم',
                'الجزء' => 'الجزء الثاني',
                'الفصل' => 'الفصل الثالث',
                'الدرس' => 'الدرس الثاني',
                'رقم السؤال' => 1,
                'نص السؤال' => 'ما الفرق بين الكتلة والوزن؟',
                'نوع السؤال' => 'نصي',
                'الإجابة الصحيحة' => 'الكتلة ثابتة أما الوزن يتغير بتغير الجاذبية',
                'مستوى السؤال' => 'صعب',
                'الشرح أو الملاحظة' => 'مثال على سؤال نصي للجزء الثاني',
                'مفعل؟' => 'نعم',
            ],
        ]));

        $subject = Subject::where('name', 'علوم')->firstOrFail();
        $partTwo = $subject->parts()->where('part_number', 2)->firstOrFail();
        $chapter = Chapter::where('name', 'الفصل الثالث')->firstOrFail();

        $this->assertSame(['created' => 1, 'skipped' => 0, 'errors' => []], $result);
        $this->assertSame($partTwo->id, $chapter->subject_part_id);
        $this->assertDatabaseHas('questions', [
            'question_text' => 'ما الفرق بين الكتلة والوزن؟',
            'level' => 'hard',
        ]);
        $this->assertSame(1, Question::count());
    }

    public function test_import_accepts_slugged_arabic_heading_keys(): void
    {
        $result = app(ExcelImportService::class)->import(collect([
            [
                'alsf_aldrasy' => 'الصف الأول',
                'almad' => 'الرياضيات',
                'algzaa' => 'الجزء الأول',
                'alfsl' => 'الأعداد والعد',
                'aldrs' => 'قراءة الأعداد',
                'rkm_alsoal' => 1,
                'ns_alsoal' => 'ما أفضل طريقة لقراءة عدد جديد؟',
                'noaa_alsoal' => 'اختيار من متعدد',
                'alakhtyar_alaol' => 'أقرأ المنازل ثم أنطق العدد',
                'alakhtyar_althany' => 'أحذف الأرقام',
                'alakhtyar_althalth' => 'أغيّر ترتيب الأرقام',
                'alakhtyar_alrabaa' => 'أترك العدد بلا قراءة',
                'alagab_alshyh' => 'أقرأ المنازل ثم أنطق العدد',
                'msto_alsoal' => 'سهل',
                'alshrh_ao_almlahth' => 'قراءة المنازل تساعد على نطق العدد بشكل صحيح.',
                'mfaaal' => 'نعم',
            ],
        ]));

        $this->assertSame(['created' => 1, 'skipped' => 0, 'errors' => []], $result);
        $this->assertDatabaseHas('questions', [
            'question_text' => 'ما أفضل طريقة لقراءة عدد جديد؟',
            'correct_answer' => 'أقرأ المنازل ثم أنطق العدد',
        ]);
    }

    public function test_import_rejects_invalid_subject_part_value(): void
    {
        $result = app(ExcelImportService::class)->import(collect([
            [
                'الصف الدراسي' => 'الصف الثاني',
                'المادة' => 'علوم',
                'الجزء' => 'جزء ثالث',
                'الفصل' => 'الفصل الأول',
                'الدرس' => 'الدرس الأول',
                'نص السؤال' => 'سؤال',
                'نوع السؤال' => 'نصي',
                'الإجابة الصحيحة' => 'إجابة',
                'مستوى السؤال' => 'سهل',
            ],
        ]));

        $this->assertSame(0, $result['created']);
        $this->assertSame(1, $result['skipped']);
        $this->assertStringContainsString('قيمة الجزء', $result['errors'][0]['error']);
    }

    public function test_import_sanitizes_control_characters_and_keeps_literal_backslashes(): void
    {
        $result = app(ExcelImportService::class)->import(collect([
            [
                'الصف الدراسي' => " الصف الثاني\x00 ",
                'المادة' => 'علوم',
                'الجزء' => 'الجزء الأول',
                'الفصل' => 'الفصل الأول',
                'الدرس' => 'الدرس الأول',
                'رقم السؤال' => 1,
                'نص السؤال' => " سؤال \\path و\\u0633 قبل\x00بعد ",
                'نوع السؤال' => 'اختيار من متعدد',
                'الاختيار الأول' => ' اختيار \\path و\\u0633 ',
                'الاختيار الثاني' => 'اختيار آخر',
                'الإجابة الصحيحة' => 'اختيار \path و\u0633',
                'مستوى السؤال' => 'سهل',
                'الشرح أو الملاحظة' => " شرح \\u0634 قبل\x07بعد ",
                'مفعل؟' => 'نعم',
            ],
        ]));

        $question = Question::firstOrFail();

        $this->assertSame(['created' => 1, 'skipped' => 0, 'errors' => []], $result);
        $this->assertSame('سؤال \path و\u0633 قبلبعد', $question->question_text);
        $this->assertSame('اختيار \path و\u0633', $question->option_a);
        $this->assertSame('شرح \u0634 قبلبعد', $question->explanation);
        $this->assertDatabaseHas('grades', ['name' => 'الصف الثاني']);
    }

    public function test_questions_import_converts_collection_rows_to_plain_arrays(): void
    {
        $import = new QuestionsImport(app(ExcelImportService::class));

        $import->collection(collect([
            collect($this->validTextRow()),
        ]));

        $this->assertSame(['created' => 1, 'skipped' => 0, 'errors' => []], $import->result);
        $this->assertDatabaseHas('questions', ['question_text' => 'ما فائدة الجذور؟']);
    }

    public function test_exported_template_can_be_imported_through_laravel_excel(): void
    {
        Storage::fake('local');
        $filename = 'questions-template.xlsx';

        $this->assertTrue(Excel::store(new QuestionsTemplateExport, $filename, 'local'));

        $import = new QuestionsImport(app(ExcelImportService::class));
        Excel::import($import, Storage::disk('local')->path($filename));

        $this->assertSame(['created' => 3, 'skipped' => 0, 'errors' => []], $import->result);
        $this->assertSame(3, Question::count());
    }

    public function test_import_converts_arabic_values_to_database_values(): void
    {
        $row = $this->validTextRow([
            'نص السؤال' => 'هل النبات مخلوق حي؟',
            'نوع السؤال' => 'صح او خطا',
            'الإجابة الصحيحة' => 'نعم',
            'مستوى السؤال' => 'صعبة',
            'مفعل؟' => 'لا',
        ]);

        $result = app(ExcelImportService::class)->import(collect([$row]));
        $question = Question::firstOrFail();

        $this->assertSame(['created' => 1, 'skipped' => 0, 'errors' => []], $result);
        $this->assertSame('true_false', $question->question_type);
        $this->assertSame('hard', $question->level);
        $this->assertSame('صح', $question->correct_answer);
        $this->assertFalse($question->is_active);
    }

    public function test_reimport_reuses_normalized_official_hierarchy_and_skips_duplicate_question(): void
    {
        $service = app(ExcelImportService::class);

        $firstResult = $service->import(collect([
            $this->validTextRow([
                'الصف الدراسي' => 'الصَّف الأوّل',
                'المادة' => 'علـوم',
                'الفصل' => 'الفصل الأوّل',
                'الدرس' => 'الدرس الأوّل',
                'نص السؤال' => 'ما النبات ؟',
            ]),
        ]));

        $secondResult = $service->import(collect([
            $this->validTextRow([
                'الصف الدراسي' => 'الصف الاول',
                'المادة' => 'علوم',
                'الفصل' => 'الفصل الاول',
                'الدرس' => 'الدرس الاول',
                'نص السؤال' => 'ما النبات؟',
            ]),
        ]));

        $this->assertSame(['created' => 1, 'skipped' => 0, 'errors' => []], $firstResult);
        $this->assertSame(['created' => 0, 'skipped' => 1, 'errors' => []], $secondResult);
        $this->assertSame(1, Grade::count());
        $this->assertSame(1, Subject::count());
        $this->assertSame(2, SubjectPart::count());
        $this->assertSame(1, Chapter::count());
        $this->assertSame(1, Lesson::count());
        $this->assertSame(1, Question::count());
    }

    public function test_import_corrects_a_clear_multiple_choice_answer_typo(): void
    {
        $row = $this->validTextRow([
            'نص السؤال' => 'ما احتياجات المخلوقات الحية؟',
            'نوع السؤال' => 'اختيار من متعدد',
            'الاختيار الأول' => 'الصخور و التربة',
            'الاختيار الثاني' => 'الغذاء و الماء و الهواء',
            'الاختيار الثالث' => 'الألعاب و الملابس',
            'الاختيار الرابع' => 'الأبنية و الطرق',
            'الإجابة الصحيحة' => 'لغذاء و الماء و الهواء',
        ]);

        $result = app(ExcelImportService::class)->import(collect([$row]));

        $this->assertSame(['created' => 1, 'skipped' => 0, 'errors' => []], $result);
        $this->assertDatabaseHas('questions', [
            'correct_answer' => 'الغذاء و الماء و الهواء',
        ]);
    }

    public function test_import_rejects_an_ambiguous_approximate_answer(): void
    {
        $row = $this->validTextRow([
            'نوع السؤال' => 'اختيار من متعدد',
            'الاختيار الأول' => 'كتاب العلوم أ',
            'الاختيار الثاني' => 'كتاب العلوم ب',
            'الإجابة الصحيحة' => 'كتاب العلوم',
        ]);

        $result = app(ExcelImportService::class)->import(collect([$row]));

        $this->assertSame(0, $result['created']);
        $this->assertSame(1, $result['skipped']);
        $this->assertStringContainsString('قريبة من أكثر من اختيار', $result['errors'][0]['error']);
        $this->assertSame(0, Question::count());
    }

    public function test_questions_template_contains_part_column_and_examples(): void
    {
        $rows = (new QuestionsTemplateExport)->array();

        $this->assertCount(4, $rows);
        $this->assertSame('الجزء', $rows[0][2]);
        $this->assertContains('الجزء الأول', array_column(array_slice($rows, 1), 2));
        $this->assertContains('الجزء الثاني', array_column(array_slice($rows, 1), 2));
        $this->assertContains('اختيار من متعدد', array_column(array_slice($rows, 1), 7));
        $this->assertContains('صح أو خطأ', array_column(array_slice($rows, 1), 7));
        $this->assertContains('نصي', array_column(array_slice($rows, 1), 7));
    }

    private function validTextRow(array $overrides = []): array
    {
        return array_replace([
            'الصف الدراسي' => 'الصف الأول',
            'المادة' => 'علوم',
            'الجزء' => 'الجزء الأول',
            'الفصل' => 'الفصل الأول',
            'الدرس' => 'الدرس الأول',
            'رقم السؤال' => 1,
            'نص السؤال' => 'ما فائدة الجذور؟',
            'نوع السؤال' => 'نصي',
            'الاختيار الأول' => null,
            'الاختيار الثاني' => null,
            'الاختيار الثالث' => null,
            'الاختيار الرابع' => null,
            'الإجابة الصحيحة' => 'تثبت النبات في التربة',
            'مستوى السؤال' => 'سهل',
            'الشرح أو الملاحظة' => null,
            'مفعل؟' => 'نعم',
        ], $overrides);
    }
}
