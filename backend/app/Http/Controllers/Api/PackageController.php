<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\QuestionPackageResource;
use App\Services\EntitlementService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PackageController extends Controller
{
    public function __construct(private readonly EntitlementService $entitlements) {}

    public function index(Request $request): JsonResponse
    {
        return response()->json(
            QuestionPackageResource::collection($this->entitlements->availablePackages($request->user()))
        );
    }

    public function owned(Request $request): JsonResponse
    {
        return response()->json(
            QuestionPackageResource::collection($this->entitlements->ownedPackages($request->user()))
        );
    }
}
