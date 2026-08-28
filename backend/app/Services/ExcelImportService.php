<?php

namespace App\Services;

use App\Models\Chapter;
use App\Models\Grade;
use App\Models\Lesson;
use App\Models\Question;
use App\Models\Subject;
use App\Models\SubjectPart;
use App\Support\ContentTextSanitizer;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class ExcelImportService
{
    private array $requiredHeaders = [
        'الصف الدراسي',
        'المادة',
        'الجزء',
        'الفصل',
        'الدرس',
        'نص السؤال',
        'نوع السؤال',
        'الإجابة الصحيحة',
        'مستوى السؤال',
    ];

    private array $levelMap = [
        'سهل' => 'easy',
        'سهلة' => 'easy',
        'easy' => 'easy',
        'صعب' => 'hard',
        'صعبة' => 'hard',
        'hard' => 'hard',
    ];

    private array $typeMap = [
        'اختيار من متعدد' => 'multiple_choice',
        'اختيارات متعددة' => 'multiple_choice',
        'متعدد' => 'multiple_choice',
        'multiple choice' => 'multiple_choice',
        'multiple_choice' => 'multiple_choice',
        'صح أو خطأ' => 'true_false',
        'صح وخطأ' => 'true_false',
        'true false' => 'true_false',
        'true_false' => 'true_false',
        'نصي' => 'text',
        'مقالي' => 'text',
        'كتابي' => 'text',
        'text' => 'text',
    ];

    private array $headerAliases = [
        'الصف الدراسي' => ['alsf_aldrasy'],
        'المادة' => ['almad'],
        'الجزء' => ['algzaa'],
        'الفصل' => ['alfsl'],
        'الدرس' => ['aldrs'],
        'رقم السؤال' => ['rkm_alsoal'],
        'نص السؤال' => ['ns_alsoal'],
        'نوع السؤال' => ['noaa_alsoal'],
        'الاختيار الأول' => ['alakhtyar_alaol'],
        'الاختيار الثاني' => ['alakhtyar_althany'],
        'الاختيار الثالث' => ['alakhtyar_althalth'],
        'الاختيار الرابع' => ['alakhtyar_alrabaa'],
        'الإجابة الصحيحة' => ['alagab_alshyh'],
        'مستوى السؤال' => ['msto_alsoal'],
        'الشرح أو الملاحظة' => ['alshrh_ao_almlahth'],
        'مفعل؟' => ['mfaaal', 'mfaal'],
    ];

    public function import(Collection $rows): array
    {
        $created = 0;
        $skipped = 0;
        $errors = [];

        $rows = $rows->map(fn ($row) => $this->normalizeRowHeaders(
            $row instanceof Collection ? $row->toArray() : (array) $row
        ));

        $this->validateHeaders($rows);

        foreach ($rows as $index => $row) {
            $rowNumber = $index + 2; // Excel row number (header is row 1)

            try {
                $result = $this->processRow($row, $rowNumber);

                if ($result === 'created') {
                    $created++;
                } else {
                    $skipped++;
                }
            } catch (\Throwable $e) {
                $errors[] = [
                    'row' => $rowNumber,
                    'error' => $e->getMessage(),
                ];
                $skipped++;
            }
        }

        return compact('created', 'skipped', 'errors');
    }

    private function processRow(array $row, int $rowNumber): string
    {
        $row = $this->prepareRow($row, $rowNumber);

        return DB::transaction(function () use ($row, $rowNumber) {
            $grade = $this->resolveGrade($row['الصف الدراسي']);
            $subject = $this->resolveSubject($grade, $row['المادة']);
            $subject->ensureDefaultParts();
            $subjectPart = $this->resolveSubjectPart($subject, $row['الجزء'], $rowNumber);
            $chapter = $this->resolveChapter($subject, $subjectPart, $row['الفصل']);
            $lesson = $this->resolveLesson($chapter, $row['الدرس']);

            if ($this->questionExists($lesson, $row['نص السؤال'], $row['نوع السؤال'])) {
                return 'skipped';
            }

            Question::create([
                'lesson_id' => $lesson->id,
                'visibility' => 'official',
                'question_text' => trim($row['نص السؤال']),
                'question_type' => $row['نوع السؤال'],
                'option_a' => $row['الاختيار الأول'] ?? null,
                'option_b' => $row['الاختيار الثاني'] ?? null,
                'option_c' => $row['الاختيار الثالث'] ?? null,
                'option_d' => $row['الاختيار الرابع'] ?? null,
                'correct_answer' => trim($row['الإجابة الصحيحة']),
                'level' => $row['مستوى السؤال'],
                'explanation' => $row['الشرح أو الملاحظة'] ?? null,
                'sort_order' => $row['رقم السؤال'] ?? null,
                'is_active' => $row['مفعل؟'],
            ]);

            return 'created';
        });
    }

    private function prepareRow(array $row, int $rowNumber): array
    {
        $row = $this->sanitizeRow($row);

        foreach ($this->requiredHeaders as $field) {
            if (empty($row[$field])) {
                throw new \InvalidArgumentException("الحقل '{$field}' مطلوب في الصف {$rowNumber}.");
            }
        }

        $levelValue = $row['مستوى السؤال'];
        $level = $this->mappedValue($levelValue, $this->levelMap);
        if ($level === null) {
            throw new \InvalidArgumentException("قيمة مستوى السؤال '{$levelValue}' غير صحيحة في الصف {$rowNumber}. المقبول: سهل، صعب.");
        }

        $typeValue = $row['نوع السؤال'];
        $type = $this->mappedValue($typeValue, $this->typeMap);
        if ($type === null) {
            throw new \InvalidArgumentException("نوع السؤال '{$typeValue}' غير صحيح في الصف {$rowNumber}.");
        }

        $row['مستوى السؤال'] = $level;
        $row['نوع السؤال'] = $type;
        $row['مفعل؟'] = $this->parseBoolean($row['مفعل؟'] ?? true);

        if ($type === 'multiple_choice') {
            $options = array_values(array_filter([
                $row['الاختيار الأول'] ?? null,
                $row['الاختيار الثاني'] ?? null,
                $row['الاختيار الثالث'] ?? null,
                $row['الاختيار الرابع'] ?? null,
            ], fn ($value) => $value !== null && $value !== ''));

            if (count($options) < 2) {
                throw new \InvalidArgumentException("سؤال الاختيار من متعدد يحتاج اختيارين على الأقل في الصف {$rowNumber}.");
            }

            $row['الإجابة الصحيحة'] = $this->resolveMultipleChoiceAnswer(
                $row['الإجابة الصحيحة'],
                $options,
                $rowNumber
            );
        }

        if ($type === 'true_false') {
            $row['الإجابة الصحيحة'] = $this->resolveTrueFalseAnswer($row['الإجابة الصحيحة'], $rowNumber);
        }

        if (! empty($row['رقم السؤال']) && ! is_numeric($row['رقم السؤال'])) {
            throw new \InvalidArgumentException("رقم السؤال يجب أن يكون رقما في الصف {$rowNumber}.");
        }

        return $row;
    }

    private function resolveGrade(string $name): Grade
    {
        $grade = $this->findByNormalizedName(
            Grade::query()->where('visibility', 'official')->get(),
            $name
        );

        return $grade ?? Grade::create([
            'name' => $name,
            'visibility' => 'official',
            'sort_order' => 0,
            'is_active' => true,
        ]);
    }

    private function resolveSubject(Grade $grade, string $name): Subject
    {
        $subject = $this->findByNormalizedName(
            $grade->subjects()->where('visibility', 'official')->get(),
            $name
        );

        return $subject ?? $grade->subjects()->create([
            'name' => $name,
            'visibility' => 'official',
            'sort_order' => 0,
            'is_active' => true,
        ]);
    }

    private function resolveChapter(Subject $subject, SubjectPart $subjectPart, string $name): Chapter
    {
        $chapter = $this->findByNormalizedName(
            $subjectPart->chapters()->where('visibility', 'official')->get(),
            $name
        );

        return $chapter ?? Chapter::create([
            'subject_id' => $subject->id,
            'subject_part_id' => $subjectPart->id,
            'name' => $name,
            'visibility' => 'official',
            'sort_order' => 0,
            'is_active' => true,
        ]);
    }

    private function resolveLesson(Chapter $chapter, string $name): Lesson
    {
        $lesson = $this->findByNormalizedName(
            $chapter->lessons()->where('visibility', 'official')->get(),
            $name
        );

        return $lesson ?? $chapter->lessons()->create([
            'name' => $name,
            'visibility' => 'official',
            'sort_order' => 0,
            'is_active' => true,
        ]);
    }

    private function findByNormalizedName(Collection $models, string $name): mixed
    {
        $normalizedName = $this->normalizeForComparison($name);

        return $models->first(
            fn ($model) => $this->normalizeForComparison($model->name) === $normalizedName
        );
    }

    private function questionExists(Lesson $lesson, string $questionText, string $questionType): bool
    {
        $normalizedQuestion = $this->normalizeForComparison($questionText);

        return $lesson->questions()
            ->where('visibility', 'official')
            ->where('question_type', $questionType)
            ->get()
            ->contains(
                fn (Question $question) => $this->normalizeForComparison($question->question_text) === $normalizedQuestion
            );
    }

    private function mappedValue(mixed $value, array $map): ?string
    {
        $normalizedValue = $this->normalizeForComparison($value);

        foreach ($map as $label => $storedValue) {
            if ($this->normalizeForComparison($label) === $normalizedValue) {
                return $storedValue;
            }
        }

        return null;
    }

    private function resolveTrueFalseAnswer(mixed $value, int $rowNumber): string
    {
        $normalized = $this->normalizeForComparison($value);
        $trueValues = ['صح', 'صحيح', 'نعم', 'yes', 'true', '1'];
        $falseValues = ['خطأ', 'خاطئ', 'غير صحيح', 'لا', 'no', 'false', '0'];

        if (in_array($normalized, array_map(fn ($item) => $this->normalizeForComparison($item), $trueValues), true)) {
            return 'صح';
        }

        if (in_array($normalized, array_map(fn ($item) => $this->normalizeForComparison($item), $falseValues), true)) {
            return 'خطأ';
        }

        throw new \InvalidArgumentException("إجابة الصح والخطأ يجب أن تكون صح أو خطأ في الصف {$rowNumber}.");
    }

    private function resolveMultipleChoiceAnswer(mixed $answer, array $options, int $rowNumber): string
    {
        $normalizedAnswer = $this->normalizeForComparison($answer);
        $scoredOptions = [];

        foreach ($options as $option) {
            $normalizedOption = $this->normalizeForComparison($option);

            if ($normalizedAnswer === $normalizedOption) {
                return $option;
            }

            similar_text($normalizedAnswer, $normalizedOption, $score);
            $scoredOptions[] = ['option' => $option, 'score' => $score];
        }

        usort($scoredOptions, fn (array $left, array $right) => $right['score'] <=> $left['score']);

        $best = $scoredOptions[0] ?? null;
        $second = $scoredOptions[1] ?? null;
        $isClearMatch = $best !== null
            && $best['score'] >= 85
            && ($second === null || ($best['score'] - $second['score']) >= 8);

        if ($isClearMatch) {
            return $best['option'];
        }

        if ($best !== null && $best['score'] >= 85) {
            throw new \InvalidArgumentException(
                "الإجابة الصحيحة قريبة من أكثر من اختيار ولا يمكن تحديدها بأمان في الصف {$rowNumber}."
            );
        }

        throw new \InvalidArgumentException("الإجابة الصحيحة يجب أن تطابق أحد الاختيارات في الصف {$rowNumber}.");
    }

    private function normalizeForComparison(mixed $value): string
    {
        $text = ContentTextSanitizer::clean($value) ?? '';
        $text = mb_strtolower($text, 'UTF-8');
        $text = preg_replace('/[\x{0640}\x{064B}-\x{065F}\x{0670}]/u', '', $text) ?? $text;
        $text = str_replace(
            ['أ', 'إ', 'آ', 'ٱ', 'ى', 'ئ', 'ؤ', 'ة'],
            ['ا', 'ا', 'ا', 'ا', 'ي', 'ي', 'و', 'ه'],
            $text
        );
        $text = preg_replace('/[^\p{L}\p{N}]+/u', ' ', $text) ?? $text;

        return trim(preg_replace('/\s+/u', ' ', $text) ?? $text);
    }

    private function validateHeaders(Collection $rows): void
    {
        if ($rows->isEmpty()) {
            throw new \InvalidArgumentException('ملف Excel لا يحتوي على أي بيانات.');
        }

        $headers = array_keys((array) $rows->first());
        $missing = array_values(array_diff($this->requiredHeaders, $headers));

        if ($missing !== []) {
            throw new \InvalidArgumentException('أعمدة الملف غير مطابقة. الأعمدة الناقصة: '.implode('، ', $missing));
        }
    }

    private function normalizeRowHeaders(array $row): array
    {
        $normalized = [];

        foreach ($row as $key => $value) {
            $normalized[$this->canonicalHeader((string) $key)] = $value;
        }

        return $normalized;
    }

    private function canonicalHeader(string $header): string
    {
        $header = trim($header);

        foreach ($this->headerAliases as $canonical => $aliases) {
            if ($header === $canonical || in_array($header, $aliases, true)) {
                return $canonical;
            }
        }

        return $header;
    }

    private function sanitizeRow(array $row): array
    {
        foreach ([
            'الصف الدراسي',
            'المادة',
            'الجزء',
            'الفصل',
            'الدرس',
            'نص السؤال',
            'نوع السؤال',
            'الاختيار الأول',
            'الاختيار الثاني',
            'الاختيار الثالث',
            'الاختيار الرابع',
            'الإجابة الصحيحة',
            'مستوى السؤال',
            'الشرح أو الملاحظة',
        ] as $field) {
            if (array_key_exists($field, $row)) {
                $row[$field] = ContentTextSanitizer::clean($row[$field]);
            }
        }

        return $row;
    }

    private function parseBoolean(mixed $value): bool
    {
        if (is_bool($value)) {
            return $value;
        }

        $normalized = $this->normalizeForComparison($value);

        if ($normalized === '') {
            return true;
        }

        return in_array($normalized, ['1', 'نعم', 'yes', 'true', '✓'], true);
    }

    private function resolveSubjectPart(Subject $subject, mixed $value, int $rowNumber): SubjectPart
    {
        $normalized = $this->normalizeForComparison($value);

        if (in_array($normalized, ['1', 'الاول', 'الجزء الاول'], true)) {
            return $subject->parts()->where('part_number', 1)->firstOrFail();
        }

        if (in_array($normalized, ['2', 'الثاني', 'الجزء الثاني'], true)) {
            return $subject->parts()->where('part_number', 2)->firstOrFail();
        }

        throw new \InvalidArgumentException(
            "قيمة الجزء '{$normalized}' غير صحيحة في الصف {$rowNumber}. المقبول: الجزء الأول، الجزء الثاني، 1، 2."
        );
    }
}
