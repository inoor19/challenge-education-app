<?php

namespace App\Http\Requests\Api;

use App\Models\Chapter;
use App\Models\Lesson;
use App\Models\Question;
use App\Models\Subject;
use App\Models\SubjectPart;
use App\Services\EntitlementService;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Validator;

class CreateChallengeRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'grade_id' => ['required', 'exists:grades,id'],
            'grade_section' => ['required', 'string', 'in:أ,ب,ج'],
            'subject_id' => ['required', 'exists:subjects,id'],
            'subject_part_id' => ['required', 'exists:subject_parts,id'],
            'chapter_ids' => ['required', 'array', 'min:1'],
            'chapter_ids.*' => ['exists:chapters,id'],
            'lesson_ids' => ['required', 'array', 'min:1'],
            'lesson_ids.*' => ['exists:lessons,id'],
            'question_ids' => ['sometimes', 'array', 'min:1'],
            'question_ids.*' => ['exists:questions,id', 'distinct'],
            'timer_seconds' => ['nullable', 'integer', 'min:10', 'max:300'],
            'timer_enabled' => ['nullable', 'boolean'],
        ];
    }

    public function messages(): array
    {
        return [
            'grade_id.required' => 'الصف الدراسي مطلوب.',
            'grade_section.required' => 'شعبة الصف مطلوبة.',
            'grade_section.in' => 'شعبة الصف يجب أن تكون أ أو ب أو ج.',
            'subject_id.required' => 'المادة مطلوبة.',
            'subject_part_id.required' => 'جزء المادة مطلوب.',
            'chapter_ids.required' => 'يجب اختيار فصل واحد على الأقل.',
            'lesson_ids.required' => 'يجب اختيار درس واحد على الأقل.',
            'question_ids.min' => 'يجب اختيار سؤال واحد على الأقل.',
        ];
    }

    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator) {
            if ($validator->errors()->isNotEmpty()) {
                return;
            }

            $subject = Subject::find($this->integer('subject_id'));
            if (! $subject || $subject->grade_id !== $this->integer('grade_id')) {
                $validator->errors()->add('subject_id', 'المادة لا تتبع الصف الدراسي المحدد.');
            }

            $subjectPart = SubjectPart::find($this->integer('subject_part_id'));
            if (! $subjectPart || $subjectPart->subject_id !== $this->integer('subject_id')) {
                $validator->errors()->add('subject_part_id', 'جزء المادة لا يتبع المادة المحددة.');
            }

            $chapterIds = collect($this->input('chapter_ids', []))->map(fn ($id) => (int) $id);
            $invalidChapters = Chapter::whereIn('id', $chapterIds)
                ->where(function ($query) {
                    $query->where('subject_id', '!=', $this->integer('subject_id'))
                        ->orWhere('subject_part_id', '!=', $this->integer('subject_part_id'));
                })
                ->exists();
            if ($invalidChapters) {
                $validator->errors()->add('chapter_ids', 'كل الفصول المختارة يجب أن تتبع المادة وجزء المادة المحددين.');
            }

            $lessonIds = collect($this->input('lesson_ids', []))->map(fn ($id) => (int) $id);
            $invalidLessons = Lesson::whereIn('id', $lessonIds)
                ->whereNotIn('chapter_id', $chapterIds)
                ->exists();
            if ($invalidLessons) {
                $validator->errors()->add('lesson_ids', 'كل الدروس المختارة يجب أن تتبع الفصول المحددة.');
            }

            $accessibleQuestionIds = app(EntitlementService::class)->accessibleQuestionIds($this->user());

            $questionIds = collect($this->input('question_ids', []))->map(fn ($id) => (int) $id)->unique()->values();
            if ($this->has('question_ids')) {
                $validSelectedQuestionCount = $questionIds->isEmpty()
                    ? 0
                    : Question::whereIn('id', $accessibleQuestionIds)
                        ->whereIn('lesson_id', $lessonIds)
                        ->whereIn('id', $questionIds)
                        ->count();

                if ($validSelectedQuestionCount !== $questionIds->count()) {
                    $validator->errors()->add('question_ids', 'كل الأسئلة المختارة يجب أن تتبع الدروس المحددة وأن تكون متاحة لهذا الحساب.');
                }
            }

            $accessibleQuestionCount = $lessonIds->isEmpty()
                ? 0
                : Question::whereIn('id', $accessibleQuestionIds)
                    ->whereIn('lesson_id', $lessonIds)
                    ->count();

            if ($accessibleQuestionCount < 1) {
                $validator->errors()->add('lesson_ids', 'لا توجد أسئلة متاحة في الحزم المفعلة لهذه الدروس.');
            }
        });
    }
}
