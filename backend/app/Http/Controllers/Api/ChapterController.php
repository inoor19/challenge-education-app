<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\ChapterResource;
use App\Models\Chapter;
use App\Services\EntitlementService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ChapterController extends Controller
{
    public function __construct(private readonly EntitlementService $entitlements) {}

    public function index(Request $request): JsonResponse
    {
        $request->validate([
            'subject_id' => ['required', 'exists:subjects,id'],
            'subject_part_id' => ['nullable', 'exists:subject_parts,id'],
        ]);

        $questionIds = $this->entitlements->accessibleQuestionIds($request->user());

        $chapters = Chapter::where('subject_id', $request->subject_id)
            ->active()
            ->when($request->filled('subject_part_id'), fn ($query) => $query->where('subject_part_id', $request->integer('subject_part_id')))
            ->where(function ($query) use ($request, $questionIds) {
                $query->whereHas('lessons.questions', fn ($query) => $query->whereIn('questions.id', $questionIds))
                    ->orWhere(function ($query) use ($request) {
                        $query->where('visibility', 'private')
                            ->where('created_by_user_id', $request->user()->id);
                    });
            })
            ->with('subjectPart')
            ->get();

        return response()->json(ChapterResource::collection($chapters));
    }
}
