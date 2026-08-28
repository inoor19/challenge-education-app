<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\CreateChallengeRequest;
use App\Http\Requests\Api\ManualScoreRequest;
use App\Http\Resources\ChallengeGroupResource;
use App\Http\Resources\ChallengeSessionResource;
use App\Models\ChallengeGroup;
use App\Models\ChallengeQuestion;
use App\Models\ChallengeSession;
use App\Models\Chapter;
use App\Models\Lesson;
use App\Models\Question;
use App\Models\SubjectPart;
use App\Services\ChallengeService;
use App\Services\EntitlementService;
use App\Services\ScoringService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ChallengeController extends Controller
{
    public function __construct(
        private readonly ChallengeService $challengeService,
        private readonly ScoringService $scoringService,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $sessions = ChallengeSession::query()
            ->where('teacher_id', $request->user()->id)
            ->with(['grade', 'subject', 'subjectPart', 'chapters.subjectPart', 'lessons', 'groups', 'challengeQuestions.question.lesson.chapter'])
            ->latest()
            ->get();

        return response()->json(ChallengeSessionResource::collection($sessions));
    }

    public function store(CreateChallengeRequest $request): JsonResponse
    {
        $session = $this->challengeService->createSession(
            $request->validated(),
            $request->user()->id
        );

        return response()->json(new ChallengeSessionResource($session), 201);
    }

    public function show(ChallengeSession $challenge): JsonResponse
    {
        $this->authorize('view', $challenge);

        $challenge->load(['grade', 'subject', 'subjectPart', 'chapters.subjectPart', 'lessons', 'groups', 'challengeQuestions.question.lesson.chapter']);

        return response()->json(new ChallengeSessionResource($challenge));
    }

    public function update(Request $request, ChallengeSession $challenge): JsonResponse
    {
        $this->authorize('update', $challenge);

        $data = $request->validate([
            'timer_seconds' => ['nullable', 'integer', 'min:10', 'max:300'],
            'timer_enabled' => ['nullable', 'boolean'],
            'groups' => ['sometimes', 'array', 'min:2'],
            'groups.*.id' => ['nullable', 'integer', 'exists:challenge_groups,id'],
            'groups.*.name' => ['required_with:groups', 'string', 'max:100'],
            'groups.*.sort_order' => ['nullable', 'integer', 'min:0'],

            // Editable setup fields (for question editing flow)
            'subject_part_id' => ['sometimes', 'integer', 'exists:subject_parts,id'],
            'chapter_ids' => ['sometimes', 'array', 'min:1'],
            'chapter_ids.*' => ['integer', 'exists:chapters,id'],
            'lesson_ids' => ['sometimes', 'array', 'min:1'],
            'lesson_ids.*' => ['integer', 'exists:lessons,id'],
            'question_ids' => ['sometimes', 'array', 'min:1'],
            'question_ids.*' => ['integer', 'exists:questions,id'],
        ]);

        foreach ($data['groups'] ?? [] as $group) {
            if (! empty($group['id'])) {
                abort_unless($challenge->groups()->whereKey($group['id'])->exists(), 403);
            }
        }

        $this->validateSetupEdit($challenge, $data);

        $session = $this->challengeService->updateSettings($challenge, $data);

        return response()->json(new ChallengeSessionResource($session));
    }

    private function validateSetupEdit(ChallengeSession $challenge, array $data): void
    {
        if (
            ! array_key_exists('subject_part_id', $data)
            && ! array_key_exists('chapter_ids', $data)
            && ! array_key_exists('lesson_ids', $data)
            && ! array_key_exists('question_ids', $data)
        ) {
            return;
        }

        $subjectPartId = $data['subject_part_id'] ?? $challenge->subject_part_id;

        $subjectPart = SubjectPart::query()->whereKey($subjectPartId)->firstOrFail();
        abort_unless((int) $subjectPart->subject_id === (int) $challenge->subject_id, 422, 'الجزء المختار لا ينتمي لنفس المادة.');

        $chapterIds = $data['chapter_ids'] ?? $challenge->chapters()->pluck('chapters.id')->all();
        $lessonIds = $data['lesson_ids'] ?? $challenge->lessons()->pluck('lessons.id')->all();

        $chapters = Chapter::query()
            ->whereIn('id', $chapterIds)
            ->get(['id', 'subject_id', 'subject_part_id']);
        abort_unless($chapters->count() === count($chapterIds), 422, 'بعض الفصول غير موجودة.');

        foreach ($chapters as $chapter) {
            abort_unless((int) $chapter->subject_id === (int) $challenge->subject_id, 422, 'بعض الفصول لا تنتمي للمادة المختارة.');
            abort_unless((int) $chapter->subject_part_id === (int) $subjectPartId, 422, 'بعض الفصول لا تنتمي للجزء المختار.');
        }

        $lessons = Lesson::query()->whereIn('id', $lessonIds)->get(['id', 'chapter_id']);
        abort_unless($lessons->count() === count($lessonIds), 422, 'بعض الدروس غير موجودة.');

        $chapterIdSet = array_fill_keys($chapterIds, true);
        foreach ($lessons as $lesson) {
            abort_unless(isset($chapterIdSet[$lesson->chapter_id]), 422, 'بعض الدروس لا تنتمي للفصول المختارة.');
        }

        if (! array_key_exists('question_ids', $data)) {
            return;
        }

        $challenge->loadMissing('teacher');
        $accessibleIds = app(EntitlementService::class)->accessibleQuestionIds($challenge->teacher);

        $questions = Question::query()
            ->active()
            ->whereIn('id', $data['question_ids'])
            ->whereIn('lesson_id', $lessonIds)
            ->whereIn('id', $accessibleIds)
            ->count();

        abort_unless($questions === count($data['question_ids']), 422, 'بعض الأسئلة غير متاحة لهذه الدروس أو ضمن الحزم المفعلة.');
    }

    public function restart(ChallengeSession $challenge): JsonResponse
    {
        $this->authorize('view', $challenge);

        abort_unless($challenge->status === 'completed', 422, 'يمكن إعادة التحديات المكتملة فقط.');

        $session = $this->challengeService->restartSession($challenge);

        return response()->json(new ChallengeSessionResource($session), 201);
    }

    public function destroy(ChallengeSession $challenge): JsonResponse
    {
        $this->authorize('delete', $challenge);

        $challenge->delete();

        return response()->json(null, 204);
    }

    public function addGroup(Request $request, ChallengeSession $challenge): JsonResponse
    {
        $this->authorize('update', $challenge);

        $request->validate([
            'name' => ['required', 'string', 'max:100'],
            'sort_order' => ['nullable', 'integer'],
        ]);

        $group = $this->challengeService->addGroup(
            $challenge,
            $request->name,
            $request->sort_order ?? $challenge->groups()->count()
        );

        return response()->json(new ChallengeGroupResource($group), 201);
    }

    public function rollDice(ChallengeSession $challenge): JsonResponse
    {
        $this->authorize('update', $challenge);

        $diceValue = $this->scoringService->rollDice();

        return response()->json(['dice_value' => $diceValue]);
    }

    public function markCorrect(Request $request, ChallengeSession $challenge, ChallengeQuestion $question): JsonResponse
    {
        $this->authorize('update', $challenge);

        $request->validate([
            'group_id' => ['required', 'exists:challenge_groups,id'],
            'dice_value' => ['required', 'integer', 'min:1', 'max:3'],
        ]);

        abort_if($question->is_used, 422, 'هذا السؤال تم استخدامه بالفعل.');
        abort_if($question->challenge_session_id !== $challenge->id, 403);
        abort_unless($challenge->groups()->whereKey($request->group_id)->exists(), 403);

        $result = $this->scoringService->markCorrect(
            $challenge,
            $question,
            $request->group_id,
            $request->dice_value,
            $request->user()->id
        );

        return response()->json([
            'points_awarded' => $result['points_awarded'],
            'group' => new ChallengeGroupResource($result['group']),
            'groups' => ChallengeGroupResource::collection($challenge->fresh()->groups),
        ]);
    }

    public function markWrong(Request $request, ChallengeSession $challenge, ChallengeQuestion $question): JsonResponse
    {
        $this->authorize('update', $challenge);

        $request->validate([
            'group_id' => ['required', 'exists:challenge_groups,id'],
            'dice_value' => ['required', 'integer', 'min:1', 'max:3'],
        ]);

        abort_if($question->is_used, 422, 'هذا السؤال تم استخدامه بالفعل.');
        abort_if($question->challenge_session_id !== $challenge->id, 403);
        abort_unless($challenge->groups()->whereKey($request->group_id)->exists(), 403);

        $this->scoringService->markWrong($challenge, $question, $request->group_id, $request->dice_value);

        return response()->json(['message' => 'تم تسجيل إجابة خاطئة.']);
    }

    public function manualScore(ManualScoreRequest $request, ChallengeSession $challenge, ChallengeGroup $group): JsonResponse
    {
        $this->authorize('update', $challenge);
        abort_if($group->challenge_session_id !== $challenge->id, 403);

        $data = $request->validated();

        $updatedGroup = match ($data['type']) {
            'add' => $this->scoringService->manualAdd($challenge, $group, $data['points'], $request->user()->id, $data['note'] ?? null),
            'subtract' => $this->scoringService->manualSubtract($challenge, $group, $data['points'], $request->user()->id, $data['note'] ?? null),
            'correction' => $this->scoringService->correctScore($challenge, $group, $data['score'], $request->user()->id, $data['note'] ?? null),
        };

        return response()->json([
            'group' => new ChallengeGroupResource($updatedGroup),
            'groups' => ChallengeGroupResource::collection($challenge->fresh()->groups),
        ]);
    }

    public function complete(ChallengeSession $challenge): JsonResponse
    {
        $this->authorize('update', $challenge);

        $session = $this->challengeService->completeSession($challenge);

        return response()->json(new ChallengeSessionResource($session));
    }
}
