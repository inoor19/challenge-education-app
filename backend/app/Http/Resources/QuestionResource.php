<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class QuestionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'lesson_id' => $this->lesson_id,
            'subject_part_id' => $this->lesson?->chapter?->subject_part_id,
            'question_text' => $this->question_text,
            'question_type' => $this->question_type,
            'option_a' => $this->option_a,
            'option_b' => $this->option_b,
            'option_c' => $this->option_c,
            'option_d' => $this->option_d,
            'correct_answer' => $this->correct_answer,
            'level' => $this->level,
            'explanation' => $this->explanation,
            'sort_order' => $this->sort_order,
            'visibility' => $this->visibility,
        ];
    }
}
