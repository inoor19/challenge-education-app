<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\GradeResource;
use App\Http\Resources\SubjectResource;
use App\Models\Grade;
use App\Services\EntitlementService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class GradeController extends Controller
{
    public function __construct(private readonly EntitlementService $entitlements) {}

    public function index(Request $request): JsonResponse
    {
        $questionIds = $this->entitlements->accessibleQuestionIds($request->user());

        $grades = Grade::active()
            ->whereHas('subjects.chapters.lessons.questions', fn ($query) => $query->whereIn('questions.id', $questionIds))
            ->get();

        return response()->json(GradeResource::collection($grades));
    }

    public function subjects(Request $request, Grade $grade): JsonResponse
    {
        $questionIds = $this->entitlements->accessibleQuestionIds($request->user());

        $subjects = $grade->subjects()
            ->active()
            ->whereHas('chapters.lessons.questions', fn ($query) => $query->whereIn('questions.id', $questionIds))
            ->get();

        return response()->json(SubjectResource::collection($subjects));
    }
}
