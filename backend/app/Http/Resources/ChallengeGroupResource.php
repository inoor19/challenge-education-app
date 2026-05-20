<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ChallengeGroupResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'challenge_session_id' => $this->challenge_session_id,
            'name' => $this->name,
            'score' => $this->score,
            'sort_order' => $this->sort_order,
        ];
    }
}
