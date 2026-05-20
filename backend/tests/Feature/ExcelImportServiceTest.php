<?php

namespace Tests\Feature;

use App\Exports\QuestionsTemplateExport;
use App\Models\Chapter;
use App\Models\Question;
use App\Models\Subject;
use App\Services\ExcelImportService;
use Illuminate\Foundation\Testing\RefreshDatabase;
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
                'الاختيار الأول' => " اختيار \\path و\\u0633 ",
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

    public function test_questions_template_contains_part_column_and_examples(): void
    {
        $rows = (new QuestionsTemplateExport())->array();

        $this->assertCount(4, $rows);
        $this->assertSame('الجزء', $rows[0][2]);
        $this->assertContains('الجزء الأول', array_column(array_slice($rows, 1), 2));
        $this->assertContains('الجزء الثاني', array_column(array_slice($rows, 1), 2));
        $this->assertContains('اختيار من متعدد', array_column(array_slice($rows, 1), 7));
        $this->assertContains('صح أو خطأ', array_column(array_slice($rows, 1), 7));
        $this->assertContains('نصي', array_column(array_slice($rows, 1), 7));
    }
}
