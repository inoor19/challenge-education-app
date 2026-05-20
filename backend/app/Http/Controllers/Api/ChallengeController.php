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
use App\Services\ChallengeService;
use App\Services\ScoringService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ChallengeController extends Controller
{
    public function __construct(
        private readonly ChallengeService $challengeService,
        private readonly ScoringService $scoringService,
    ) {}

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
