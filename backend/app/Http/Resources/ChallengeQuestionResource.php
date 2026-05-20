<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ChallengeQuestionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'sequence_number' => $this->sequence_number,
            'is_used' => $this->is_used,
            'used_at' => $this->used_at?->toISOString(),
            'answer_status' => $this->answer_status,
            'awarded_points' => $this->awarded_points,
            'last_dice_value' => $this->last_dice_value,
            'selected_group_id' => $this->selected_group_id,
            'question' => new QuestionResource($this->whenLoaded('question')),
        ];
    }
}
