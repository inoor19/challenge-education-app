<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class StorePurchaseResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'question_package_id' => $this->question_package_id,
            'store' => $this->store,
            'product_id' => $this->product_id,
            'transaction_id' => $this->transaction_id,
            'status' => $this->status,
            'verified_at' => $this->verified_at?->toISOString(),
            'expires_at' => $this->expires_at?->toISOString(),
        ];
    }
}
