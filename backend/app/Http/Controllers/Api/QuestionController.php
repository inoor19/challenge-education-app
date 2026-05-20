<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\QuestionResource;
use App\Models\Question;
use App\Services\EntitlementService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class QuestionController extends Controller
{
    public function __construct(private readonly EntitlementService $entitlements) {}

    public function index(Request $request): JsonResponse
    {
        $request->validate([
            'lesson_ids' => ['required', 'array'],
            'lesson_ids.*' => ['exists:lessons,id'],
        ]);

        $questions = Question::active()
            ->forLessons($request->lesson_ids)
            ->whereIn('id', $this->entitlements->accessibleQuestionIds($request->user()))
            ->orderBy('lesson_id')
            ->orderBy('sort_order')
            ->with('lesson.chapter')
            ->get();

        return response()->json(QuestionResource::collection($questions));
    }
}
