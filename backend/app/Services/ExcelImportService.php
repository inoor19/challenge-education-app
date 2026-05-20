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
        'easy' => 'easy',
        'صعب' => 'hard',
        'hard' => 'hard',
    ];

    private array $typeMap = [
        'اختيار من متعدد' => 'multiple_choice',
        'multiple_choice' => 'multiple_choice',
        'صح أو خطأ' => 'true_false',
        'true_false' => 'true_false',
        'نصي' => 'text',
        'text' => 'text',
    ];

    public function import(Collection $rows): array
    {
        $created = 0;
        $skipped = 0;
        $errors = [];

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
        $row = $this->sanitizeRow($row);

        $this->validateRow($row, $rowNumber);

        return DB::transaction(function () use ($row, $rowNumber) {
            $grade = Grade::firstOrCreate(
                ['name' => trim($row['الصف الدراسي'])],
                ['sort_order' => 0, 'is_active' => true]
            );

            $subject = Subject::firstOrCreate(
                ['grade_id' => $grade->id, 'name' => trim($row['المادة'])],
                ['sort_order' => 0, 'is_active' => true]
            );
            $subject->ensureDefaultParts();
            $subjectPart = $this->resolveSubjectPart($subject, $row['الجزء'], $rowNumber);

            $chapter = Chapter::firstOrCreate(
                ['subject_id' => $subject->id, 'subject_part_id' => $subjectPart->id, 'name' => trim($row['الفصل'])],
                ['subject_part_id' => $subjectPart->id, 'sort_order' => 0, 'is_active' => true]
            );
            if (! $chapter->subject_part_id) {
                $chapter->update(['subject_part_id' => $subjectPart->id]);
            }

            $lesson = Lesson::firstOrCreate(
                ['chapter_id' => $chapter->id, 'name' => trim($row['الدرس'])],
                ['sort_order' => 0, 'is_active' => true]
            );

            $level = $this->levelMap[trim($row['مستوى السؤال'])] ?? null;
            $type = $this->typeMap[trim($row['نوع السؤال'])] ?? null;
            $isActive = $this->parseBoolean($row['مفعل؟'] ?? true);

            Question::create([
                'lesson_id' => $lesson->id,
                'question_text' => trim($row['نص السؤال']),
                'question_type' => $type,
                'option_a' => $row['الاختيار الأول'] ?? null,
                'option_b' => $row['الاختيار الثاني'] ?? null,
                'option_c' => $row['الاختيار الثالث'] ?? null,
                'option_d' => $row['الاختيار الرابع'] ?? null,
                'correct_answer' => trim($row['الإجابة الصحيحة']),
                'level' => $level,
                'explanation' => $row['الشرح أو الملاحظة'] ?? null,
                'sort_order' => $row['رقم السؤال'] ?? null,
                'is_active' => $isActive,
            ]);

            return 'created';
        });
    }

    private function validateRow(array $row, int $rowNumber): void
    {
        foreach ($this->requiredHeaders as $field) {
            if (empty($row[$field])) {
                throw new \InvalidArgumentException("الحقل '{$field}' مطلوب في الصف {$rowNumber}.");
            }
        }

        $levelValue = trim($row['مستوى السؤال']);
        if (!isset($this->levelMap[$levelValue])) {
            throw new \InvalidArgumentException("قيمة مستوى السؤال '{$levelValue}' غير صحيحة في الصف {$rowNumber}. المقبول: سهل، صعب.");
        }

        $typeValue = trim($row['نوع السؤال']);
        if (!isset($this->typeMap[$typeValue])) {
            throw new \InvalidArgumentException("نوع السؤال '{$typeValue}' غير صحيح في الصف {$rowNumber}.");
        }

        if ($this->typeMap[$typeValue] === 'multiple_choice') {
            $options = array_filter([
                trim((string) ($row['الاختيار الأول'] ?? '')),
                trim((string) ($row['الاختيار الثاني'] ?? '')),
                trim((string) ($row['الاختيار الثالث'] ?? '')),
                trim((string) ($row['الاختيار الرابع'] ?? '')),
            ]);

            if (count($options) < 2) {
                throw new \InvalidArgumentException("سؤال الاختيار من متعدد يحتاج اختيارين على الأقل في الصف {$rowNumber}.");
            }

            if (! in_array(trim($row['الإجابة الصحيحة']), $options, true)) {
                throw new \InvalidArgumentException("الإجابة الصحيحة يجب أن تطابق أحد الاختيارات في الصف {$rowNumber}.");
            }
        }

        if ($this->typeMap[$typeValue] === 'true_false' && ! in_array(trim($row['الإجابة الصحيحة']), ['صح', 'خطأ', 'true', 'false'], true)) {
            throw new \InvalidArgumentException("إجابة الصح والخطأ يجب أن تكون صح أو خطأ في الصف {$rowNumber}.");
        }

        if (! empty($row['رقم السؤال']) && ! is_numeric($row['رقم السؤال'])) {
            throw new \InvalidArgumentException("رقم السؤال يجب أن يكون رقما في الصف {$rowNumber}.");
        }
    }

    private function validateHeaders(Collection $rows): void
    {
        if ($rows->isEmpty()) {
            throw new \InvalidArgumentException('ملف Excel لا يحتوي على أي بيانات.');
        }

        $headers = array_keys((array) $rows->first());
        $missing = array_values(array_diff($this->requiredHeaders, $headers));

        if ($missing !== []) {
            throw new \InvalidArgumentException('أعمدة الملف غير مطابقة. الأعمدة الناقصة: ' . implode('، ', $missing));
        }
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
        return in_array(strtolower((string) $value), ['1', 'نعم', 'yes', 'true', '✓'], true);
    }

    private function resolveSubjectPart(Subject $subject, mixed $value, int $rowNumber): SubjectPart
    {
        $normalized = trim((string) $value);

        if (in_array($normalized, ['1', 'الأول', 'الاول', 'الجزء الأول', 'الجزء الاول'], true)) {
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
