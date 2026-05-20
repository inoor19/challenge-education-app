<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\QuestionPackageResource;
use App\Http\Resources\StorePurchaseResource;
use App\Models\QuestionPackage;
use App\Models\StorePurchase;
use App\Models\TeacherPackage;
use App\Services\EntitlementService;
use App\Services\PurchaseVerificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class PurchaseController extends Controller
{
    public function __construct(
        private readonly PurchaseVerificationService $verifier,
        private readonly EntitlementService $entitlements,
    ) {}

    public function verify(Request $request): JsonResponse
    {
        $data = $this->validatePurchasePayload($request);
        $package = QuestionPackage::active()->findOrFail($data['question_package_id']);

        abort_unless($package->productIdForStore($data['store']) === $data['product_id'], 422, 'معرّف المنتج لا يطابق الحزمة.');

        $purchase = DB::transaction(function () use ($request, $data, $package) {
            $verification = $this->verifier->verify($data);
            $transactionId = $data['transaction_id']
                ?? sha1((string) ($data['purchase_token'] ?? $data['signed_transaction']));

            $purchase = StorePurchase::updateOrCreate(
                [
                    'store' => $data['store'],
                    'transaction_id' => $transactionId,
                ],
                [
                    'user_id' => $request->user()->id,
                    'question_package_id' => $package->id,
                    'product_id' => $data['product_id'],
                    'purchase_token' => $data['purchase_token'] ?? null,
                    'signed_transaction' => $data['signed_transaction'] ?? null,
                    'status' => $verification['status'],
                    'verified_at' => $verification['verified'] ? now() : null,
                    'expires_at' => null,
                    'raw_payload' => $data['raw_payload'] ?? $data,
                ]
            );

            if ($purchase->isVerified()) {
                TeacherPackage::updateOrCreate(
                    ['user_id' => $request->user()->id, 'question_package_id' => $package->id],
                    ['purchased_at' => now()]
                );
            }

            return $purchase;
        });

        return response()->json([
            'purchase' => new StorePurchaseResource($purchase),
            'package' => new QuestionPackageResource($package->fresh()->load(['grade', 'subject', 'chapter', 'lesson'])->loadCount('questions')),
            'owned_packages' => QuestionPackageResource::collection($this->entitlements->ownedPackages($request->user())),
        ]);
    }

    public function restore(Request $request): JsonResponse
    {
        $request->validate([
            'purchases' => ['nullable', 'array'],
            'purchases.*.question_package_id' => ['required_with:purchases', 'exists:question_packages,id'],
            'purchases.*.store' => ['required_with:purchases', Rule::in(['android', 'ios'])],
            'purchases.*.product_id' => ['required_with:purchases', 'string'],
            'purchases.*.transaction_id' => ['nullable', 'string'],
            'purchases.*.purchase_token' => ['nullable', 'string'],
            'purchases.*.signed_transaction' => ['nullable', 'string'],
        ]);

        foreach ($request->input('purchases', []) as $purchasePayload) {
            $restoreRequest = new Request($purchasePayload);
            $restoreRequest->setUserResolver(fn () => $request->user());
            $this->verify($restoreRequest);
        }

        return response()->json([
            'owned_packages' => QuestionPackageResource::collection($this->entitlements->ownedPackages($request->user())),
        ]);
    }

    private function validatePurchasePayload(Request $request): array
    {
        return $request->validate([
            'question_package_id' => ['required', 'exists:question_packages,id'],
            'store' => ['required', Rule::in(['android', 'ios'])],
            'product_id' => ['required', 'string', 'max:255'],
            'transaction_id' => ['nullable', 'string'],
            'purchase_token' => ['nullable', 'string'],
            'signed_transaction' => ['nullable', 'string'],
            'raw_payload' => ['nullable', 'array'],
        ]);
    }
}
