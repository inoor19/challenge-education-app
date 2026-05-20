<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ChapterResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'subject_id' => $this->subject_id,
            'subject_part_id' => $this->subject_part_id,
            'subject_part' => new SubjectPartResource($this->whenLoaded('subjectPart')),
            'name' => $this->name,
            'sort_order' => $this->sort_order,
            'is_active' => $this->is_active,
            'visibility' => $this->visibility,
        ];
    }
}
