<?php

namespace App\Services;

class PurchaseVerificationService
{
    public function verify(array $payload): array
    {
        $store = $payload['store'];
        $transactionId = $payload['transaction_id'] ?? null;
        $purchaseToken = $payload['purchase_token'] ?? null;
        $signedTransaction = $payload['signed_transaction'] ?? null;

        $hasProof = filled($transactionId) || filled($purchaseToken) || filled($signedTransaction);

        if (! in_array($store, ['android', 'ios'], true) || ! $hasProof) {
            return ['verified' => false, 'status' => 'rejected'];
        }

        if (app()->environment(['local', 'testing']) && str_starts_with((string) $transactionId, 'test_')) {
            return ['verified' => true, 'status' => 'verified'];
        }

        if (config('services.store_verification.trust_client_payload', false)) {
            return ['verified' => true, 'status' => 'verified'];
        }

        return ['verified' => false, 'status' => 'pending'];
    }
}
