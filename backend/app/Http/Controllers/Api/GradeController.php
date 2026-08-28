<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\GradeResource;
use App\Http\Resources\SubjectResource;
use App\Models\Grade;
use App\Models\QuestionPackage;
use App\Services\EntitlementService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class GradeController extends Controller
{
    public function __construct(private readonly EntitlementService $entitlements) {}

    public function index(Request $request): JsonResponse
    {
        $questionIds = $this->entitlements->accessibleQuestionIds($request->user());
        $packageGradeIds = QuestionPackage::query()
            ->active()
            ->whereNotNull('grade_id')
            ->pluck('grade_id');

        $grades = Grade::active()
            ->where(function ($query) use ($request, $questionIds, $packageGradeIds) {
                $query->where(function ($query) use ($questionIds, $packageGradeIds) {
                    $query->whereHas('subjects.chapters.lessons.questions', fn ($query) => $query->whereIn('questions.id', $questionIds))
                        ->orWhereIn('id', $packageGradeIds);
                })->orWhere(function ($query) use ($request) {
                    $query->where('visibility', 'private')
                        ->where('created_by_user_id', $request->user()->id);
                });
            })
            ->get();

        return response()->json(GradeResource::collection($grades));
    }

    public function subjects(Request $request, Grade $grade): JsonResponse
    {
        $questionIds = $this->entitlements->accessibleQuestionIds($request->user());

        $subjects = $grade->subjects()
            ->active()
            ->where(function ($query) use ($request, $questionIds) {
                $query->whereHas('chapters.lessons.questions', fn ($query) => $query->whereIn('questions.id', $questionIds))
                    ->orWhere(function ($query) use ($request) {
                        $query->where('visibility', 'private')
                            ->where('created_by_user_id', $request->user()->id);
                    });
            })
            ->get();

        return response()->json(SubjectResource::collection($subjects));
    }
}
