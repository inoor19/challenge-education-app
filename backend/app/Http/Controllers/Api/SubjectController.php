<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\ChapterResource;
use App\Http\Resources\SubjectPartResource;
use App\Models\Subject;
use App\Services\EntitlementService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SubjectController extends Controller
{
    public function __construct(private readonly EntitlementService $entitlements) {}

    public function chapters(Request $request, Subject $subject): JsonResponse
    {
        $questionIds = $this->entitlements->accessibleQuestionIds($request->user());

        $chapters = $subject->chapters()
            ->active()
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

    public function parts(Request $request, Subject $subject): JsonResponse
    {
        abort_unless(
            $subject->visibility === 'official' || $subject->created_by_user_id === $request->user()->id,
            403
        );

        $questionIds = $this->entitlements->accessibleQuestionIds($request->user());

        $parts = $subject->parts()
            ->active()
            ->when(! $request->boolean('include_empty'), fn ($query) => $query->whereHas('chapters.lessons.questions', fn ($query) => $query->whereIn('questions.id', $questionIds)))
            ->get();

        return response()->json(SubjectPartResource::collection($parts));
    }
}
