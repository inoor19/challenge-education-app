<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\LessonResource;
use App\Models\Lesson;
use App\Services\EntitlementService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LessonController extends Controller
{
    public function __construct(private readonly EntitlementService $entitlements) {}

    public function index(Request $request): JsonResponse
    {
        $request->validate([
            'chapter_ids' => ['required', 'array'],
            'chapter_ids.*' => ['exists:chapters,id'],
        ]);

        $questionIds = $this->entitlements->accessibleQuestionIds($request->user());

        $lessons = Lesson::whereIn('chapter_id', $request->chapter_ids)
            ->active()
            ->where(function ($query) use ($request, $questionIds) {
                $query->whereHas('questions', fn ($query) => $query->whereIn('questions.id', $questionIds))
                    ->orWhere(function ($query) use ($request) {
                        $query->where('visibility', 'private')
                            ->where('created_by_user_id', $request->user()->id);
                    });
            })
            ->orderBy('chapter_id')
            ->orderBy('sort_order')
            ->get();

        return response()->json(LessonResource::collection($lessons));
    }
}
