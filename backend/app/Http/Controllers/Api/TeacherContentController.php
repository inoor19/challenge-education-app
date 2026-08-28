<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\ChapterResource;
use App\Http\Resources\GradeResource;
use App\Http\Resources\LessonResource;
use App\Http\Resources\QuestionResource;
use App\Http\Resources\SubjectPartResource;
use App\Http\Resources\SubjectResource;
use App\Models\Chapter;
use App\Models\Grade;
use App\Models\Lesson;
use App\Models\Question;
use App\Models\Subject;
use App\Models\SubjectPart;
use App\Support\ContentTextSanitizer;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class TeacherContentController extends Controller
{
    public function grades(Request $request): JsonResponse
    {
        $grades = Grade::active()
            ->visibleTo($request->user())
            ->get();

        return GradeResource::collection($grades)->response();
    }

    public function storeGrade(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:150'],
            'sort_order' => ['nullable', 'integer', 'min:0'],
        ]);

        $grade = Grade::create([
            ...$data,
            'created_by_user_id' => $request->user()->id,
            'visibility' => 'private',
            'is_active' => true,
            'sort_order' => $data['sort_order'] ?? 0,
        ]);

        return (new GradeResource($grade))->response()->setStatusCode(201);
    }

    public function updateGrade(Request $request, Grade $grade): JsonResponse
    {
        $this->abortUnlessOwned($request, $grade);

        $data = $request->validate([
            'name' => ['sometimes', 'required', 'string', 'max:150'],
            'sort_order' => ['sometimes', 'nullable', 'integer', 'min:0'],
            'is_active' => ['sometimes', 'boolean'],
        ]);

        $grade->update($data);

        return (new GradeResource($grade))->response();
    }

    public function destroyGrade(Request $request, Grade $grade): JsonResponse
    {
        $this->abortUnlessOwned($request, $grade);
        $grade->update(['is_active' => false]);

        return response()->json(['message' => 'تم إخفاء الصف.']);
    }

    public function subjects(Request $request): JsonResponse
    {
        $data = $request->validate([
            'grade_id' => ['nullable', 'exists:grades,id'],
        ]);

        $subjects = Subject::active()
            ->visibleTo($request->user())
            ->when(isset($data['grade_id']), fn ($query) => $query->where('grade_id', $data['grade_id']))
            ->get();

        return SubjectResource::collection($subjects)->response();
    }

    public function storeSubject(Request $request): JsonResponse
    {
        $data = $request->validate([
            'grade_id' => ['required', 'exists:grades,id'],
            'name' => ['required', 'string', 'max:150'],
            'background_theme' => ['nullable', 'string', 'max:255'],
            'sort_order' => ['nullable', 'integer', 'min:0'],
        ]);

        $this->abortUnlessVisible($request, Grade::findOrFail($data['grade_id']));

        $subject = Subject::create([
            ...$data,
            'created_by_user_id' => $request->user()->id,
            'visibility' => 'private',
            'is_active' => true,
            'sort_order' => $data['sort_order'] ?? 0,
        ])->load('parts');

        return (new SubjectResource($subject))->response()->setStatusCode(201);
    }

    public function updateSubject(Request $request, Subject $subject): JsonResponse
    {
        $this->abortUnlessOwned($request, $subject);

        $data = $request->validate([
            'grade_id' => ['sometimes', 'required', 'exists:grades,id'],
            'name' => ['sometimes', 'required', 'string', 'max:150'],
            'background_theme' => ['sometimes', 'nullable', 'string', 'max:255'],
            'sort_order' => ['sometimes', 'nullable', 'integer', 'min:0'],
            'is_active' => ['sometimes', 'boolean'],
        ]);

        if (isset($data['grade_id'])) {
            $this->abortUnlessVisible($request, Grade::findOrFail($data['grade_id']));
        }

        $subject->update($data);

        return (new SubjectResource($subject))->response();
    }

    public function destroySubject(Request $request, Subject $subject): JsonResponse
    {
        $this->abortUnlessOwned($request, $subject);
        $subject->update(['is_active' => false]);

        return response()->json(['message' => 'تم إخفاء المادة.']);
    }

    public function storeSubjectPart(Request $request): JsonResponse
    {
        $data = $request->validate([
            'subject_id' => ['required', 'exists:subjects,id'],
            'name' => ['required', 'string', 'max:150'],
            'sort_order' => ['nullable', 'integer', 'min:0'],
        ]);

        $subject = Subject::findOrFail($data['subject_id']);
        $this->abortUnlessVisible($request, $subject);

        $nextPartNumber = ((int) $subject->parts()->max('part_number')) + 1;

        $part = SubjectPart::create([
            'subject_id' => $subject->id,
            'name' => $data['name'],
            'part_number' => $nextPartNumber,
            'sort_order' => $data['sort_order'] ?? $nextPartNumber,
            'is_active' => true,
        ]);

        return (new SubjectPartResource($part))->response()->setStatusCode(201);
    }

    public function chapters(Request $request): JsonResponse
    {
        $data = $request->validate([
            'subject_id' => ['nullable', 'exists:subjects,id'],
            'subject_part_id' => ['nullable', 'exists:subject_parts,id'],
        ]);

        $chapters = Chapter::active()
            ->visibleTo($request->user())
            ->when(isset($data['subject_id']), fn ($query) => $query->where('subject_id', $data['subject_id']))
            ->when(isset($data['subject_part_id']), fn ($query) => $query->where('subject_part_id', $data['subject_part_id']))
            ->with('subjectPart')
            ->get();

        return ChapterResource::collection($chapters)->response();
    }

    public function storeChapter(Request $request): JsonResponse
    {
        $data = $request->validate([
            'subject_part_id' => ['required', 'exists:subject_parts,id'],
            'name' => ['required', 'string', 'max:150'],
            'sort_order' => ['nullable', 'integer', 'min:0'],
        ]);

        $part = SubjectPart::with('subject')->findOrFail($data['subject_part_id']);
        $this->abortUnlessVisible($request, $part->subject);

        $chapter = Chapter::create([
            'subject_id' => $part->subject_id,
            'subject_part_id' => $part->id,
            'name' => $data['name'],
            'sort_order' => $data['sort_order'] ?? 0,
            'created_by_user_id' => $request->user()->id,
            'visibility' => 'private',
            'is_active' => true,
        ])->load('subjectPart');

        return (new ChapterResource($chapter))->response()->setStatusCode(201);
    }

    public function updateChapter(Request $request, Chapter $chapter): JsonResponse
    {
        $this->abortUnlessOwned($request, $chapter);

        $data = $request->validate([
            'subject_part_id' => ['sometimes', 'required', 'exists:subject_parts,id'],
            'name' => ['sometimes', 'required', 'string', 'max:150'],
            'sort_order' => ['sometimes', 'nullable', 'integer', 'min:0'],
            'is_active' => ['sometimes', 'boolean'],
        ]);

        if (isset($data['subject_part_id'])) {
            $part = SubjectPart::with('subject')->findOrFail($data['subject_part_id']);
            $this->abortUnlessVisible($request, $part->subject);
            $data['subject_id'] = $part->subject_id;
        }

        $chapter->update($data);

        return (new ChapterResource($chapter->load('subjectPart')))->response();
    }

    public function destroyChapter(Request $request, Chapter $chapter): JsonResponse
    {
        $this->abortUnlessOwned($request, $chapter);
        $chapter->update(['is_active' => false]);

        return response()->json(['message' => 'تم إخفاء الفصل.']);
    }

    public function lessons(Request $request): JsonResponse
    {
        $data = $request->validate([
            'chapter_id' => ['nullable', 'exists:chapters,id'],
        ]);

        $lessons = Lesson::active()
            ->visibleTo($request->user())
            ->when(isset($data['chapter_id']), fn ($query) => $query->where('chapter_id', $data['chapter_id']))
            ->get();

        return LessonResource::collection($lessons)->response();
    }

    public function storeLesson(Request $request): JsonResponse
    {
        $data = $request->validate([
            'chapter_id' => ['required', 'exists:chapters,id'],
            'name' => ['required', 'string', 'max:150'],
            'sort_order' => ['nullable', 'integer', 'min:0'],
        ]);

        $chapter = Chapter::findOrFail($data['chapter_id']);
        $this->abortUnlessVisible($request, $chapter);

        $lesson = Lesson::create([
            ...$data,
            'sort_order' => $data['sort_order'] ?? 0,
            'created_by_user_id' => $request->user()->id,
            'visibility' => 'private',
            'is_active' => true,
        ]);

        return (new LessonResource($lesson))->response()->setStatusCode(201);
    }

    public function updateLesson(Request $request, Lesson $lesson): JsonResponse
    {
        $this->abortUnlessOwned($request, $lesson);

        $data = $request->validate([
            'chapter_id' => ['sometimes', 'required', 'exists:chapters,id'],
            'name' => ['sometimes', 'required', 'string', 'max:150'],
            'sort_order' => ['sometimes', 'nullable', 'integer', 'min:0'],
            'is_active' => ['sometimes', 'boolean'],
        ]);

        if (isset($data['chapter_id'])) {
            $this->abortUnlessVisible($request, Chapter::findOrFail($data['chapter_id']));
        }

        $lesson->update($data);

        return (new LessonResource($lesson))->response();
    }

    public function destroyLesson(Request $request, Lesson $lesson): JsonResponse
    {
        $this->abortUnlessOwned($request, $lesson);
        $lesson->update(['is_active' => false]);

        return response()->json(['message' => 'تم إخفاء الدرس.']);
    }

    public function questions(Request $request): JsonResponse
    {
        $data = $request->validate([
            'lesson_id' => ['nullable', 'exists:lessons,id'],
        ]);

        $questions = Question::active()
            ->visibleTo($request->user())
            ->when(isset($data['lesson_id']), fn ($query) => $query->where('lesson_id', $data['lesson_id']))
            ->with('lesson.chapter')
            ->orderBy('lesson_id')
            ->orderBy('sort_order')
            ->get();

        return QuestionResource::collection($questions)->response();
    }

    public function storeQuestion(Request $request): JsonResponse
    {
        $data = $this->sanitizeQuestionData($this->validateQuestion($request));
        $this->validateQuestionAnswer($data);
        $lesson = Lesson::findOrFail($data['lesson_id']);
        $this->abortUnlessVisible($request, $lesson);

        $question = Question::create([
            ...$data,
            'created_by_user_id' => $request->user()->id,
            'visibility' => 'private',
            'is_active' => true,
        ])->load('lesson.chapter');

        return (new QuestionResource($question))->response()->setStatusCode(201);
    }

    public function updateQuestion(Request $request, Question $question): JsonResponse
    {
        $this->abortUnlessOwned($request, $question);
        $data = $this->sanitizeQuestionData($this->validateQuestion($request, true));
        $this->validateQuestionAnswer($data, $question);

        if (isset($data['lesson_id'])) {
            $this->abortUnlessVisible($request, Lesson::findOrFail($data['lesson_id']));
        }

        $question->update($data);

        return (new QuestionResource($question->load('lesson.chapter')))->response();
    }

    public function destroyQuestion(Request $request, Question $question): JsonResponse
    {
        $this->abortUnlessOwned($request, $question);
        $question->update(['is_active' => false]);

        return response()->json(['message' => 'تم إخفاء السؤال.']);
    }

    private function validateQuestion(Request $request, bool $partial = false): array
    {
        $required = $partial ? 'sometimes' : 'required';

        return $request->validate([
            'lesson_id' => [$required, 'exists:lessons,id'],
            'question_text' => [$required, 'string'],
            'question_type' => [$required, Rule::in(['multiple_choice', 'true_false', 'text'])],
            'option_a' => ['nullable', 'string', 'max:255'],
            'option_b' => ['nullable', 'string', 'max:255'],
            'option_c' => ['nullable', 'string', 'max:255'],
            'option_d' => ['nullable', 'string', 'max:255'],
            'correct_answer' => [$partial ? 'sometimes' : 'present', 'nullable', 'string', 'max:255'],
            'level' => [$required, Rule::in(['easy', 'hard'])],
            'explanation' => ['nullable', 'string'],
            'sort_order' => ['nullable', 'integer', 'min:0'],
            'is_active' => ['sometimes', 'boolean'],
        ]);
    }

    private function sanitizeQuestionData(array $data): array
    {
        foreach (['question_text', 'correct_answer'] as $field) {
            if (array_key_exists($field, $data)) {
                $data[$field] = ContentTextSanitizer::clean($data[$field]) ?? '';
            }
        }

        foreach (['option_a', 'option_b', 'option_c', 'option_d', 'explanation'] as $field) {
            if (array_key_exists($field, $data)) {
                $data[$field] = ContentTextSanitizer::clean($data[$field]);
            }
        }

        return $data;
    }

    private function validateQuestionAnswer(array $data, ?Question $existing = null): void
    {
        $questionType = $data['question_type'] ?? $existing?->question_type;
        $correctAnswer = $data['correct_answer'] ?? $existing?->correct_answer;

        if ($questionType === null) {
            return;
        }

        $correctAnswer = trim((string) $correctAnswer);

        if ($questionType === 'text') {
            return;
        }

        if ($questionType === 'true_false' && ! in_array($correctAnswer, ['صح', 'خطأ'], true)) {
            throw ValidationException::withMessages([
                'correct_answer' => 'الإجابة الصحيحة لسؤال الصح والخطأ يجب أن تكون صح أو خطأ.',
            ]);
        }

        if ($questionType !== 'multiple_choice') {
            return;
        }

        $options = collect(['option_a', 'option_b', 'option_c', 'option_d'])
            ->map(fn (string $field) => $data[$field] ?? $existing?->{$field})
            ->filter(fn ($option) => is_string($option) && trim($option) !== '')
            ->map(fn (string $option) => trim($option))
            ->values();

        if ($options->count() < 2) {
            throw ValidationException::withMessages([
                'option_a' => 'سؤال الاختيارات يحتاج خيارين على الأقل.',
            ]);
        }

        if (! $options->containsStrict($correctAnswer)) {
            throw ValidationException::withMessages([
                'correct_answer' => 'الإجابة الصحيحة يجب أن تطابق نص أحد الخيارات.',
            ]);
        }
    }

    private function abortUnlessOwned(Request $request, mixed $model): void
    {
        abort_unless(
            $model->visibility === 'private' && $model->created_by_user_id === $request->user()->id,
            403,
            'يمكنك تعديل المحتوى الذي أنشأته فقط.'
        );
    }

    private function abortUnlessVisible(Request $request, mixed $model): void
    {
        abort_unless(
            $model->visibility === 'official' || $model->created_by_user_id === $request->user()->id,
            403,
            'هذا المحتوى غير متاح لهذا الحساب.'
        );
    }
}
